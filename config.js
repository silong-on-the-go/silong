/* SILONG settings. Leave a value empty to keep that feature off.

   SUPABASE_URL and SUPABASE_KEY switch on real accounts (they work across devices) and the visit
   counter (stats.html). Find both in Supabase: Project Settings, API Keys. Use the Project URL and the
   publishable key (or the legacy anon key). Both are meant to be public: the database's row-level
   security (supabase/setup.sql) decides what anyone can read or write. Never put a secret or
   service_role key here.

   GOOGLE_MAPS_API_KEY is optional. Empty keeps the free OpenStreetMap map. */
window.SILONG_CONFIG = {
  SUPABASE_URL: '',
  SUPABASE_KEY: '',
  GOOGLE_MAPS_API_KEY: ''
};
