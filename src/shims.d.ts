declare interface ImportMetaEnv { readonly VITE_SUPABASE_URL?: string; readonly VITE_SUPABASE_PUBLISHABLE_KEY?: string; }
declare interface ImportMeta { readonly env: ImportMetaEnv; }
declare module '@supabase/supabase-js' { export function createClient(...args:any[]): any; }
