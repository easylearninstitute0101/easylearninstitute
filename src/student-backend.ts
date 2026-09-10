import { supabase } from './supabase'

const STUDENT_KEY = 'easylearn_students'
let studentCache: any[] = []
let ready = false
let lastWrittenIds = new Set<string>()

async function currentUserAndInstitute() {
  const { data: sessionData } = await supabase.auth.getSession()
  const user = sessionData.session?.user
  if (!user) return null

  // Resolve the institute through the secure database function.
  // This also repairs an existing profile that has no institute_id.
  const { data: instituteId, error } = await supabase.rpc('ensure_my_institute')

  if (error || !instituteId) {
    console.warn('Could not find your institute.', error?.message)
    return null
  }

  return { user, instituteId: instituteId as string }
}

function mapRow(row: any) {
  return {
    id: row.student_id || row.id,
    name: row.full_name || '',
    phone: row.phone || '',
    batch: '',
    fee: 0,
    status: row.status || 'Active',
    email: row.email || '',
    dob: row.date_of_birth || '',
    gender: row.gender || '',
    guardian: row.guardian_name || '',
    guardianPhone: row.guardian_phone || '',
    address: row.address || '',
    admissionDate: row.admission_date || ''
  }
}

export async function refreshStudents() {
  const context = await currentUserAndInstitute()
  if (!context) return

  const { data, error } = await supabase
    .from('students')
    .select('id,institute_id,user_id,student_id,full_name,phone,email,guardian_name,guardian_phone,address,date_of_birth,gender,admission_date,status,created_at,updated_at')
    .eq('institute_id', context.instituteId)
    .order('created_at', { ascending: false })

  if (error) {
    console.warn('Student sync failed:', error.message)
    alert(`Student load failed: ${error.message}`)
    return
  }

  studentCache = (data || []).map(mapRow)
  ready = true
}

async function insertStudent(student: any) {
  const context = await currentUserAndInstitute()
  if (!context) {
    alert('Could not find your institute. Please log out and log in again.')
    return
  }

  const { data, error } = await supabase
    .from('students')
    .insert({
      institute_id: context.instituteId,
      user_id: context.user.id,
      student_id: student.id,
      full_name: student.name,
      phone: student.phone,
      email: student.email || null,
      guardian_name: student.guardian || null,
      guardian_phone: student.guardianPhone || null,
      address: student.address || null,
      date_of_birth: student.dob || null,
      gender: student.gender || null,
      admission_date: student.admissionDate || null,
      status: student.status || 'Active'
    })
    .select('id,institute_id,user_id,student_id,full_name,phone,email,guardian_name,guardian_phone,address,date_of_birth,gender,admission_date,status,created_at,updated_at')
    .single()

  if (error) {
    console.error('Student save failed:', error.message)
    alert(`Student save failed: ${error.message}`)
    return
  }

  const mapped = mapRow(data)
  const index = studentCache.findIndex(x => x.id === mapped.id)
  if (index >= 0) studentCache[index] = mapped
  else studentCache.unshift(mapped)
  ready = true
  lastWrittenIds.add(mapped.id)

  // Confirm the database state after a successful insert.
  await refreshStudents()
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
    ready = true

    for (const student of added) void insertStudent(student)
    return
  }

  return originalSetItem.call(this, key, value)
}

supabase.auth.onAuthStateChange((_event, session) => {
  if (session) {
    window.setTimeout(() => { void refreshStudents() }, 0)
  } else {
    studentCache = []
    ready = false
  }
})

void refreshStudents()
