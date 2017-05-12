use strict;
use warnings;

package WebPrototypes::ResetPass;
use parent qw(Plack::Component);
use Plack::Request;
use URL::Encode 'url_encode_utf8';
use String::Random 'random_regex';

use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

use 5.0100; 

sub find_user { die 'find_user needs to be implemented in subclass' }

sub update_user{ die 'update_user needs to be implemented in subclass' }

sub wrap_text{
    my( $self, $text ) = @_;
    return "<html><body>$text</body></html>";
}

sub build_reply{
    my( $self, $text ) = @_;
    return [ 200, [ 'Content-Type' => 'text/html' ], [ $self->wrap_text( $text ) ] ];
}

sub call {
    my($self, $env) = @_;
    my $path = $env->{PATH_INFO};

    if( $path eq '/reset' ){
        return $self->_reset( $env );
    }
    return $self->_index( $env );
}

sub _index {
    my ( $self, $env ) = @_;
    my $req = Plack::Request->new( $env );
    if( $req->method eq 'POST' ){
        my $username = $req->param( 'username' );
        my( $user, $email ) = $self->find_user( $username );
        if( !$user ){
            return $self->build_reply( "User not found" );
        }
        else{
            my $pass_token = random_regex( '\w{40}' );
            $self->update_user( $user, { pass_token => $pass_token });
            $self->_send_pass_token( $env, $user, $username, $email, $pass_token );
            return $self->build_reply( "Email sent" );
        }
    }
    return $self->build_reply( <<END );
<form method="POST">
Username or email: <input type="text" name="username">
<input type="submit">
</form>
END

}

sub build_email {
    my( $self, $to, $reset_url ) = @_;
    return Email::Simple->create(
      header => [
        To      => $to,
        From    => 'root@localhost',
        Subject => "Password reset",
      ],
      body => $reset_url,
    );
}

sub send_mail {
    my( $self, $mail ) = @_;
    sendmail( $mail );
}

sub _send_pass_token {
    my( $self, $env, $user, $username, $email, $pass_token ) = @_;
    my $my_server = $env->{HTTP_ORIGIN} //
    ( $env->{'psgi.url_scheme'} // 'http' ) . '://' . 
    ( $env->{HTTP_HOST} // 
        $env->{SERVER_NAME} . 
        ( $env->{SERVER_PORT} && $env->{SERVER_PORT} != 80 ? ':' . $env->{SERVER_PORT} : '' )
    );
    my $reset_url = URI->new( $my_server );
    $reset_url->path( $env->{SCRIPT_NAME} . '/reset' );
    $reset_url->query_form( name => $username, token => $pass_token );
    $self->send_mail( $self->build_email( $email, $reset_url ), $pass_token );
}

sub _reset {
    my ( $self, $env, ) = @_;
    my $req = Plack::Request->new( $env );
    my $name = $req->param( 'name' );
    my $token = $req->param( 'token' );
    my( $user, $email, $pass_token ) = $self->find_user( $name );
    if( !( $user && $pass_token eq $token ) ){
        return $self->build_reply( 'Token invalid' );
    }
    else{
        if( $req->method eq 'POST' ){
            $self->update_user( $user, { pass_token => undef, password => $req->param( 'password' ) } );
            return $self->build_reply( 'Password reset' );
        }
        else{
            my $encoded_name = url_encode_utf8( $name );
            my $encoded_token = url_encode_utf8( $pass_token );
            return $self->build_reply( <<END );
<form method="POST">
New password:<input type="text" name="password">
<input type="submit">
<input type="hidden" name="name" value="$encoded_name">
<input type="hidden" name="pass_token" value="$encoded_token">
</form>
END
        }
    }
}


1;

__END__

# ABSTRACT: (Experimental) Plack application for sending a 'Reset password link' via email

=head1 SYNOPSIS

    # connecting with DBIx::Class
    {
        package My::ResetPass;
        use parent 'WebPrototypes::ResetPass';
        use Plack::Util::Accessor qw( schema );

        sub find_user {
            my( $self, $name ) = @_;
            my $user = $schema->resultset( 'User' )->search({ username =>  $name })->next;
            return $user, $user->email, $user->pass_token if $user;
            return;
        }

        sub update_user {
            my( $self, $user, $attrs ) = @_;
            $user->update( $attrs ); 
        }

    }

    use Plack::Builder;

    my $app = My::ResetPass->new( schema => $schema );

    builder {
        mount "/forgotten_pass" => builder {
            $app->to_app;
        };
    };

=head1 DESCRIPTION

This application implements the common reset forgotten password mechanism
in a storage independent way.  The examples here are with DBIx::Class
but they can be easily ported to other storage layers.

It has two pages.  First page where the user enters his login details and 
if they are correct an email with a link (with a random verification token)
to the password reset page is sent.
Second page - the password reset page - checks the token - and lets the user
to choose a new password.

This application uses the Template Method design pattern.

=head2 PURE VIRTUAL METHODS

These methods need to be overriden in subclass.

=over 4

=item find_user ( name )

Should return a following tuple
    $user, $user_email, $verification_token

The C<$user> is user object or user id - passed to the C<update_user> method

=item update_user ( user, params )

Should update the user object with params. 
It is used for saving the new password and verification token.

=back

=head2 VIRTUAL METHODS

These methods have defaults - but should probably be overriden anyway.

=over 4

=item wrap_text ( text )

Should return the html page containing the passed text fragment.  By default it just adds
the html and body tags.

=item build_reply ( page_body )

Should return the PSGI response data structure.

=item build_email ( to_address, link_to_the_reset_page )

Should create the email containing the link.

=item send_mail ( mail )

Should send the mail (created by build_mail).

=back

=head2 OTHER METHODS

=over 4

=item call ( env )

=back

=head1 SEE ALSO

L<Plack>
L<Plack::Middleware::Auth::Form> 

=cut

