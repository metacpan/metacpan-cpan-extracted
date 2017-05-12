package WWW::Mechanize::CGI;

use strict;
use warnings;
use base 'WWW::Mechanize';

use Carp;
use File::Spec;
use HTTP::Request;
use HTTP::Request::AsCGI;
use HTTP::Response;
use IO::Pipe;

our $VERSION = 0.3;

sub cgi {
    my $self = shift;

    if ( @_ ) {
        $self->{cgi} = shift;
    }

    return $self->{cgi};
}

sub cgi_application {
    my ( $self, $application ) = @_;

    unless ( File::Spec->file_name_is_absolute($application) ) {
        $application = File::Spec->rel2abs($application);
    }

    $self->env( SCRIPT_FILENAME => $application, $self->env );

    unless ( -e $application ) {
        croak( qq/Path to application '$application' does not exist./ );
    }

    unless ( -f _ ) {
        croak( qq/Path to application '$application' is not a file./ );
    }

    unless ( -x _ ) {
        croak( qq/Application '$application' is not executable./ );
    }

    my $cgi = sub {

        my $status = system($application);
        my $value  = $status >> 8;

        if ( $status == -1 ) {
            croak( qq/Failed to execute application '$application'. Reason: '$!'/ );
        }

        if ( $value > 0 ) {
            croak( qq/Application '$application' exited with value: $value/ );
        }
    };

    $self->cgi($cgi);
}

sub fork {
    my $self = shift;

    if ( @_ ) {
        $self->{fork} = shift;
    }

    return $self->{fork};
}

sub env {
    my $self = shift;

    if ( @_ ) {
        $self->{env} = { @_ };
    }

    return %{ $self->{env} || {} };
}

sub _make_request {
    my ( $self, $request ) = @_;

    if ( $self->cookie_jar ) {
        $self->cookie_jar->add_cookie_header($request);
    }

    my $c = HTTP::Request::AsCGI->new( $request, $self->env );

    my ( $error, $kid, $pipe, $response );

    if ( $self->fork ) {

        $pipe = IO::Pipe->new;
        $kid  = CORE::fork();

        unless ( defined $kid ) {
            croak("Can't fork() kid: $!");
        }
    }

    unless ( $kid ) {

        $c->setup;

        eval { $self->cgi->() };

        $c->restore;

        if ( $self->fork ) {

            $pipe->writer;
            $pipe->write($@) if $@;

            exit(1) if $@;
            exit(0);
        }
    }

    $error = $@;

    if ( $self->fork ) {

        waitpid( $kid, 0 );

        $pipe->reader;
        $pipe->read( $error, 4096 ) if ( $? >> 8 ) > 0;
    }

    if ( $error ) {
        $response = HTTP::Response->new( 500, 'Internal Server Error' );
        $response->date( time() );
        $response->header( 'X-Error' => $error );
        $response->content( $response->error_as_HTML );
        $response->content_type('text/html');
    }
    else {
        $response = $c->response;
    }

    $response->header( 'Content-Base' => $request->uri );
    $response->request($request);

    if ( $self->cookie_jar ) {
        $self->cookie_jar->extract_cookies($response);
    }

    return $response;
}

1;

__END__

=head1 NAME

WWW::Mechanize::CGI - Use WWW::Mechanize with CGI applications.

=head1 SYNOPSIS

    use CGI;
    use WWW::Mechanize::CGI;
    
    # Using a external CGI application
    
    $mech = WWW::Mechanize::CGI->new;
    $mech->cgi_application('/path/to/cgi/executable.cgi');
    
    $response = $mech->get('http://localhost/');
    
    
    # Using a inline CGI callback
    
    $mech = WWW::Mechanize::CGI->new;
    $mech->cgi( sub {
        
        my $q = CGI->new;
        
        print $q->header,
              $q->start_html('Hello World'),
              $q->h1('Hello World'),
              $q->end_html;
    });
    
    $response = $mech->get('http://localhost/');

=head1 DESCRIPTION

Provides a convenient way of using CGI applications with L<WWW::Mechanize>.

=head1 METHODS

=over 4 

=item new

Behaves like, and calls, L<WWW::Mechanize>'s C<new> method. Any parms
passed in get passed to WWW::Mechanize's constructor.

=item cgi

Coderef to be used to execute the CGI application.

=item cgi_application('/path/to/cgi/executable.cgi')

Path to CGI executable.

=item env( [, key => value ] )

Set/Get additional environment variables to be used in CGI. Takes a hash and 
returns a hash.

    $mech->env( DOCUMENT_ROOT => '/export/www/myapp' );

=item fork

Set to a true value if you want to fork() before executing CGI.

=back

=head1 SEE ALSO

=over 4

=item L<Test::WWW::Mechanize::CGI>

=item L<WWW::Mechanize>

=item L<LWP::UserAgent>

=item L<HTTP::Request::AsCGI>

=back

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut
