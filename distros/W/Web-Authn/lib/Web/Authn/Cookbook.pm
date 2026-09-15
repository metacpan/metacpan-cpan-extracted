##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn/Cookbook.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/09/09
## Modified 2026/09/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Web::Authn::Cookbook;
BEGIN
{
    use strict;
    use warnings;
    our $VERSION = 'v0.1.0';
};

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Web::Authn::Cookbook - Implementing passkeys with L<Web::Authn>

=head1 PURPOSE

This document is a start-to-finish recipe for a Relying Party (your website) using L<Web::Authn>. It assumes you can run HTTPS (or C<http://localhost>), store rows in a database, and keep a short-lived session. It does not assume Mojolicious, Dancer, Catalyst, or any particular ORM — the endpoint bodies are plain Perl you can paste behind whatever framework you use.

Runnable companions live in F<scripts/>:

=over

=item F<scripts/schema.sql>

SQLite / PostgreSQL-friendly tables.

=item F<scripts/print-options.pl>

Prints registration and authentication JSON with no server.

=item F<scripts/webauthn.psgi>

A tiny Plack app using the object-oriented API: four JSON routes + SQLite + cookie sessions.

=item F<scripts/webauthn-using-class-functions.psgi>

The same app, written with the exported class functions.

=back

    perldoc Web::Authn::Cookbook
    plackup scripts/webauthn.psgi

=head1 THE MODEL IN ONE PAGE

A passkey is an asymmetric key pair. The B<authenticator> (Touch ID, Windows Hello, a YubiKey, a phone via hybrid) holds the private key and never sends it. You store only:

=over

=item * C<credential_id> — opaque bytes the authenticator chose

=item * C<public_key> — a COSE_Key, stored as raw bytes

=item * C<sign_count> — monotonic counter used to detect cloned keys

=item * C<user_handle> — random bytes you put in C<user.id> at
registration, stable for the life of the account

=back

WebAuthn (and FIDO before it) calls each end-to-end dance a ceremony: browser, authenticator, and relying party exchanging a challenge and a signed response. There are two of them:

=over 4

=item * Registration ceremony — navigator.credentials.create() / attestation

=item * Authentication ceremony — navigator.credentials.get() / assertion

=back

W3C WebAuthn titles the Relying Party (i.e. the Perl app using Web::Authn) procedures that way: “Registering a New Credential” and “Verifying an Authentication Assertion” sit under some ceremonies.

There are two ceremonies:

    REGISTER                          LOGIN
    POST /webauthn/register/begin     POST /webauthn/login/begin
           | options JSON                    | options JSON
           v                                 v
    navigator.credentials.create()    navigator.credentials.get()
           |                                 |
    POST /webauthn/register/complete  POST /webauthn/login/complete
           | verify + INSERT                 | verify + UPDATE sign_count
           v                                 v
    row in credentials                session cookie

=head1 BEFORE ANY CODE

=head2 Origin and rp_id

WebAuthn only works in a B<secure context>.

    Production page   https://app.example.com
    rp_id             example.com          # or app.example.com
    expected_origin   https://app.example.com

    Local page        http://localhost:5000
    rp_id             localhost
    expected_origin   http://localhost:5000

C<rp_id> must be equal to the page's registrable domain, or a suffix of it. C<expected_origin> is the B<full origin> (scheme + host + port if non-default). Do not take either value from the client.

    my %RP = (
        rp_id   => 'example.com',
        rp_name => 'Example Co',
        origin  => 'https://app.example.com',
    );

=head2 Dependencies

    cpanm CryptX Bytes::Random::Secure
    # for the sample PSGI app:
    cpanm Plack Plack::Middleware::Session DBI DBD::SQLite JSON::PP

L<Web::Authn> itself only needs CryptX and Bytes::Random::Secure.

=head2 Policy knobs

Start here for consumer passkeys:

    authenticator_selection => {
        resident_key      => 'preferred',  # 'required' = passkeys only
        user_verification => 'preferred',  # 'required' = passwordless
    },
    attestation => 'none',

Use C<< attestation => 'direct' >> only if you will inspect vendor certificates and pass roots in C<pem_root_certs_bytes_by_fmt>.

=head1 DATABASE SCHEMA

The sample schema is in F<scripts/schema.sql>. Two tables plus an optional challenge table if you do not want to keep the challenge in the session store.

=head2 SQLite

    CREATE TABLE users (
         id            INTEGER PRIMARY KEY
        ,email         TEXT    NOT NULL UNIQUE
        ,display_name  TEXT    NOT NULL
        -- WebAuthn user handle: 16–64 random bytes, NOT the email.
        ,user_handle   BLOB    NOT NULL UNIQUE
    );

    CREATE TABLE credentials (
         id              INTEGER PRIMARY KEY
        ,user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
        ,credential_id   BLOB    NOT NULL UNIQUE
        ,public_key      BLOB    NOT NULL          -- COSE_Key
        ,sign_count      INTEGER NOT NULL DEFAULT 0
        ,aaguid          TEXT
        ,fmt             TEXT
        ,transports      TEXT                      -- JSON array
        ,device_type     TEXT                      -- singleDevice | multiDevice
        ,backed_up       INTEGER NOT NULL DEFAULT 0
        ,created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );

    CREATE INDEX credentials_user ON credentials(user_id);

    -- Optional if your session store cannot hold raw bytes:
    CREATE TABLE webauthn_challenges (
         id          INTEGER PRIMARY KEY
        ,session_id  TEXT    NOT NULL
        ,purpose     TEXT    NOT NULL              -- register | login
        ,challenge   BLOB    NOT NULL
        ,user_id     INTEGER
        ,expires_at  INTEGER NOT NULL
    );

=head2 PostgreSQL

Same columns; use C<BYTEA> instead of C<BLOB>, C<BOOLEAN> for C<backed_up>, C<TIMESTAMPTZ> for C<created_at>.

=head2 What each column is

=over

=item C<users.user_handle>

Created once with C<< $authn->generate_user_handle >>. Sent as C<user.id> at every registration. Some authenticators echo it back as C<userHandle> on login; you can use that to find the account during usernameless login.

=item C<credentials.credential_id>

Primary lookup key on login. Compare as raw bytes, not as a locale-sensitive string.

=item C<credentials.public_key>

The exact C<credential_public_key> bytes returned by C<< $authn->verify_registration_response >>. Do not re-encode them.

=item C<credentials.sign_count>

Write C<new_sign_count> after every successful login. If the authenticator reports a value that is not greater than the stored value (and either is non-zero), L<Web::Authn> rejects the assertion.

=back

=head1 SESSION

You need somewhere to keep the challenge between C</begin> and C</complete>. A signed cookie session, Redis, or the C<webauthn_challenges> table all work. Rules:

=over

=item * 16+ random bytes (the module default is 64).

=item * One challenge, one use. Delete it after verify, success or failure.

=item * Expire it (60–300 seconds). The C<timeout> in the options is only a browser hint.

=back

    $session->{webauthn_challenge} = $opts->{challenge};   # raw bytes
    $session->{webauthn_user_id}   = $user->{id};          # register

=head1 FOUR ENDPOINTS

All four accept and return C<application/json>. CSRF: these mutate state, so require your normal session cookie + SameSite, or a CSRF token. Do not skip authentication on register/begin — the user must already be identified (logged in with a password, or mid-signup after email verify).

The snippets below use a fictional C<$c> request object with C<< $c->session >>, C<< $c->json >>, C<< $c->render_json >>, and a fictional C<$db> with C<dbh>. Adapt the plumbing; keep the L<Web::Authn> calls as written.

Two calling styles are equivalent. Pick one and stay with it.

B<Object-oriented (recommended).> Build one C<Web::Authn> per process (or per request) with the Relying Party identity. Methods return C<undef> and set L<Web::Authn/error> on failure; they C<die> only if L<Web::Authn/fatal> is true.

    use Web::Authn;

    my $authn = Web::Authn->new(
        rp_id           => $RP{rp_id},
        rp_name         => $RP{rp_name},
        expected_origin => $RP{origin},
    );

B<Class functions.> The names exported by L<Web::Authn> still work. They build a temporary object internally. Failures are reported the same way (C<undef> + C<< Web::Authn->error >>), unless you set C<fatal> on that temporary object — so for C<eval> / C<die> you either enable fatal or check C<< Web::Authn->error >>. The historical C<eval { ... }> pattern still works if the called function throws (helpers such as L<Web::Authn::Parse> still C<throw>), but the public wrappers prefer C<error>.

    use Web::Authn qw(
        generate_registration_options
        verify_registration_response
        generate_authentication_options
        verify_authentication_response
        options_to_json
        bytes_to_base64url
        base64url_to_bytes
        generate_user_handle
    );

=head2 POST /webauthn/register/begin

Call this when an already-identified user clicks “Add a passkey”.

    sub register_begin
    {
        my $c = shift( @_ );
        my $user = $c->current_user or return $c->status(401);

        my $handle = $user->{user_handle};
        if( !defined( $handle ) || !length( $handle ) )
        {
            $handle = $authn->generate_user_handle;
            $db->update_user_handle( $user->{id}, $handle );
            $user->{user_handle} = $handle;
        }

        my @exclude = map
        {
            {
                type       => 'public-key',
                id         => $_->{credential_id},
                transports => $_->{transports},
            }
        } $db->credentials_for( $user->{id} );

        my $opts = $authn->generate_registration_options(
            user_name               => $user->{email},
            user_id                 => $handle,
            user_display_name       => $user->{display_name},
            exclude_credentials     => \@exclude,
            authenticator_selection =>
            {
                resident_key      => 'preferred',
                user_verification => 'preferred',
            },
            attestation => 'none',
            timeout     => 60_000,
        ) || return( $c->status( 500, $authn->error->message ) );

        $c->session->{webauthn_challenge} = $opts->{challenge};
        $c->session->{webauthn_user_id}   = $user->{id};

        return( $c->render_json_raw( $authn->options_to_json( $opts ) ) );
    }

The same with class functions:

    my $handle = $user->{user_handle} || generate_user_handle();
    my $opts = generate_registration_options(
        rp_id                   => $RP{rp_id},
        rp_name                 => $RP{rp_name},
        user_name               => $user->{email},
        user_id                 => $handle,
        user_display_name       => $user->{display_name},
        exclude_credentials     => \@exclude,
        authenticator_selection => {
            resident_key      => 'preferred',
            user_verification => 'preferred',
        },
        attestation => 'none',
        timeout     => 60_000,
    ) || return( $c->status( 500, Web::Authn->error->message ) );
    return( $c->render_json_raw( options_to_json( $opts ) ) );

C<exclude_credentials> stops the same authenticator from being registered twice. C<options_to_json> emits camelCase and base64url — that is the document C<@simplewebauthn/browser> expects as C<optionsJSON>.

=head2 POST /webauthn/register/complete

Body is the JSON produced by C<startRegistration()> (or your own C<navigator.credentials.create> wrapper).

    sub register_complete
    {
        my $c = shift( @_ );
        my $user = $c->current_user or return( $c->status(401) );
        my $body = $c->json;

        my $challenge = delete( $c->session->{webauthn_challenge} );
        delete( $c->session->{webauthn_user_id} );
        $challenge or return( $c->status( 400, 'no challenge in session' ) );

        my $reg = $authn->verify_registration_response(
            credential                => $body,
            expected_challenge        => $challenge,
            require_user_presence     => 1,
            require_user_verification => 0,
        );
        unless( $reg )
        {
            return( $c->status( 400, 'registration failed' ) );
        }

        $db->insert_credential(
            user_id       => $user->{id},
            credential_id => $reg->{credential_id},
            public_key    => $reg->{credential_public_key},
            sign_count    => $reg->{sign_count},
            aaguid        => $reg->{aaguid},
            fmt           => $reg->{fmt},
            device_type   => $reg->{credential_device_type},
            backed_up     => $reg->{credential_backed_up} ? 1 : 0,
        );

        return( $c->render_json({ ok => JSON::PP::true }) );
    }

The same with class functions:

    my $reg = verify_registration_response(
        credential                => $body,
        expected_challenge        => $challenge,
        expected_rp_id            => $RP{rp_id},
        expected_origin           => $RP{origin},
        require_user_presence     => 1,
        require_user_verification => 0,
    ) || return( $c->status( 400, Web::Authn->error->message ) );

Returned fields you should persist are listed in L<Web::Authn/verify_registration_response>.

=head2 POST /webauthn/login/begin

Two shapes.

B<Username first> — the user typed an email, you look them up:

    sub login_begin
    {
        my $c = shift( @_ );
        my $email = $c->json->{email} or
            return( $c->status(400, 'email required') );
        my $user = $db->user_by_email( $email ) or
            return( $c->status( 404, 'unknown user' ) );

        my @allow = map
        {
            { type => 'public-key', id => $_->{credential_id} }
        } $db->credentials_for( $user->{id} );

        @allow or return( $c->status( 400, 'no passkeys on this account' ) );

        my $opts = $authn->generate_authentication_options(
            allow_credentials => \@allow,
            user_verification => 'preferred',
        ) || return( $c->status( 500, $authn->error->message ) );

        $c->session->{webauthn_challenge} = $opts->{challenge};
        $c->session->{webauthn_user_id}   = $user->{id};
        return( $c->render_json_raw( $authn->options_to_json( $opts ) ) );
    }

The same with class functions:

    my $opts = generate_authentication_options(
        rp_id             => $RP{rp_id},
        allow_credentials => \@allow,
        user_verification => 'preferred',
    ) || return( $c->status( 500, Web::Authn->error->message ) );
    return( $c->render_json_raw( options_to_json( $opts ) ) );

B<Usernameless / “Sign in with passkey”> — omit C<allow_credentials> so the authenticator picks a discoverable credential:

    # OO
    my $opts = $authn->generate_authentication_options(
        user_verification => 'preferred',
    ) || return( $c->status( 500, $authn->error->message ) );

    # class function
    my $opts = generate_authentication_options(
        rp_id             => $RP{rp_id},
        user_verification => 'preferred',
    ) || return( $c->status( 500, Web::Authn->error->message ) );

    $c->session->{webauthn_challenge} = $opts->{challenge};
    # no webauthn_user_id — you will find the user after verify

=head2 POST /webauthn/login/complete

    sub login_complete
    {
        my $c = shift( @_ );
        my $body = $c->json;
        my $challenge = delete( $c->session->{webauthn_challenge} );
        $challenge or return( $c->status( 400, 'no challenge in session' ) );

        my $cred_id = $authn->base64url_to_bytes( $body->{id} );
        $cred_id or return( $c->status( 400, 'bad credential id' ) );

        my $row = $db->credential_by_id( $cred_id ) or
            return( $c->status( 400, 'unknown credential' ) );

        my $ok = $authn->verify_authentication_response(
            credential                    => $body,
            expected_challenge            => $challenge,
            credential_public_key         => $row->{public_key},
            credential_current_sign_count => $row->{sign_count},
            require_user_verification     => 0,
        );
        unless( $ok )
        {
            # cloned authenticator, wrong origin, replayed challenge…
            return( $c->status( 401, 'authentication failed' ) );
        }

        $db->update_sign_count( $row->{id}, $ok->{new_sign_count} );
        $c->establish_login( $row->{user_id} );
        return( $c->render_json({ ok => JSON::PP::true }) );
    }

The same with class functions:

    my $cred_id = base64url_to_bytes( $body->{id} ) ||
        return( $c->status( 400, 'bad credential id' ) );
    my $ok = verify_authentication_response(
        credential                    => $body,
        expected_challenge            => $challenge,
        expected_rp_id                => $RP{rp_id},
        expected_origin               => $RP{origin},
        credential_public_key         => $row->{public_key},
        credential_current_sign_count => $row->{sign_count},
        require_user_verification     => 0,
    ) || return( $c->status( 401, Web::Authn->error->message ) );

On usernameless login, C<< $ok->{user_handle} >> (if present) must match C<users.user_handle> for C<< $row->{user_id} >>; treat a mismatch as a hard failure.

=head1 FRONTEND

Binary fields cannot travel in JSON. This module and L<https://simplewebauthn.dev/> use the same convention: unpadded base64url on the wire.

    npm install @simplewebauthn/browser

    import {
        startRegistration,
        startAuthentication,
        browserSupportsWebAuthn,
    } from '@simplewebauthn/browser';

    if( !browserSupportsWebAuthn() )
    {
        throw new Error('WebAuthn not available');
    }

    // Register
    const begin = await fetch('/webauthn/register/begin', {
        method: 'POST',
        credentials: 'same-origin',
    });
    const optionsJSON = await begin.json();
    const attResp = await startRegistration({ optionsJSON });
    await fetch('/webauthn/register/complete', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(attResp),
    });

    // Login (username first: send { email } on begin)
    const lbegin = await fetch('/webauthn/login/begin', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
    });
    const authJSON = await lbegin.json();
    const assertResp = await startAuthentication({ optionsJSON: authJSON });
    await fetch('/webauthn/login/complete', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(assertResp),
    });

