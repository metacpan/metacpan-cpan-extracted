use strict;
package Web::Authenticate;
$Web::Authenticate::VERSION = '0.013';
use Mouse;
use Carp;
use Web::Authenticate::Cookie::Handler;
use Web::Authenticate::RedirectHandler;
use Web::Authenticate::Result::CreateUser;
use Web::Authenticate::Result::Login;
use Web::Authenticate::Result::Authenticate;
use Web::Authenticate::Result::IsAuthenticated;
use Web::Authenticate::Result::CheckForSession;
use Web::Authenticate::RequestUrlProvider::CgiRequestUrlProvider;
use Ref::Util qw/is_arrayref/;
#ABSTRACT: Allows web authentication using cookies and a storage engine. 




has user_storage_handler => (
    does => 'Web::Authenticate::User::Storage::Handler::Role',
    is => 'ro',
    required => 1,
);


has session_handler => (
    does => 'Web::Authenticate::Session::Handler::Role',
    is => 'ro',
    required => 1,
);


has cookie_handler => (
    does => 'Web::Authenticate::Cookie::Handler::Role',
    is => 'ro',
    required => 1,
    default => sub { Web::Authenticate::Cookie::Handler->new },
);


has redirect_handler => (
    does => 'Web::Authenticate::RedirectHandler::Role',
    is => 'ro',
    required => 1,
    default => sub { Web::Authenticate::RedirectHandler->new },
);




has request_url_provider => (
    does => 'Web::Authenticate::RequestUrlProvider::Role',
    is => 'ro',
    required => 1,
    default => sub { Web::Authenticate::RequestUrlProvider::CgiRequestUrlProvider->new },
);


has login_url => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);


has after_login_url => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);


has after_logout_url => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);


has authenticate_fail_url => (
    isa => 'Str|Undef',
    is => 'rw',
);


has update_expires_on_authenticate => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
    default => 1,
);


has allow_after_login_redirect_override => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
    default => 1,
);


has allow_after_login_redirect_time_seconds => (
    isa => 'Int',
    is => 'ro',
    required => 1,
    default => 300,
);


has allow_multiple_sessions_per_user => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
    default => undef,
);

has _after_login_redirect_override_cookie_name => (
    isa => 'Str',
    is => 'ro',
    required => '1',
    default => 'after_login_redirect',
);


sub login {
    my $self = shift;
    my %params = @_;

    croak "must provide login_args and login_args must be arrayref" unless $params{login_args} and is_arrayref($params{login_args});
    _validate_role_arrayref('authenticators', $params{authenticators}, 'Web::Authenticate::Authenticator::Role');
    _validate_role_arrayref('auth_redirects', $params{auth_redirects}, 'Web::Authenticate::Authenticator::Redirect::Role');

    $params{authenticators} ||= [];
    $params{auth_redirects} ||= [];

    my $user = $self->user_storage_handler->load_user(@{$params{login_args}});

    return Web::Authenticate::Result::Login->new(success => undef) unless $user;

    for my $authenticator (@{$params{authenticators}}) {
        return Web::Authenticate::Result::Login->new(success => undef, user => $user, failed_authenticator => $authenticator)
            unless $authenticator->authenticate($user);
    }
    
    $self->session_handler->invalidate_current_session;

    unless ($self->allow_multiple_sessions_per_user) {
        $self->session_handler->invalidate_user_sessions($user);
    }
    $self->session_handler->create_session($user);

    my $redirect_url = $self->after_login_url;
    my $allow_after_login_redirect_override_url;
    my $result_auth_redirect;
    if ($self->allow_after_login_redirect_override) {
        my $override_cookie_name = $self->_after_login_redirect_override_cookie_name;
        $allow_after_login_redirect_override_url = $self->cookie_handler->get_cookie($override_cookie_name);
        $self->cookie_handler->delete_cookie($override_cookie_name);
    } 
    
    if ($allow_after_login_redirect_override_url) {
        $redirect_url = $allow_after_login_redirect_override_url; 
    } else {
        for my $auth_redirect (@{$params{auth_redirects}}) {
            if ($auth_redirect->authenticator->authenticate($user)) {
                $redirect_url = $auth_redirect->url;
                $result_auth_redirect = $auth_redirect;
                last;
            }
        }
    }

    $self->redirect_handler->redirect($redirect_url);

    return Web::Authenticate::Result::Login->new(success => 1, user => $user, auth_redirect => $result_auth_redirect);
}


sub logout {
    my ($self) = @_;

    $self->session_handler->delete_session;
    $self->redirect_handler->redirect($self->after_logout_url);
}


