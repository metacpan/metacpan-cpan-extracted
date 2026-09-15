#!/usr/bin/env perl
##----------------------------------------------------------------------------
## WebAuthn - scripts/webauthn.psgi
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use FindBin;
    use DBI;
    use JSON;
    use Plack::Builder;
    use Plack::Request;
    use Web::Authn;
};

use strict;
use warnings;

# Tiny Plack Relying Party used by Web::Authn::Cookbook.
#
#   cpanm Plack Plack::Middleware::Session DBI DBD::SQLite JSON
#   plackup -l http://localhost:5000 scripts/webauthn.psgi
#
# Open http://localhost:5000 — demo user is alice@example.com.

my $RP_ID   = $ENV{WEBAUTHN_RP_ID}   || 'localhost';
my $RP_NAME = $ENV{WEBAUTHN_RP_NAME} || 'Web::Authn Cookbook';
my $ORIGIN  = $ENV{WEBAUTHN_ORIGIN}  || 'http://localhost:5000';
my $DBFILE  = $ENV{WEBAUTHN_DB}      || "$FindBin::Bin/webauthn-cookbook.sqlite";

my $JSON = JSON->new->utf8;

my $authn = Web::Authn->new(
    rp_id           => $RP_ID,
    rp_name         => $RP_NAME,
    expected_origin => $ORIGIN,
);

sub dbh
{
    my $need_schema = !-e $DBFILE;
    my $dbh = DBI->connect( "dbi:SQLite:dbname=$DBFILE", undef, undef,
    {
        RaiseError      => 1,
        AutoCommit      => 1,
        sqlite_see_blob => 1,
    });
    if( $need_schema )
    {
        my $sql = do
        {
            open( my $fh, '<', "$FindBin::Bin/schema.sql" ) or die( $! );
            local $/;
            <$fh>;
        };
        $dbh->do( $_ ) for( grep{ /\S/ } split( /;/, $sql ) );
        my $handle = $authn->generate_user_handle;
        $dbh->do(
            q{INSERT INTO users (email, display_name, user_handle) VALUES (?,?,?)},
            undef, 'alice@example.com', 'Alice', $handle,
        );
    }
    return( $dbh );
}

sub current_user
{
    my $env = shift( @_ );
    my $id  = $env->{'psgix.session'}->{user_id} || return;
    return( dbh()->selectrow_hashref( q{SELECT * FROM users WHERE id = ?}, undef, $id ) );
}

sub json_res
{
    my( $code, $data ) = @_;
    my $body = ref( $data ) ? $JSON->encode( $data ) : $data;
    return([
        $code,
        [ 'Content-Type' => 'application/json; charset=utf-8' ],
        [ $body ],
    ]);
}

sub html_res
{
    my $body = shift( @_ );
    return([ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ $body ] ]);
}

