import { supabase } from '../supabase'

export async function getCurrentInstituteId(): Promise<string> {
  const { data, error } = await supabase.rpc('ensure_my_institute')
  if (error || !data) throw new Error(error?.message || 'Institute could not be resolved')
  return data as string
}

export async function getCurrentUser() {
  const { data, error } = await supabase.auth.getUser()
  if (error || !data.user) throw new Error(error?.message || 'You must be logged in')
  return data.user
}

export function cleanText(value: unknown): string | null {
  const text = String(value ?? '').trim()
  return text ? text : null
}

export function positiveAmount(value: unknown): number {
  const n = Number(value)
  if (!Number.isFinite(n) || n <= 0) throw new Error('Amount must be greater than 0')
  return n
}
