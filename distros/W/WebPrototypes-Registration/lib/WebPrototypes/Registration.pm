use strict;
use warnings;

use 5.0100;

package WebPrototypes::Registration;
BEGIN {
  $WebPrototypes::Registration::VERSION = '0.002';
}
use parent qw(Plack::Component);
use Plack::Request;
use URL::Encode 'url_encode_utf8';
use String::Random 'random_regex';
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use Email::Valid;

use Plack::Util::Accessor qw( email_validator );

sub prepare_app {
    my $self = shift;
    $self->email_validator( Email::Valid->new() ) if !defined $self->email_validator;
}

sub find_user { die 'find_user needs to be implemented in subclass' }

sub create_user { die 'find_user needs to be implemented in subclass' }

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
    my $req = Plack::Request->new( $env );
    my $uerror = '';
    my $eerror = '';
    my $username = '';
    my $email = '';
    if( $req->method eq 'POST' ){
        $username = $req->param( 'username' );
        $email = $req->param( 'email' );
        if( $self->find_user( $username ) ){
            $uerror = '<span class="error">This username is already registered</span>';
        }
        if( !$self->email_validator->address( $email ) ){
            $eerror = '<span class="error">Wrong format of email</span>';
        }
        if( !$uerror && !$eerror ){
            my $pass_token = random_regex( '\w{40}' );
            my $user = $self->create_user( username => $username, email => $email, pass_token => $pass_token );
            $self->_send_pass_token( $env, $user, $username, $email, $pass_token );
            return $self->build_reply( "Email sent" );
        }
    }
    my $encoded_username = url_encode_utf8( $username );
    my $encoded_email = url_encode_utf8( $email );
    return $self->build_reply( <<END );
<form method="POST">
Username: <input type="text" name="username" value="$encoded_username"> $uerror
Email: <input type="text" name="email" value="$encoded_email"> $eerror
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
    $reset_url->path( "/ResetPass/reset/$username/$pass_token" );
    $self->send_mail( $self->build_email( $email, $reset_url ) );
}


1;



=pod

=head1 NAME

WebPrototypes::Registration - (Experimental) Plack application for registering a new user

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # connecting with DBIx::Class
    {
        package My::Register;
        use parent 'WebPrototypes::Registration';
        use Plack::Util::Accessor qw( schema );

        sub find_user {
            my( $self, $name ) = @_;
            return $self->schema->resultset( 'User' )->search({ username =>  $name })->next;
        }

        sub create_user {
            my( $self, %fields ) = @_;
            return $self->schema->resultset( 'User' )->create({ %fields });
        }
    }

    use Plack::Builder;

    my $app = My::Register->new( schema => $schema );

    builder {
        mount "/register" => builder {
            $app->to_app;
        };
    };

=head1 DESCRIPTION

This application implements a user registration mechanism.  After the registration
and email address verification letter is sent.

The examples here are with DBIx::Class
but they can be easily ported to other storage layers.

This application uses the Template Method design pattern.

=head2 PURE VIRTUAL METHODS

These methods need to be overriden in subclass.

=over 4

=item find_user ( name )

Should return a true value if the name is already registered

=item create_user ( attributes )

Should create the user object. 

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

=head1 AUTHOR

Zbigniew Lukasiak <zby@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Zbigniew Lukasiak <zby@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

# ABSTRACT: (Experimental) Plack application for registering a new user

THIS IS VERY EXPERIMENTAL NOW


