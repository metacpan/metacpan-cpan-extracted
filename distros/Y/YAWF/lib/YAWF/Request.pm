package YAWF::Request;

=pod

=head1 NAME

YAWF::Request - Object for an HTTP request

=head1 SYNOPSIS

  my $request = YAWF->request;

=head1 DESCRIPTION

This module handles the processing of HTTP requests to a YAWF based project.

This module is the main entry point for all requests, it creates a new
(singleton) YAWF parent object.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use CGI ( ':close_upload_files', ':debug','-utf8' );
use CGI::Cookie ();
use File::Spec  ();
use GD::SecurityImage;
use Template ();

use YAWF;

use Class::XSAccessor accessors => {
    yawf         => 'yawf',
    domain       => 'domain',
    uri          => 'uri',
    headers      => 'headers',
    documentroot => 'documentroot',
    module       => 'module',
    method       => 'method',
    handler      => 'handler',
    query        => 'query',
};

our $VERSION = '0.01';

=pod

=head2 new

This is usually done by the HTTP server or the YAWF module for your HTTP server.

=cut

sub new {
    my $class = shift;

    my $self = bless {@_}, $class;

    # Create a YAWF object only if I'm not a ISA class
    $self->{yawf} = YAWF->new( request => $self )
      if ref($self) eq __PACKAGE__;

    # Add some defaults
    $self->{send_header} ||= sub { print $_[0] . ': ' . $_[1] . "\n"; };
    $self->{send_body}   ||= sub { print @_; };

    # Copy all headers to lower case keys
    $self->{headers} ||= {};
    for ( keys( %{ $self->{headers} } ) ) {
        $self->{headers}->{ lc($_) } = $self->{headers}->{$_};
    }

    return $self;
}

=pod

=head2 run

Usually called by the HTTP server's YAWF module, processes the request.

=cut

sub run {
    my $self   = shift;
    my $reply  = $self->yawf->reply;
    my $config = $self->yawf->config;

    # TODO: Maybe move this part to a YAWF::Handler?
    if ( defined( $config->requesthandler ) ) {

   # Create the project request handler and act as a ISA class of it from now on
        eval 'use ' . $config->requesthandler;
        $self = $config->requesthandler->new( %{$self} );
        $self->yawf->request($self);
    }

    # Parse HTTP arguments
    $self->pre_parse if $self->can('pre_parse');
    $self->parse;
    $self->post_parse if $self->can('post_parse');

    # Convert the request to module and method
    $self->pre_route if $self->can('pre_route');
    $self->rewrite if $self->can('rewrite');  # Rewriting may change the request
    $self->route;
    $self->post_route if $self->can('post_route');

    # Do the actual work
    $self->pre_process if $self->can('pre_process');
    $self->process;
    $self->post_process if $self->can('post_process');

    # Redirect to other URL
    if ( defined( $reply->redir ) ) {
        $self->pre_redir if $self->can('pre_redir');
        $self->redir;
        $self->post_redir if $self->can('post_redir');
    }
    elsif ( defined( $reply->{template} ) ) {

        # WORKAROUND for Template::Toolkit - bug:
        # Initilize session here
        $self->yawf->session;

        my @includes;
        if ( ref( $config->template_dir ) eq 'ARRAY' ) {
            push @includes, @{ $config->template_dir };
        }
        else {
            push @includes, $config->template_dir;
        }

        push @includes, File::Spec->catdir( $self->yawf->shared, 'templates' )
          unless $config->no_default_templates;

        $self->pre_template if $self->can('pre_template');

        # TODO: Cache the template object (in the config cache?)
        my $tt = Template->new(
            {
                INCLUDE_PATH => \@includes,
                COMPILE_EXT  => '.ttc',
                PRE_CHOMP    => 2,
                POST_CHOMP   => 2,
                %{ $config->tt_config },
            }
        );
        if ( !defined($tt) ) {
            $self->error(
                'Something bad happend while starting the template system: '
                  . Template->error() );
        }
        elsif (
            !$tt->process( $reply->template, $reply->data, \$reply->{content} )
          )
        {
            $self->error( 'Template processing error for template '
                  . $reply->template . ': '
                  . $tt->error );
        }
        $self->post_template if $self->can('post_template');

    }

    # Ausgabe
    $self->pre_output if $self->can('pre_output');
    $self->output;
    $self->post_output if $self->can('post_output');

    $self->yawf->session->save
      if defined( $self->yawf->{session} )
          and UNIVERSAL::can( $self->yawf->session, 'save' )
    ;    # Don't create a session just for saving

    return $reply->status;
}

sub error {
    my $self = shift;

    if ( ref( $self->{error} ) ) {
        return &{ $self->{error} }(@_);
    }
    else {
        print STDERR scalar( localtime(time) )
          . " ERROR "
          . join( ' ', @_ ) . "\n";
        return 1;
    }
}

sub parse {
    my $self = shift;

    # Parse everything and prepare Basics
    $self->{CGI} ||= CGI->new;
    $self->{query} = scalar( $self->{CGI}->Vars );
    $self->{cookies} =
      { map { $_, $self->{CGI}->cookie($_); } ( $self->{CGI}->cookie() ) };

    return 1;
}