sub demo_page
{
    return( <<'HTML' );
<!doctype html>
<meta charset="utf-8">
<title>Web::Authn cookbook demo</title>
<style>
  body { font: 16px/1.4 system-ui, sans-serif; max-width: 40rem; margin: 2rem auto; }
  button { margin: .25rem .25rem 0 0; padding: .4rem .8rem; }
  pre { background: #f4f4f4; padding: .75rem; overflow: auto; }
  label { display: block; margin: .5rem 0; }
</style>
<h1>Web::Authn cookbook</h1>
<p>Demo account: <code>alice@example.com</code>. This page talks to the
four JSON endpoints in this script.</p>
<label>Email <input id="email" value="alice@example.com"></label>
<p>
  <button id="login-pw">Establish demo session</button>
  <button id="reg">Register passkey</button>
  <button id="login-pk">Login with passkey</button>
  <button id="logout">Logout</button>
</p>
<pre id="log"></pre>
<script type="module">
  const log = (m) => {
    document.getElementById('log').textContent += m + "\\n";
  };
  const json = (r) => r.text().then((t) => {
    try { return JSON.parse(t); } catch { return t; }
  });

  const b64uToBytes = (s) => {
    s = s.replace(/-/g, '+').replace(/_/g, '/');
    while (s.length % 4) s += '=';
    const bin = atob(s);
    return Uint8Array.from(bin, (c) => c.charCodeAt(0));
  };
  const bytesToB64u = (buf) => {
    const bytes = new Uint8Array(buf);
    let s = '';
    bytes.forEach((b) => { s += String.fromCharCode(b); });
    return btoa(s).replace(/\\+/g, '-').replace(/\\//g, '_').replace(/=+$/, '');
  };
  const decodeCreate = (o) => {
    o.challenge = b64uToBytes(o.challenge);
    o.user.id = b64uToBytes(o.user.id);
    (o.excludeCredentials || []).forEach((c) => { c.id = b64uToBytes(c.id); });
    return o;
  };
  const decodeGet = (o) => {
    o.challenge = b64uToBytes(o.challenge);
    (o.allowCredentials || []).forEach((c) => { c.id = b64uToBytes(c.id); });
    return o;
  };
  const encodeCred = (cred) => ({
    id: cred.id,
    rawId: bytesToB64u(cred.rawId),
    type: cred.type,
    response: Object.fromEntries(
      Object.entries(cred.response).map(([k, v]) => [
        k,
        (typeof v === 'string' || v == null) ? v : bytesToB64u(v),
      ])
    ),
    clientExtensionResults: cred.getClientExtensionResults(),
  });

  document.getElementById('login-pw').onclick = async () => {
    const r = await fetch('/session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: document.getElementById('email').value }),
    });
    log('session ' + r.status + ' ' + JSON.stringify(await json(r)));
  };
  document.getElementById('logout').onclick = async () => {
    log('logout ' + (await fetch('/session', { method: 'DELETE' })).status);
  };
  document.getElementById('reg').onclick = async () => {
    const begin = await fetch('/webauthn/register/begin', { method: 'POST' });
    const opts = await json(begin);
    log('register/begin ' + begin.status);
    if (!begin.ok) { log(JSON.stringify(opts)); return; }
    const cred = await navigator.credentials.create({ publicKey: decodeCreate(opts) });
    const done = await fetch('/webauthn/register/complete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(encodeCred(cred)),
    });
    log('register/complete ' + done.status + ' ' + JSON.stringify(await json(done)));
  };
  document.getElementById('login-pk').onclick = async () => {
    const begin = await fetch('/webauthn/login/begin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: document.getElementById('email').value }),
    });
    const opts = await json(begin);
    log('login/begin ' + begin.status);
    if (!begin.ok) { log(JSON.stringify(opts)); return; }
    const cred = await navigator.credentials.get({ publicKey: decodeGet(opts) });
    const done = await fetch('/webauthn/login/complete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(encodeCred(cred)),
    });
    log('login/complete ' + done.status + ' ' + JSON.stringify(await json(done)));
  };
</script>

HTML
}

