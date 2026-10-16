// ============================================================
// FILL THESE IN with your own Supabase project's values.
// Dashboard > Project Settings > API > "Project URL" and "anon public" key.
// This "anon" key is safe to expose in a public frontend — access is
// controlled by the Row Level Security policies in schema.sql, not by
// keeping this key secret.
// ============================================================
const SUPABASE_URL = "https://yneyidzigakknmbegxuf.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InluZXlpZHppZ2Fra25tYmVneHVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2MDY1ODIsImV4cCI6MjEwNjE4MjU4Mn0.m35VkbmMhKnlas3ZAK5mLTqCoCbgDWdt55WqWHSZzD4";

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
