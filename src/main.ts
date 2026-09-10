import { supabase } from './supabase'
import './style.css'

type Student={id:string;name:string;phone:string;batch:string;fee:number;status:string}
type Batch={id:string;name:string;course:string;teacher:string;students:number;fee:number;status:string}
type Payment={id:string;studentId:string;name:string;amount:number;method:string;date:string}

const demoStudents:Student[]=[
{id:'EL-1001',name:'Abdullah Rahman',phone:'01712-345678',batch:'HSC 2027 Science',fee:2500,status:'Active'},
{id:'EL-1002',name:'Nusrat Sultana',phone:'01812-456789',batch:'SSC 2027',fee:2000,status:'Active'},
{id:'EL-1003',name:'Mohammad Hasan',phone:'01912-567890',batch:'Computer Basic',fee:1500,status:'Active'}]
const demoBatches:Batch[]=[
{id:'B-1001',name:'HSC 2027 Science',course:'HSC Science',teacher:'Mr. Rahman',students:42,fee:2500,status:'Active'},
{id:'B-1002',name:'SSC 2027',course:'SSC',teacher:'Ms. Nusrat',students:36,fee:2000,status:'Active'},
{id:'B-1003',name:'Computer Basic',course:'Computer Basic',teacher:'Mr. Hasan',students:24,fee:1500,status:'Active'}]

const get=(k:string)=>JSON.parse(localStorage.getItem(k)||'[]')
const set=(k:string,v:any)=>localStorage.setItem(k,JSON.stringify(v))
const students=()=>[...demoStudents,...get('easylearn_students')]
const batches=()=>[...demoBatches,...get('easylearn_batches')]
const payments=():Payment[]=>get('easylearn_payments')
const app=document.querySelector<HTMLDivElement>('#app')!

function header(back=true){return `<header class="topbar"><div class="brand"><div class="logo">E</div><div><div class="brand-name">Easylearn</div><div class="brand-sub">INSTITUTE</div></div></div><div class="topbar-actions">${back?'<button class="outline-btn" data-page="dashboard">← Dashboard</button>':''}<button class="language-btn">বাংলা</button><button class="logout-btn" data-page="login">Logout</button></div></header>`}
function login(){
  app.innerHTML=`<div class="login-page"><div class="login-card"><div class="login-logo">E</div><h1>Easylearn Institute</h1><p class="login-subtitle">Sign in to your institute account</p><div id="authMessage" class="auth-message"></div><div class="form-group"><label>Email</label><input id="email" type="email" autocomplete="email" placeholder="Enter your email"/></div><div class="form-group"><label>Password</label><input id="password" type="password" autocomplete="current-password" placeholder="Enter your password"/></div><button class="primary-btn full" id="login">Login</button><button class="text-btn" id="showRegister">Create a new account</button><button class="text-btn muted" id="forgotPassword">Forgot password?</button></div></div>`

  const message=document.getElementById('authMessage')!
  const setMessage=(text:string,error=false)=>{message.textContent=text;message.className=`auth-message ${error?'error':'success'}`}

  document.getElementById('login')!.onclick=async()=>{
    const email=(document.getElementById('email') as HTMLInputElement).value.trim()
    const password=(document.getElementById('password') as HTMLInputElement).value
    if(!email||!password){setMessage('Please enter your email and password.',true);return}

    const button=document.getElementById('login') as HTMLButtonElement
    button.disabled=true
    button.textContent='Signing in...'

    const { error }=await supabase.auth.signInWithPassword({email,password})

    button.disabled=false
    button.textContent='Login'

    if(error){setMessage(error.message,true);return}
    dashboard()
  }

  document.getElementById('showRegister')!.onclick=register

  document.getElementById('forgotPassword')!.onclick=async()=>{
    const email=(document.getElementById('email') as HTMLInputElement).value.trim()
    if(!email){setMessage('Enter your email first, then click Forgot password.',true);return}
    const { error }=await supabase.auth.resetPasswordForEmail(email,{redirectTo:window.location.origin})
    if(error){setMessage(error.message,true);return}
    setMessage('Password reset email sent. Check your inbox.')
  }
}