If you call C<navigator.credentials.create> yourself you must decode base64url C<challenge>, C<user.id>, and descriptor C<id> to C<Uint8Array> on the way in, and encode C<rawId>, C<clientDataJSON>, C<attestationObject>, C<authenticatorData>, C<signature>, C<userHandle> on the way out.

=head1 DATA-ACCESS SNIPPETS

These match the schema above. Use placeholders; never interpolate binary ids into SQL.

    sub insert_credential
    {
        my( $self, %row ) = @_;
        $self->dbh->do(
            q{INSERT INTO credentials
              (user_id, credential_id, public_key, sign_count,
               aaguid, fmt, device_type, backed_up)
              VALUES (?,?,?,?,?,?,?,?)},
            undef,
            @row{qw(user_id credential_id public_key sign_count
                    aaguid fmt device_type backed_up)},
        );
    }

    sub credential_by_id
    {
        my( $self, $id ) = @_;
        return( $self->dbh->selectrow_hashref(
            q{SELECT * FROM credentials WHERE credential_id = ?},
            undef, $id,
        ) );
    }

    sub update_sign_count
    {
        my( $self, $pk, $count ) = @_;
        $self->dbh->do(
            q{UPDATE credentials SET sign_count = ? WHERE id = ?},
            undef, $count, $pk,
        );
    }