sub route {
    my $self   = shift;
    my $config = $self->yawf->config;

    # Use a default YAWF::Handler namespace for security reasons if notfound
    # project namespace was defined:
    my $handlerprefix = $config->handlerprefix || 'YAWF::Handler';

    my $uri = $self->uri;

    # Do some default rewriting
    $uri =~ s/\.html?$//;
    $uri =~ s/\/$//;

    $handlerprefix = 'YAWF::Setup'
      if $config->setup_enabled and ( $uri =~ s/^\/?yawf_setup// );

    if ( $uri =~ /^\/capcha\/(\w+)\/(\d+)\/(\d+)\/\d+$/ ) {
        $self->{query}->{SID} = $1;
        my $gdsi = GD::SecurityImage->new(
            width   => $2,
            height  => $3,
            gd_font => 'giant',
            font    => $config->capcha->{ttf},
            lines   => 10 + int( rand(30) ),
            bgcolor => '#'
              . join(
                '',
                unpack(
                    "H*",
                    chr( 180 + int( rand(76) ) )
                      . chr( 180 + int( rand(76) ) )
                      . chr( 180 + int( rand(76) ) )
                )
              ),
            scramble => 1,
        );
        $gdsi->random( $self->yawf->session->{capcha} || '------' );
        $gdsi->create(
            (
                (
                    defined( $config->capcha->{ttf} )
                      and -e $config->capcha->{ttf}
                ) ? 'ttf' : 'normal'
            ),
            'default',
            '#'
              . join(
                '',
                unpack(
                    "H*",
                    chr( int( rand(76) ) )
                      . chr( int( rand(76) ) )
                      . chr( int( rand(76) ) )
                )
              ),
            '#'
              . join(
                '',
                unpack(
                    "H*",
                    chr( 100 + int( rand(76) ) )
                      . chr( 100 + int( rand(76) ) )
                      . chr( 100 + int( rand(76) ) )
                )
              )
        );
        $gdsi->particle( 3 * ( $2 + $3 ) );
        my ( $image, $mime ) = $gdsi->out;
        $self->yawf->reply->status(200);
        $self->yawf->reply->headers->{'Content-type'} = $mime;
        $self->yawf->reply->content($image);
    }
    elsif ( $uri =~ /^\/?([\w\.]+)$/ ) {
        my @Parts = split( /\./, $1 );

        if ( $#Parts > 0 ) {
            $self->{method} = pop(@Parts);
        }
        else {
            $self->{method} = 'index';
        }
        $self->{module} =
          join( '::', $handlerprefix, map { ucfirst($_); } (@Parts) );

    }
    elsif ( $uri =~ /^\/?$/ ) {
        $self->{module} = $handlerprefix;
        $self->{method} = 'index';
    }
    else {
        $self->yawf->reply->status(400);
    }

    return 1;
}

# Call the request handler
sub process {
    my $self = shift;

    if ( defined( $self->{module} ) ) {
        eval 'use ' . $self->{module} . ';';
        if ($@) {
            $self->error( "$@ while loading " . $self->{module} );
            $self->yawf->reply->status(500);
        }
        else {
            $self->{handler} =
              $self->{module}
              ->new( yawf => $self->yawf, %{ $self->{handler_args} || {} } );
            if ( !defined( $self->{handler} ) ) {
                $self->error( 'Error creating handler ' . $self->{module} );
                $self->yawf->reply->status(500);
            }
            elsif (( !defined( $self->{handler}->{WEB_METHODS} ) )
                or ( !$self->{handler}->{WEB_METHODS}->{ $self->{method} } ) )
            {
                $self->error( 'Method '
                      . $self->{module} . '::'
                      . $self->{method}
                      . ' not found' );
                $self->yawf->reply->status(404);
            }
            elsif ( !$self->{module}->can( $self->{method} ) ) {
                $self->error( 'Internal error - method '
                      . $self->{method}
                      . ' was declared but not found in '
                      . $self->{handler} );
                $self->yawf->reply->status(500);
            }
            else {
                if ( $self->{handler}->{LOGIN} ) {
                    $self->pre_logincheck if $self->can( 'pre_logincheck' );
                    $self->yawf->reply->{redir} = '/login?'
                      unless $self->yawf->session->{loggedin};
                    $self->post_logincheck if $self->can( 'post_logincheck' );
                    return 1 unless $self->yawf->session->{loggedin};
                }

                $self->pre_handler if $self->can( 'pre_handler' );
                my $method = $self->{method};
                $self->{handler_result} = $self->{handler}->$method;
                $self->post_handler if $self->can( 'post_handler' );

                return $self->{handler_result};
            }
        }
    }

    return 1;
}

sub redir {
    my $self  = shift;
    my $reply = $self->yawf->reply;

    $reply->headers->{Location} = $reply->redir;
    $reply->status(302);

    return 1;
}

sub output {
    my $self  = shift;
    my $reply = $self->yawf->reply;

    $reply->headers->{'Content-length'} ||= length( $reply->content )
      if defined( $reply->content );

    $self->{send_status}( $reply->headers->{Status} || 200 );

    for my $key ( keys( %{ $reply->headers } ) ) {
        next if $key eq 'Status';
        if ( ref( $reply->headers->{$key} ) eq 'ARRAY' ) {
            for my $value ( @{ $reply->headers->{$key} } ) {
                &{ $self->{send_header} }( $key, $value );
            }
        }
        else {
            &{ $self->{send_header} }( $key, $reply->headers->{$key} );
        }
    }

    # Maybe use $r->sendfile as alternate?
    if ( ( !defined( $reply->content ) ) and defined( $reply->content_fh ) ) {
        my $fh        = $reply->content_fh;
        my $blocksize = 131072;
        while ( defined($fh) ) {
            my $buffer;
            my $read_bytes = sysread( $fh, $buffer, $blocksize );
            &{ $self->{send_body} }($buffer);
            last if $read_bytes < $blocksize;
        }
        close $fh;
    }
    elsif ( defined( $reply->content ) ) {
        &{ $self->{send_body} }( $reply->content );
    }

}

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2010 Sebastian Willing.

=cut
