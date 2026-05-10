import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

/**
 * Edge Function: login-nip
 * 
 * Bypass RLS untuk lookup NIP/ID Karyawan di tabel users,
 * lalu sign in menggunakan email yang ditemukan.
 * 
 * Pencarian berdasarkan (prioritas):
 * 1. kolom nip
 * 2. kolom employee_id
 * 3. kolom email (jika input berupa email)
 * 
 * Request body: { "nip": "1234", "password": "xxx" }
 * Response: { "session": {...}, "user": {...} } atau { "error": "..." }
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: 'Server configuration error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { nip, password } = await req.json();

    if (!nip || !password) {
      return new Response(JSON.stringify({ error: 'NIP dan password wajib diisi.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Client dengan service_role_key → bypass RLS
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const trimmedNip = nip.trim();
    let email: string | null = null;

    // Strategi 1: Cari berdasarkan kolom nip atau employee_id
    const { data: userData, error: lookupError } = await supabase
      .from('users')
      .select('email, nip, employee_id')
      .or(`nip.eq.${trimmedNip},employee_id.eq.${trimmedNip}`)
      .maybeSingle();

    if (lookupError) {
      console.error('Lookup error:', lookupError.message);
    }

    if (userData?.email) {
      email = userData.email;
    }

    // Strategi 2: Jika tidak ketemu, coba cari langsung di email
    // (untuk backward compatibility jika NIP = email)
    if (!email) {
      const emailToTry = trimmedNip.includes('@') 
        ? trimmedNip 
        : `${trimmedNip}@ruaitv.local`;

      const { data: emailUser } = await supabase
        .from('users')
        .select('email')
        .eq('email', emailToTry)
        .maybeSingle();

      if (emailUser?.email) {
        email = emailUser.email;
      }
    }

    // Strategi 3: Coba langsung sign in dengan format nip@ruaitv.local
    // (jika user dibuat dengan format email ini)
    if (!email) {
      const fallbackEmail = trimmedNip.includes('@') 
        ? trimmedNip 
        : `${trimmedNip}@ruaitv.local`;
      
      const { data: directAuth, error: directError } = await supabase.auth.signInWithPassword({
        email: fallbackEmail,
        password: password,
      });

      if (!directError && directAuth.session) {
        return new Response(JSON.stringify({
          session: directAuth.session,
          user: directAuth.user,
        }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    if (!email) {
      return new Response(JSON.stringify({ error: 'ID Karyawan/NIP tidak ditemukan.' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Sign in dengan email yang ditemukan
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password,
    });

    if (authError) {
      return new Response(JSON.stringify({ error: 'Password salah.' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({
      session: authData.session,
      user: authData.user,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('login-nip error:', error);
    return new Response(JSON.stringify({
      error: error instanceof Error ? error.message : 'Internal server error',
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