=head1 ERRORS

Object-oriented:

    my $ok = $authn->verify_authentication_response( %arg );
    unless( $ok )
    {
        my $err = $authn->error;
        if( $err->isa( 'Web::Authn::Exception::InvalidAuthentication' ) )
        {
            $log->info( "webauthn: $err" );
            return( 401 );
        }
        die( $err );
    }

    $authn->fatal(1);   # optional: methods die() with the exception

Class functions:

    my $ok = verify_authentication_response( %arg );
    unless( $ok )
    {
        my $err = Web::Authn->error;
        if( $err->isa( 'Web::Authn::Exception::InvalidAuthentication' ) )
        {
            $log->info( "webauthn: $err" );
            return( 401 );
        }
        die( $err );
    }

Show the user a generic “That passkey could not be verified”. Log the exception server-side. Classes are documented in L<Web::Authn::Exception>.

=head1 PRODUCT DETAILS

=head2 Adding a second passkey

Same register pair. C<exclude_credentials> lists every existing C<credential_id> so the platform will not silently replace the first key.

=head2 Removing a passkey

C<DELETE FROM credentials WHERE credential_id = ? AND user_id = ?>.
Require a fresh login or another passkey so an XSS session cannot strip the victim's only key.

=head2 Sign-count drop

If verify fails with a message about the signature counter, treat that credential as B<cloned>. Disable it and ask the user to register a new one from a machine they control.

