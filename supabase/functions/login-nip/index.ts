import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

/**
 * Edge Function: login-nip
 * 
 * Bypass RLS untuk lookup NIP/ID Karyawan di tabel users,
 * lalu sign in menggunakan email yang ditemukan.
 * 
 * Request body: { "nip": "12345", "password": "xxx" }
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

    // Cari user berdasarkan NIP atau employee_id
    const { data: userData, error: lookupError } = await supabase
      .from('users')
      .select('email')
      .or(`nip.eq.${nip},employee_id.eq.${nip}`)
      .maybeSingle();

    if (lookupError) {
      return new Response(JSON.stringify({ error: 'Gagal mencari data karyawan.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!userData || !userData.email) {
      return new Response(JSON.stringify({ error: 'ID Karyawan / NIP tidak ditemukan.' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Sign in dengan email yang ditemukan
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: userData.email,
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