sub authenticate {
    my ($self) = shift;
    my %params = @_;

    _validate_role_arrayref('auth_redirects', $params{auth_redirects}, 'Web::Authenticate::Authenticator::Redirect::Role');

    $params{auth_redirects} ||= [];

    my $is_authenticated = $self->is_authenticated(@_, redirect => 1);

    unless ($is_authenticated->success) {
        if ($is_authenticated->user) {
            return Web::Authenticate::Result::Authenticate->new(success => undef, user => $is_authenticated->user, failed_authenticator => $is_authenticated->failed_authenticator);
        } else {
            return Web::Authenticate::Result::Authenticate->new(success => undef);
        }
    }

    # in this function, unlike in login, if redirect role fails then they're directed there.
    my $user = $is_authenticated->user;
    for my $auth_redirect (@{$params{auth_redirects}}) {
        unless ($auth_redirect->authenticator->authenticate($user)) {
            $self->redirect_handler->redirect($auth_redirect->url);
            return Web::Authenticate::Result::Authenticate->new(success => undef, user => $user, auth_redirect => $auth_redirect);
        }
    }

    $self->session_handler->update_expires if $self->update_expires_on_authenticate;

    return Web::Authenticate::Result::Authenticate->new(success => 1, user => $user);
}


sub is_authenticated {
    my ($self) = shift;
    my %params = @_;

    _validate_role_arrayref('authenticators', $params{authenticators}, 'Web::Authenticate::Authenticator::Role');

    $params{authenticators} ||= [];

    my $session = $self->session_handler->get_session;

    unless ($session) {
        my $allow_after_login_redirect_override =
            exists $params{allow_after_login_redirect_override}
            ? $params{allow_after_login_redirect_override} : $self->allow_after_login_redirect_override;
        if ($allow_after_login_redirect_override) {
            my $url = $self->request_url_provider->url;
            $self->cookie_handler->set_cookie($self->_after_login_redirect_override_cookie_name, $url, $self->allow_after_login_redirect_time_seconds);
        }
        $self->redirect_handler->redirect($self->login_url) if $params{redirect};
        return Web::Authenticate::Result::IsAuthenticated->new(success => undef) unless $session;
    }

    my $user = $session->user;
    unless ($user) {
        $self->redirect_handler->redirect($self->login_url) if $params{redirect};
        return Web::Authenticate::Result::IsAuthenticated->new(success => undef);
    }
    
    for my $authenticator (@{$params{authenticators}}) {
        unless ($authenticator->authenticate($user)) {
            $self->redirect_handler->redirect($self->authenticate_fail_url) if $params{redirect};
            return Web::Authenticate::Result::IsAuthenticated->new(success => undef, user => $user, failed_authenticator => $authenticator);
        }
    }

    return Web::Authenticate::Result::IsAuthenticated->new(success => 1, user => $user);
}


sub check_for_session {
    my $self = shift;
    my %params = @_;

    my $result = $self->is_authenticated(allow_after_login_redirect_override => undef);

    return Web::Authenticate::Result::CheckForSession->new(success => undef) unless $result->success;

    my $user = $result->user;
    my $redirect_url;
    my $result_auth_redirect;
    if ($params{auth_redirects}) {
        for my $auth_redirect (@{$params{auth_redirects}}) {
            if ($auth_redirect->authenticator->authenticate($user)) {
                $redirect_url = $auth_redirect->url;
                $result_auth_redirect = $auth_redirect;
                last;
            }
        }
    }

    unless ($redirect_url) {
        $redirect_url = $self->after_login_url;
    }

    $self->redirect_handler->redirect($redirect_url);
    return Web::Authenticate::Result::CheckForSession->new(success => 1, user => $user, auth_redir => $result_auth_redirect);
}


sub create_user {
    my ($self) = shift;
    my %params = @_;

    my $username = delete $params{username};
    my $password = delete $params{password};
    croak "must provide username" unless $username;
    croak "must provide password" unless $password;

    my $username_verifiers = delete $params{username_verifiers};
    my $password_verifiers = delete $params{password_verifiers};

    _validate_role_arrayref('username_verifiers', $username_verifiers, 'Web::Authenticate::User::CredentialVerifier::Role');
    _validate_role_arrayref('password_verifiers', $password_verifiers, 'Web::Authenticate::User::CredentialVerifier::Role');

    $username_verifiers ||= [];
    $password_verifiers ||= [];

    my @failed_username_verifiers;
    for my $verifier (@$username_verifiers) {
        unless ($verifier->verify($username)) {
            push @failed_username_verifiers, $verifier;
        }
    }

    my @failed_password_verifiers;
    for my $verifier (@$password_verifiers) {
        unless ($verifier->verify($password)) {
            push @failed_password_verifiers, $verifier;
        }
    }

    if (@failed_username_verifiers or @failed_password_verifiers) {
        return Web::Authenticate::Result::CreateUser->new(success => undef, failed_username_verifiers => \@failed_username_verifiers, failed_password_verifiers => \@failed_password_verifiers);  
    }

    my $user = $self->user_storage_handler->store_user($username, $password, $params{user_values});
    return Web::Authenticate::Result::CreateUser->new(success => 1, user => $user);
}

