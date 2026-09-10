import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://obyvxtxfteipfisubvfj.supabase.co'

const supabasePublishableKey =
  'sb_publishable_e0Bvd0k5EDZ5GSia8RhJ9g_yCFkQaB1'

export const supabase = createClient(
  supabaseUrl,
  supabasePublishableKey
)