function register(){
  app.innerHTML=`<div class="login-page"><div class="login-card"><div class="login-logo">E</div><h1>Create Account</h1><p class="login-subtitle">Register your Easylearn account</p><div id="authMessage" class="auth-message"></div><div class="form-group"><label>Full Name</label><input id="regName" type="text" autocomplete="name" placeholder="Your full name"/></div><div class="form-group"><label>Email</label><input id="regEmail" type="email" autocomplete="email" placeholder="you@example.com"/></div><div class="form-group"><label>Password</label><input id="regPassword" type="password" autocomplete="new-password" placeholder="At least 6 characters"/></div><div class="form-group"><label>Confirm Password</label><input id="regConfirm" type="password" autocomplete="new-password" placeholder="Repeat your password"/></div><button class="primary-btn full" id="register">Register</button><button class="text-btn" id="showLogin">Already have an account? Login</button></div></div>`

  const message=document.getElementById('authMessage')!
  const setMessage=(text:string,error=false)=>{message.textContent=text;message.className=`auth-message ${error?'error':'success'}`}

  document.getElementById('showLogin')!.onclick=login

  document.getElementById('register')!.onclick=async()=>{
    const name=(document.getElementById('regName') as HTMLInputElement).value.trim()
    const email=(document.getElementById('regEmail') as HTMLInputElement).value.trim()
    const password=(document.getElementById('regPassword') as HTMLInputElement).value
    const confirm=(document.getElementById('regConfirm') as HTMLInputElement).value

    if(!name||!email||!password||!confirm){setMessage('Please fill in all fields.',true);return}
    if(password.length<6){setMessage('Password must be at least 6 characters.',true);return}
    if(password!==confirm){setMessage('Passwords do not match.',true);return}

    const button=document.getElementById('register') as HTMLButtonElement
    button.disabled=true
    button.textContent='Creating account...'

    const { data,error }=await supabase.auth.signUp({
      email,
      password,
      options:{data:{full_name:name},emailRedirectTo:window.location.origin}
    })

    button.disabled=false
    button.textContent='Register'

    if(error){setMessage(error.message,true);return}

    if(data.session){
      dashboard()
      return
    }

    setMessage('Registration successful. Check your email and confirm your account before logging in.')
  }
}

