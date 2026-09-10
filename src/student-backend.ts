import { supabase } from './supabase'

const STUDENT_KEY = 'easylearn_students'
let studentCache: any[] = []
let ready = false
let lastWrittenIds = new Set<string>()

async function currentInstituteId(): Promise<string | null> {
  const { data: sessionData } = await supabase.auth.getSession()
  const user = sessionData.session?.user
  if (!user) return null

  const { data, error } = await supabase
    .from('profiles')
    .select('institute_id')
    .eq('id', user.id)
    .single()

  if (error || !data?.institute_id) {
    console.warn('Could not resolve institute for current user.', error?.message)
    return null
  }

  return data.institute_id
}

function mapRow(row: any) {
  return {
    id: row.student_id || row.id,
    name: row.name || '',
    phone: row.phone || '',
    batch: '',
    fee: 0,
    status: row.status || 'Active',
    email: '',
    dob: row.dob || '',
    gender: row.gender || '',
    guardian: row.guardian_name || '',
    guardianPhone: row.guardian_phone || '',
    address: row.address || '',
    admissionDate: row.admission_date || ''
  }
}

async function loadStudents() {
  const instituteId = await currentInstituteId()
  if (!instituteId) return

  const { data, error } = await supabase
    .from('students')
    .select('id,institute_id,student_id,name,phone,guardian_name,guardian_phone,address,dob,gender,admission_date,status')
    .eq('institute_id', instituteId)
    .order('created_at', { ascending: false })

  if (error) {
    console.warn('Student sync failed:', error.message)
    return
  }

  studentCache = (data || []).map(mapRow)
  ready = true
}

async function insertStudent(student: any) {
  const instituteId = await currentInstituteId()
  if (!instituteId) return

  const { data, error } = await supabase
    .from('students')
    .insert({
      institute_id: instituteId,
      student_id: student.id,
      name: student.name,
      phone: student.phone,
      guardian_name: student.guardian || null,
      guardian_phone: student.guardianPhone || null,
      address: student.address || null,
      dob: student.dob || null,
      gender: student.gender || null,
      admission_date: student.admissionDate || null,
      status: student.status || 'Active'
    })
    .select('id,institute_id,student_id,name,phone,guardian_name,guardian_phone,address,dob,gender,admission_date,status')
    .single()

  if (error) {
    console.error('Student save failed:', error.message)
    return
  }

  const mapped = mapRow(data)
  const index = studentCache.findIndex(x => x.id === mapped.id)
  if (index >= 0) studentCache[index] = mapped
  else studentCache.unshift(mapped)
  ready = true
  lastWrittenIds.add(mapped.id)
}

const originalGetItem = Storage.prototype.getItem
const originalSetItem = Storage.prototype.setItem

Storage.prototype.getItem = function(key: string) {
  if (key === STUDENT_KEY && ready) return JSON.stringify(studentCache)
  return originalGetItem.call(this, key)
}

Storage.prototype.setItem = function(key: string, value: string) {
  if (key === STUDENT_KEY) {
    let next: any[] = []
    try { next = JSON.parse(value || '[]') } catch { next = [] }

    const previousIds = new Set(studentCache.map(x => x.id))
    const added = next.filter(x => x?.id && !previousIds.has(x.id) && !lastWrittenIds.has(x.id))
    studentCache = next

    for (const student of added) void insertStudent(student)
    return
  }

  return originalSetItem.call(this, key, value)
}

supabase.auth.onAuthStateChange((_event, session) => {
  if (session) {
    window.setTimeout(() => { void loadStudents() }, 0)
  } else {
    studentCache = []
    ready = false
  }
})

void loadStudents()