my $app = sub
{
    my $env     = shift( @_ );
    my $req     = Plack::Request->new( $env );
    my $path    = $req->path;
    my $method  = $req->method;
    my $session = $env->{'psgix.session'};

    if( $path eq '/' && $method eq 'GET' )
    {
        return( html_res( demo_page() ) );
    }

    if( $path eq '/session' && $method eq 'POST' )
    {
        my $body = eval{ $JSON->decode( $req->content ) } || {};
        my $user = dbh()->selectrow_hashref(
            q{SELECT * FROM users WHERE email = ?}, undef, $body->{email} || '',
        );
        $user or return( json_res( 404, { error => 'unknown user' } ) );
        $session->{user_id} = $user->{id};
        return( json_res( 200, { ok => \1, email => $user->{email} } ) );
    }
    if( $path eq '/session' && $method eq 'DELETE' )
    {
        %$session = ();
        return( json_res( 200, { ok => \1 } ) );
    }

    if( $path eq '/webauthn/register/begin' && $method eq 'POST' )
    {
        my $user = current_user( $env ) ||
            return( json_res( 401, { error => 'login first' } ) );
        my $sth = dbh()->prepare( q{SELECT credential_id FROM credentials WHERE user_id = ?} );
        $sth->execute( $user->{id} );
        my @exclude;
        while( my $row = $sth->fetchrow_hashref )
        {
            push( @exclude, { type => 'public-key', id => $row->{credential_id} } );
        }
        my $opts = $authn->generate_registration_options(
            user_name               => $user->{email},
            user_id                 => $user->{user_handle},
            user_display_name       => $user->{display_name},
            exclude_credentials     => \@exclude,
            authenticator_selection =>
            {
                resident_key      => 'preferred',
                user_verification => 'preferred',
            },
            attestation => 'none',
        ) || return( json_res( 500, { error => '' . $authn->error } ) );
        $session->{webauthn_challenge} = $opts->{challenge};
        return( json_res( 200, $authn->options_to_json( $opts ) ) );
    }

    if( $path eq '/webauthn/register/complete' && $method eq 'POST' )
    {
        my $user = current_user( $env ) ||
            return( json_res( 401, { error => 'login first' } ) );
        my $challenge = delete( $session->{webauthn_challenge} ) ||
            return( json_res( 400, { error => 'no challenge' } ) );
        my $body = eval{ $JSON->decode( $req->content ) } ||
            return( json_res( 400, { error => 'invalid json' } ) );
        my $reg = $authn->verify_registration_response(
            credential         => $body,
            expected_challenge => $challenge,
        );
        unless( $reg )
        {
            return( json_res( 400, { error => 'registration failed', detail => '' . $authn->error } ) );
        }
        dbh()->do(
            q{INSERT INTO credentials
              (user_id, credential_id, public_key, sign_count, aaguid, fmt,
               device_type, backed_up)
              VALUES (?,?,?,?,?,?,?,?)},
            undef,
            $user->{id},
            $reg->{credential_id},
            $reg->{credential_public_key},
            $reg->{sign_count},
            $reg->{aaguid},
            $reg->{fmt},
            $reg->{credential_device_type},
            $reg->{credential_backed_up} ? 1 : 0,
        );
        return( json_res( 200, { ok => \1, aaguid => $reg->{aaguid} } ) );
    }

    if( $path eq '/webauthn/login/begin' && $method eq 'POST' )
    {
        my $body = eval{ $JSON->decode( $req->content ) } || {};
        my $user = dbh()->selectrow_hashref(
            q{SELECT * FROM users WHERE email = ?}, undef, $body->{email} || '',
        ) || return( json_res( 404, { error => 'unknown user' } ) );
        my $sth = dbh()->prepare( q{SELECT credential_id FROM credentials WHERE user_id = ?} );
        $sth->execute( $user->{id} );
        my @allow;
        while( my $row = $sth->fetchrow_hashref )
        {
            push( @allow, { type => 'public-key', id => $row->{credential_id} } );
        }
        @allow or return( json_res( 400, { error => 'no passkeys' } ) );
        my $opts = $authn->generate_authentication_options(
            allow_credentials => \@allow,
            user_verification => 'preferred',
        ) || return( json_res( 500, { error => '' . $authn->error } ) );
        $session->{webauthn_challenge} = $opts->{challenge};
        $session->{webauthn_user_id}   = $user->{id};
        return( json_res( 200, $authn->options_to_json( $opts ) ) );
    }

    if( $path eq '/webauthn/login/complete' && $method eq 'POST' )
    {
        my $challenge = delete( $session->{webauthn_challenge} ) ||
            return( json_res( 400, { error => 'no challenge' } ) );
        my $body = eval{ $JSON->decode( $req->content ) } ||
            return( json_res( 400, { error => 'invalid json' } ) );
        my $cred_id = $authn->base64url_to_bytes( $body->{id} ) ||
            return( json_res( 400, { error => 'bad id' } ) );
        my $row = dbh()->selectrow_hashref(
            q{SELECT * FROM credentials WHERE credential_id = ?}, undef, $cred_id,
        ) || return( json_res( 400, { error => 'unknown credential' } ) );
        my $ok = $authn->verify_authentication_response(
            credential                    => $body,
            expected_challenge            => $challenge,
            credential_public_key         => $row->{public_key},
            credential_current_sign_count => $row->{sign_count},
        );
        unless( $ok )
        {
            return( json_res( 401, { error => 'authentication failed', detail => '' . $authn->error } ) );
        }
        dbh()->do(
            q{UPDATE credentials SET sign_count = ? WHERE id = ?},
            undef, $ok->{new_sign_count}, $row->{id},
        );
        $session->{user_id} = $row->{user_id};
        return( json_res( 200, { ok => \1 } ) );
    }

    return( json_res( 404, { error => 'not found' } ) );
};

builder
{
    enable( 'Session' );
    $app;
};

__END__
