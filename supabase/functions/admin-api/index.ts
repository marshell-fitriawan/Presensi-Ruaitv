import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

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
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');

    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      return new Response(JSON.stringify({ error: 'Missing Supabase configuration' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 🔐 VALIDASI USER LOGIN
    const supabaseUser = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user } } = await supabaseUser.auth.getUser();

    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 🔥 CLIENT ADMIN (BYPASS RLS)
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    // 🔥 CEK ROLE ADMIN (dari table users)
    const { data: adminData, error: roleError } = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    if (roleError || adminData?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Forbidden: Admin only' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { action, payload } = await req.json();

    // =========================
    // USERS
    // =========================

    if (action === 'get_users') {
      const { data, error } = await supabase.from('users').select('*').order('name');
      return new Response(JSON.stringify({ data, error }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'create_user') {
      const { email, password, name, nip, department, role } = payload;

      const { data: userData, error: createError } =
        await supabase.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
        });

      if (createError) {
        return new Response(JSON.stringify({ error: createError.message }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const userId = userData.user?.id;

      const { error: profileError } = await supabase.from('users').insert({
        id: userId,
        name,
        email,
        nip: nip || null,
        employee_id: nip || null,
        department,
        role,
        is_active: true,
      });

      return new Response(JSON.stringify({ error: profileError }), {
        status: profileError ? 400 : 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'update_user') {
      const { id, ...rest } = payload;

      const { data, error } = await supabase
        .from('users')
        .update(rest)
        .eq('id', id);

      return new Response(JSON.stringify({ data, error }), {
        status: error ? 400 : 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'delete_user') {
      const { id } = payload;

      // delete dari auth
      await supabase.auth.admin.deleteUser(id);

      // delete dari table
      const { error } = await supabase.from('users').delete().eq('id', id);

      return new Response(JSON.stringify({ error }), {
        status: error ? 400 : 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // =========================
    // ATTENDANCE
    // =========================

    if (action === 'get_attendance') {
      const { data, error } = await supabase
        .from('attendance')
        .select('*')
        .order('timestamp', { ascending: false });

      return new Response(JSON.stringify({ data, error }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'approve_attendance') {
      const { id } = payload;

      const { data, error } = await supabase
        .from('attendance')
        .update({ status: 'approved' })
        .eq('id', id);

      return new Response(JSON.stringify({ data, error }), {
        status: error ? 400 : 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'reject_attendance') {
      const { id } = payload;

      const { data, error } = await supabase
        .from('attendance')
        .update({ status: 'rejected' })
        .eq('id', id);

      return new Response(JSON.stringify({ data, error }), {
        status: error ? 400 : 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'Unknown action' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Edge function error:', error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Internal server error',
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});