=head2 Recovery

Passwordless (C<< user_verification => 'required' >>, no password left) needs a recovery path that is not weaker than the passkey: a second passkey on another device, a hardware key, or in-person proof. An email magic link undoes most of the phishing resistance.

=head2 Attestation pinning

Only if you must restrict vendors. Ship the vendor root PEM yourself (Apple WebAuthn Root CA, Yubico, etc.). This distribution does not bundle them.

    # OO
    $authn->verify_registration_response(
        credential         => $body,
        expected_challenge => $challenge,
        pem_root_certs_bytes_by_fmt => {
            apple  => [ $apple_root_pem ],
            packed => [ $yubico_root_pem ],
        },
    ) || return( $c->status( 400, $authn->error->message ) );

    # class function
    verify_registration_response(
        credential         => $body,
        expected_challenge => $challenge,
        expected_rp_id     => $RP{rp_id},
        expected_origin    => $RP{origin},
        pem_root_certs_bytes_by_fmt => {
            apple  => [ $apple_root_pem ],
            packed => [ $yubico_root_pem ],
        },
    ) || return( $c->status( 400, Web::Authn->error->message ) );

=head1 LOCAL TESTING

    # terminal 1
    plackup -l http://localhost:5000 scripts/webauthn.psgi

Point a browser at C<http://localhost:5000>. C<rp_id> must be C<localhost> and C<expected_origin> C<http://localhost:5000>. Chrome and Safari treat that origin as a secure context.

A platform authenticator (Touch ID, Windows Hello) or a cheap FIDO2 key is enough. In Chrome DevTools → Application → Passkeys you can inspect what was created.

=head1 CHECKLIST

=over

=item * C<rp_id> and C<expected_origin> are constants, not client input.

=item * Challenges live in the server session, one-time, short TTL.

=item * C<user.id> is random bytes, stored on C<users.user_handle>.

=item * C<credential_id> and C<public_key> stored as binary.

=item * C<sign_count> updated only after a successful verify.

=item * Register endpoints require an already-identified user.

=item * Rate-limit begin and complete.

=item * HTTPS in production.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Web::Authn>, L<Web::Authn::Exception>,
L<https://www.w3.org/TR/webauthn-3/>,
L<https://simplewebauthn.dev/>,
L<https://github.com/duo-labs/py_webauthn>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