sub _validate_role_arrayref {
    my ($param_name, $arrayref, $role) = @_;
    croak "$param_name must be an arrayref" if $arrayref and not is_arrayref($arrayref);

    for my $item (@$arrayref) {
        croak "all items in $param_name must do $role" unless $item->does($role);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate - Allows web authentication using cookies and a storage engine. 

=head1 VERSION

version 0.013

=head1 SYNOPSIS

    my $dbix_raw = DBIx::Raw->new(dsn => 'dbi:mysql:test:127.0.0.1:3306', user => 'user', password => 'password');
    my $user_storage_handler = Web::Authenticate::User::Storage::Handler::SQL->new(dbix_raw => $dbix_raw);
    my $storage_handler = Web::Authenticate::Session::Storage::Handler::SQL->new(dbix_raw => $dbix_raw, user_storage_handler => $user_storage_handler);
    my $session_handler = Web::Authenticate::Session::Handler->new(session_storage_handler => $storage_handler);
    my $web_authenticate = Web::Authenticate->new(
        user_storage_handler => $user_storage_handler,
        session_handler => $session_handler,
        after_login_url => 'http://www.google.com/account.cgi',
        after_logout_url => 'http://www.google.com/',
        login_url => 'http://www.google.com/login.cgi',
    );  

    # login user
    my $login_result = $web_authenticate->login(login_args => [$username, $password]);

    if ($login_result->success) {
        # success!
    }

    # authenticate a user to be on a page just with their session
    my $authenticate_result = $web_authenticate->authenticate;

    if ($authenticate_result->succes) {
        # success! allowed to access page
    } 

    # authenticate user with authenticators
    my $authenticate_result = $web_authenticate->authenticate(authenticators => $authenticators);

    if ($authenticate_result->succes) {
        # success! allowed to access page
    } 

    
    # create a user
    my $create_user_result = $web_authenticate->create_user(username => $username, password => $password);

    if ($create_user_result->success) {
        print "Created user " . $create_user_result->user->id . "\n";
    }

    # create a user and verify username and password meet requirements
    my $create_user_result = $web_authenticate->create_user(username => $username, password => $password, username_verifiers => $username_verifiers, password_verifiers => $password_verifiers);

    if ($create_user_result->success) {
        print "Created user " . $create_user_result->user->id . "\n";
    } else {
        print "username errors: \n";
        for my $verifier (@{$create_user_result->failed_username_verifiers}) {
            print "\t" . $verifier->error_msg . "\n";
        }

        print "password errors: \n";
        for my $verifier (@{$create_user_result->failed_password_verifiers}) {
            print "\t" . $verifier->error_msg . "\n";
        }
    }

    # create a user with additional values
    my $user_values => {
        age => 22,
        address => '123 Hopper Ln, Austin TX 78705',
    };
    my $create_user_result = $web_authenticate->create_user(username => $username, password => $password, user_values => $user_values);

    if ($create_user_result->success) {
        print "Created user " . $create_user_result->user->id . "\n";
        print "user age " . $create_user_result->user->row->{age} . "\n";
        print "user address " . $create_user_result->user->row->{address} . "\n";
    }

=head1 DESCRIPTION

This modules allows easy management of user authentication via cookies, redirects, a storage engine, a session handler, and cookie handler.
It is flexible so you can rewrite any of those pieces for your applications' needs.

=head1 METHODS

=head2 user_storage_handler

Sets the L<Web::Authenticate::User::Storage::Handler::Role> to be used. This is required with no default.

=head2 session_handler

Sets the L<Web::Authenticate::Session::Handler::Role> to be used. This is required with no default.

=head2 cookie_handler

Sets the object that does L<Web::Authenticate::Cookie::Handler::Role> to be used. The default is the default L<Web::Authenticate::Cookie::Handler>.

=head2 redirect_handler

Sets the object that does L<Web::Authenticate::RedirectHandler::Role> to be used. The default is the default L<Web::Authenticate::RedirectHandler>.

=head2 request_url_provider

Sets the object that does L<Web::Authenticate::RequestUrlProvider::Role> to get the url for the current request
(used to store the current url if L</allow_after_login_redirect_override> is set to true and L</authenticate> fails).
Default is L<Web::Authenticate::RequestUrlProvider::CgiRequestUrlProvider>.

=head2 login_url

Sets the login url that a user will be redirected to if they need to login. This is required with no default.

    my $web_auth = Web::Authenticate->new(login_url => "http://www.google.com/login");

OR

    $web_auth->login_url("http://www.google.com/login");

=head2 after_login_url

The url the user will be redirected to after a successful login.

=head2 after_logout_url

The url the user will be redirected to after a successful logout. This is required with no default.

=head2 authenticate_fail_url

The url the user will be redirected to if they are logged in, but fail to pass all authenticators in the
authenticators arrayref for L</authenticate>.

=head2 update_expires_on_authenticate

If set to true (1), updates the expires time for the session upon successful authentication. Default is true.

=head2 allow_after_login_redirect_override

If a user requests a page that requires authentication and is redirected to login, if allow_after_login_redirect_override is set to true (1), then
the user will be redirected to that url after a successful login. If set to false, then the user will be redirected to L</after_login_url>.

=head2 allow_after_login_redirect_time_seconds

The url of the page the user tried to load is set to a cookie if they are redirected to login from L</authenticate>. This sets the amount of time (in seconds)
for the cookie to be valid. Default is 5 minutes.

=head2 allow_multiple_sessions_per_user

A bool (1 or undef) whether or not to allow multiple sessions per user. If set to true, when L<Web::Authenticate::Session::Handler::Role/invalidate_user_sessions> will
not be called. Default is false.

=head2 login

=over

=item

B<login_args (required)> - the arguments that the L<Web::Authenticate::User::Storage::Handler::Role> requires for 
L<Web::Authenticate::User::Storage::Handler::Role/load_user>.

=item

B<authenticators (optional)> - An arrayref of L<Web::Authenticate::Authenticator::Role>. If any of the authenticators does not
authenticate, then login will fail.

=item

B<auth_redirects (optional)> - An arrayref of L<Web::Authenticate::Authenticator::Redirect::Role>. If the user logins successfully, the user will
be redirected to the L<Web::Authenticate::Authenticator::Redirect::Role/url> of the first L<Web::Authenticate::Authenticator::Redirect::Role/authenticator>
that authenticates. If none of the auth_redirects authenticate, then the user will be redirected to L</after_login_url>.

=back

Verifies the arguments required by L<Web::Authenticate::User::Storage::Handler::Role> in L</user_storage_handler>. If they are correct, if L</allow_after_login_redirect_override>
is set to 1 and the user has a cookie set for this, the user will be redirected to that url. If not, the user is redirected to the 
first the L<Web::Authenticate::Authenticator::Redirect::Role/url> of the first succesful L<Web::Authenticate::Authenticator::Redirect::Role> in auth_redirects. 
If auth_redirects is empty or none authenticate, then the user is redirected to L</after_login_url>
Returns a L<Web::Authenticate::Result::Login> object. 

    my $login_result = $web_auth->login(login_args => [$username, $password]);

    if ($login_result->success) {
        log("user id is " . $login_result->user->id);
        exit; # already set to redirect to appropriate page
    } else {
        # handle login failure
        if ($login_result->authenticator) {
            # this authenticator caused the failure
        }
    }

=head2 logout

Logs a user out of their current session by deleting their session cookie and their storage-backed session.

    $web_authenticate->logout;

=head2 authenticate

=over

=item

B<authenticators (optional)> - An arrayref of L<Web::Authenticate::Authenticator::Role>. If any of the authenticators does not
authenticate, then the user will be redirected to L</authenticate_fail_url>.

=item

B<auth_redirects (optional)> - An arrayref of L<Web::Authenticate::Authenticator::Redirect::Role>. The user will
be redirected to the L<Web::Authenticate::Authenticator::Redirect::Role/url> of the first L<Web::Authenticate::Authenticator::Redirect::Role/authenticator>
that fails to authenticates. If none of the auth_redirects fail to authenticate, then the user will not be redirected.

=back

First makes sure that the user authenticates as being logged in with a session. If the user is not, the user is redirected to L</login_url>.
Then, the method tries to authenticate all authenticators. If any authenticator fails, the user is redirected to L</authenticate_fail_url>.
Then, all auth_redirects are checked. If any auth_redirect fails to authenticate, the user will be redirected to the L<Web::Authenticate::Authenticator::Redirect::Role/url>
for that auth_redirect. auth_redirects are processed in order. This method returns a L<Web::Authenticate::Result::Authenticate> object.

    my $authenticate_result = $web_auth->authenticate;

    # OR
    my $authenticate_result = $web_auth->authenticate(authenticators => $authenticators, auth_redirects => $auth_redirects);

    if ($authenticate_result->success) {
        print "User " . $authenticate_result->user->id . " successfully authenticated\n";
    } else {
        # failed to authenticate user.
        if ($authenticate_result->failed_authenticator) {
            # this authenticator caused the failure
        }
    }

=head2 is_authenticated

=over

=item

B<authenticators (optional)> - An arrayref of L<Web::Authenticate::Authenticator::Role>. If any of the authenticators does not
authenticate, then the user will be redirected to L</authenticate_fail_url>.

=item

B<redirect (optional)> - If set to true, this method will redirect appropriately if the user does not authenticate.

=item

B<allow_after_login_redirect_override (optional)> - Can override L</allow_after_login_redirect_override> for this call. Defaults to L</allow_after_login_redirect_override>.

=back

First makes sure that the user authenticates as being logged in with a session. If the user is not, the user is redirected to L</login_url> if redirect is set to 1.
Then, the method tries to authenticate all authenticators. If any authenticator fails, the user is redirected to L</authenticate_fail_url> if redirect is set to 1.
This method returns a L<Web::Authenticate::Result::IsAuthenticated> object.

    my $is_authenticated_result = $web_auth->is_authenticated;

    # OR
    my $is_authenticated_result = $web_auth->is_authenticated(authenticators => $authenticators);

    if ($is_authenticated_result->success) {
        print "User " . $is_authenticated_result->user->id . " successfully authenticated\n";
    } else {
        # failed to authenticate user.
        if ($is_authenticated_result->failed_authenticator) {
            # this authenticator caused the failure
        }
    }

This method does not update the expires time for the session. It does however respect L</allow_after_login_redirect_override>.

=head2 check_for_session 

=over

=item

B<auth_redirects (optional)> - An arrayref of L<Web::Authenticate::Authenticator::Redirect::Role>. If the user is authenticated successfully with a session, they will 
be redirected to the L<Web::Authenticate::Authenticator::Redirect::Role/url> of the first L<Web::Authenticate::Authenticator::Redirect::Role/authenticator>
that authenticates. If none of the auth_redirects authenticate, then the user will be redirected to L</after_login_url>.

=back

This is meant to be used on the login page if you do not want users to be able to login if they are already authenticated.

    $web_authenticate->check_for_session;

    # or with auth redirects
    $web_authenticate->check_for_session(auth_redirects => $auth_redirects);

Returns L<Web::Authenticate::Result::CheckForSession>.

=head2 create_user

=over

=item

B<username (required)> - The username for the user to create.

=item

B<password (required)> - The password for the user to create.

=item

B<username_verifiers (optional)> - optional arrayref of L<Web::Authenticate::User::CredentialVerifier> to verify if an entered username is correct.

=item

B<password_verifiers (optional)> - optional arrayref of L<Web::Authenticate::User::CredentialVerifier> to verify if an entered password is correct.

=item

B<user_values (optional)> - optional hashref where column names are the keys and the values for those columns are the values. These values will be
passed on to L<Web::Authenticate::User::Storage::Handler::Role> when creating the user.

=back

This is a convenience method that can be used if the L<Web::Authenticate::User::Storage::Handler::Role> you are using accepts its 
L<Web::Authenticate::User::Storage::Handler::Role/store_user> arguments as:

    store_user($username, $password, $user_values)

Such as L<Web::Authenticate::User::Storage::Handler::SQL>.

    my $create_user_result = $web_authenticate->create_user(
        username => $username, 
        password => $password, 
        username_verifiers => $username_verifiers, 
        password_verifiers => $password_verifiers,
        user_values => {
            age => $age,
            insert_time => \'NOW()',
        },
    );

    if ($create_user_result->success) {
        print "User " . $create_user_result->user->id . " created\n";
    } else {
        print "username errors: \n";
        for my $verifier (@{$create_user_result->failed_username_verifiers}) {
            print "\t" . $verifier->error_msg . "\n";
        }

        print "password errors: \n";
        for my $verifier (@{$create_user_result->failed_password_verifiers}) {
            print "\t" . $verifier->error_msg . "\n";
        }
    }

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