function dashboard(){app.innerHTML=`${header(false)}<main class="dashboard"><div class="welcome-card"><div><h1>Welcome back, Admin 👋</h1><p>Manage your institute from one place.</p></div><div class="trial-box"><b>30 Days Trial</b><span>Active</span></div></div><div class="stats-grid"><div class="stat-card"><i>👨‍🎓</i><span>Students<strong>${students().length+245}</strong></span></div><div class="stat-card"><i>📚</i><span>Batches<strong>${batches().length+15}</strong></span></div><div class="stat-card"><i>👨‍🏫</i><span>Staff<strong>12</strong></span></div><div class="stat-card"><i>৳</i><span>This Month<strong>৳85,500</strong></span></div></div><section class="dashboard-section"><div class="section-heading"><div><h2>Quick Actions</h2><p>Common tasks</p></div></div><div class="quick-actions"><button class="quick-action" data-page="students"><i>👨‍🎓</i><b>Students</b><small>Manage students</small></button><button class="quick-action" data-page="add"><i>➕</i><b>Add Student</b><small>Register new student</small></button><button class="quick-action" data-page="batches"><i>📚</i><b>Batches</b><small>Manage batches</small></button><button class="quick-action" data-page="fees"><i>💰</i><b>Fees</b><small>Fee collection</small></button><button class="quick-action" data-page="attendance"><i>✅</i><b>Attendance</b><small>Take attendance</small></button><button class="quick-action" data-page="routine"><i>🗓️</i><b>Routine</b><small>Class routine</small></button></div></section><div class="dashboard-columns"><div class="content-card"><h2>Today's Attendance</h2><p>Thursday, September 10</p><div class="attendance-summary"><div><b>218</b><span>Present</span></div><div><b>22</b><span>Absent</span></div><div><b>8</b><span>Late</span></div></div></div><div class="content-card"><h2>Fee Overview</h2><p>Current month</p><div class="fee-overview"><div><span>Collected</span><b>৳85,500</b></div><div><span>Due</span><b>৳24,500</b></div></div></div></div></main>`;bind()}
function studentsPage(){const list=students();app.innerHTML=`${header()}<main class="dashboard"><div class="page-header"><div><h1>Students</h1><p>Manage all students of your institute</p></div><button class="primary-btn" data-page="add">+ Add Student</button></div><div class="content-card"><input id="search" class="search-input" placeholder="Search by name, ID or phone..."/><div class="student-list-header"><b>${list.length} Students</b><span>Active students</span></div><div id="list" class="students-list">${list.map((s,i)=>card(s,i)).join('')}</div></div></main>`;document.getElementById('search')!.addEventListener('input',e=>{const q=(e.target as HTMLInputElement).value.toLowerCase();document.querySelectorAll('.student-card').forEach(x=>(x as HTMLElement).style.display=x.textContent!.toLowerCase().includes(q)?'flex':'none')});document.querySelectorAll('[data-view]').forEach(b=>b.addEventListener('click',()=>{const s=list[Number((b as HTMLElement).dataset.view)];alert(`Student Details\n\nName: ${s.name}\nID: ${s.id}\nPhone: ${s.phone}\nBatch: ${s.batch}\nMonthly Fee: ৳${s.fee}`)}));bind()}
function card(s:Student,i:number){return `<div class="student-card"><div class="student-avatar">${s.name.split(' ').map(x=>x[0]).join('').slice(0,2).toUpperCase()}</div><div class="student-info"><b>${s.name}</b><small>ID: ${s.id}</small><small>📞 ${s.phone}</small><small>📚 ${s.batch}</small></div><div class="student-fee"><small>Monthly Fee</small><b>৳${s.fee}</b></div><span class="active-status">${s.status}</span><button class="outline-btn" data-view="${i}">View</button></div>`}
function addStudent(){app.innerHTML=`${header()}<main class="dashboard"><div class="page-header"><div><h1>Add New Student</h1><p>Register a new student</p></div></div><div class="content-card"><h2>Student Information</h2><div class="form-grid">${field('studentName','Student Name *','Enter student name')}${field('studentPhone','Phone Number *','01XXXXXXXXX')}${field('studentEmail','Email','student@email.com')}${field('studentDob','Date of Birth','', 'date')}${select('studentGender','Gender',['Male','Female','Other'])}${field('guardianName','Guardian Name *','Enter guardian name')}${field('guardianPhone','Guardian Phone *','01XXXXXXXXX')}${field('address','Address','Enter address')}${select('studentCourse','Course *',['HSC Science','SSC','Computer Basic','Spoken English'])}${select('studentBatch','Batch *',['HSC 2027 Science','SSC 2027','Computer Basic'])}${field('studentFee','Monthly Fee (৳) *','2500','number')}${field('admissionDate','Admission Date *','', 'date')}</div><div class="form-actions"><button class="outline-btn" data-page="students">Cancel</button><button class="primary-btn" id="saveStudent">Save Student</button></div></div></main>`;document.getElementById('saveStudent')!.onclick=()=>{const v=(id:string)=>(document.getElementById(id) as HTMLInputElement).value.trim();const course=(document.getElementById('studentCourse') as HTMLSelectElement).value,batch=(document.getElementById('studentBatch') as HTMLSelectElement).value;if(!v('studentName')||!v('studentPhone')||!v('guardianName')||!v('guardianPhone')||!course||!batch||!v('studentFee')||!v('admissionDate'))return alert('Please fill in all required fields.');const a=get('easylearn_students');a.push({id:`EL-${Date.now()}`,name:v('studentName'),phone:v('studentPhone'),email:v('studentEmail'),dob:v('studentDob'),guardian:v('guardianName'),guardianPhone:v('guardianPhone'),address:v('address'),course,batch,fee:Number(v('studentFee')),admissionDate:v('admissionDate'),status:'Active'});set('easylearn_students',a);alert('Student added successfully!');studentsPage()};bind()}
function field(id:string,label:string,placeholder:string,type='text'){return `<div class="form-group"><label>${label}</label><input id="${id}" type="${type}" placeholder="${placeholder}"/></div>`}
function select(id:string,label:string,opts:string[]){return `<div class="form-group"><label>${label}</label><select id="${id}"><option value="">Select</option>${opts.map(x=>`<option>${x}</option>`).join('')}</select></div>`}
function batchesPage(){const list=batches();app.innerHTML=`${header()}<main class="dashboard"><div class="page-header"><div><h1>Batches</h1><p>Manage all batches</p></div><button class="primary-btn" id="newBatch">+ New Batch</button></div><div id="batchForm"></div><div class="batch-grid">${list.map((b,i)=>`<div class="batch-card"><div class="batch-card-top"><i>📚</i><span class="active-status">${b.status}</span></div><h3>${b.name}</h3><p>${b.course}</p><div class="batch-details"><div><small>Teacher</small><b>${b.teacher}</b></div><div><small>Students</small><b>${b.students}</b></div><div><small>Fee</small><b>৳${b.fee}</b></div></div><button class="outline-btn" data-batch="${i}">View</button></div>`).join('')}</div></main>`;document.getElementById('newBatch')!.onclick=()=>{document.getElementById('batchForm')!.innerHTML=`<div class="content-card"><h2>Create New Batch</h2><div class="form-grid">${field('bn','Batch Name *','HSC 2027 Science')}${field('bc','Course *','HSC Science')}${field('bt','Teacher *','Teacher name')}${field('bf','Monthly Fee *','2500','number')}</div><div class="form-actions"><button class="outline-btn" id="cancelB">Cancel</button><button class="primary-btn" id="saveB">Save Batch</button></div></div>`;document.getElementById('cancelB')!.onclick=()=>batchesPage();document.getElementById('saveB')!.onclick=()=>{const v=(id:string)=>(document.getElementById(id) as HTMLInputElement).value.trim();if(!v('bn')||!v('bc')||!v('bt')||!v('bf'))return alert('Please fill in all required fields.');const a=get('easylearn_batches');a.push({id:`B-${Date.now()}`,name:v('bn'),course:v('bc'),teacher:v('bt'),students:0,fee:Number(v('bf')),status:'Active'});set('easylearn_batches',a);batchesPage()}};bind()}
function feesPage(){const ss=students(),ps=payments();const totalFee=ss.reduce((a,s)=>a+s.fee,0),paid=ps.reduce((a,p)=>a+p.amount,0);app.innerHTML=`${header()}<main class="dashboard"><div class="page-header"><div><h1>Fees</h1><p>Manage student fees and payments</p></div><button class="primary-btn" id="collect">+ Collect Fee</button></div><div class="stats-grid"><div class="stat-card"><i>💰</i><span>Monthly Fees<strong>৳${totalFee}</strong></span></div><div class="stat-card"><i>✅</i><span>Total Paid<strong>৳${paid}</strong></span></div><div class="stat-card"><i>⏳</i><span>Total Due<strong>৳${Math.max(totalFee-paid,0)}</strong></span></div></div><div id="feeForm"></div><div class="content-card"><h2>Student Fee Status</h2>${ss.map(s=>{const p=ps.filter(x=>x.studentId===s.id).reduce((a,x)=>a+x.amount,0);return `<div class="student-card"><div class="student-avatar">${s.name[0]}</div><div class="student-info"><b>${s.name}</b><small>${s.id}</small></div><div class="student-fee"><small>Fee</small><b>৳${s.fee}</b></div><div class="student-fee"><small>Paid</small><b>৳${p}</b></div><div class="student-fee"><small>Due</small><b>৳${Math.max(s.fee-p,0)}</b></div></div>`}).join('')}</div><div class="content-card"><h2>Payment History</h2>${ps.length?ps.slice().reverse().map(p=>`<div class="history"><b>${p.name}</b><span>৳${p.amount}</span><small>${p.method} • ${p.date}</small></div>`).join(''):'<div class="empty-state">No payments yet.</div>'}</div></main>`;document.getElementById('collect')!.onclick=()=>{document.getElementById('feeForm')!.innerHTML=`<div class="content-card"><h2>Collect Student Fee</h2><div class="form-grid">${select('fs','Student',ss.map(s=>`${s.id}|${s.name}`))}${field('fa','Payment Amount (৳)','2500','number')}${select('fm','Payment Method',['Cash','bKash','Nagad','Rocket','Bank'])}${field('fd','Payment Date','', 'date')}</div><div class="form-actions"><button class="outline-btn" id="fc">Cancel</button><button class="primary-btn" id="fsave">Save Payment</button></div></div>`;const sel=document.getElementById('fs') as HTMLSelectElement;[...sel.options].forEach(o=>{if(o.value)o.textContent=o.textContent!.replace('|',' — ')});document.getElementById('fc')!.onclick=()=>feesPage();document.getElementById('fsave')!.onclick=()=>{const sid=sel.value,amount=Number((document.getElementById('fa') as HTMLInputElement).value),method=(document.getElementById('fm') as HTMLSelectElement).value,date=(document.getElementById('fd') as HTMLInputElement).value;if(!sid||!amount||!method||!date)return alert('Please fill in all required fields.');const s=ss.find(x=>x.id===sid)!;const a=payments();a.push({id:`PAY-${Date.now()}`,studentId:s.id,name:s.name,amount,method,date});set('easylearn_payments',a);alert('Payment saved successfully!');feesPage()}};bind()}
function placeholder(title:string,text:string){app.innerHTML=`${header()}<main class="dashboard"><div class="page-header"><div><h1>${title}</h1><p>${text}</p></div></div><div class="content-card empty-state"><div class="big-icon">🚧</div><h2>${title} module</h2><p>This module is prepared in the system and will be expanded in the next development stage.</p></div></main>`;bind()}
function bind(){document.querySelectorAll('[data-page]').forEach(b=>b.addEventListener('click',async()=>{const page=(b as HTMLElement).dataset.page!;if(page==='login'){await supabase.auth.signOut();login();return}go(page)}))}
function go(p:string){if(p==='login')login();else if(p==='dashboard')dashboard();else if(p==='students')studentsPage();else if(p==='add')addStudent();else if(p==='batches')batchesPage();else if(p==='fees')feesPage();else if(p==='attendance')placeholder('Attendance','Take and manage daily attendance');else if(p==='routine')placeholder('Routine','Manage class schedules and routines')}
(async()=>{
  const { data }=await supabase.auth.getSession()
  if(data.session){dashboard()}else{login()}
})()
