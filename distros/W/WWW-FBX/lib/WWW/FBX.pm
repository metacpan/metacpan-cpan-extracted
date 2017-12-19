package WWW::FBX;
use Moose;
use Carp::Clan qw/^(?:WWW::FBX|Moose|Class::MOP)/;
use JSON::MaybeXS;
use Scalar::Util qw/reftype/;
use URI::Escape;
use HTTP::Request::Common;
use WWW::FBX::Error;
use Encode qw/encode_utf8/;
use Try::Tiny;
use LWP::UserAgent;

with 'WWW::FBX::Role::API::APIv3';
with 'WWW::FBX::Role::Auth';
 
use namespace::autoclean;

our $VERSION = "0.22";

has base_url    => ( isa => 'Str', is => 'ro', default => 'http://mafreebox.free.fr' );
has lwp_args    => ( isa => 'HashRef', is => 'ro', default => sub { {} } );
has [ qw/app_id app_name app_version device_name/ ] => ( 
    isa => 'Str', is => 'ro', required => 1 );
has ua          => ( isa => 'LWP::UserAgent', is => 'rw', lazy => 1, builder => '_build_ua' );
has uar         => ( isa => 'HashRef', is => 'rw' );
has uarh        => ( isa => 'HTTP::Response', is => 'rw' );
has debug       => ( isa => 'Bool', is => 'rw', default => 0, trigger => \&_set_debug );
has noauth      => ( isa => 'Bool', is => 'ro', default => 0 );

has _json_handler   => (
    is      => 'rw',
    default => sub { JSON->new->allow_nonref },
    handles => { from_json => 'decode' },
);

sub _set_debug {
    my ( $self, $debug, $odebug) = @_ ;
    if ( defined $odebug and $odebug != $debug or $debug ) {
        if ($debug) {
            $self->ua->add_handler("request_send", sub { print ">" x 25, "\n"; shift->dump; return });
            $self->ua->add_handler("response_done", sub { print "<" x 25, "\n"; shift->dump; return });
        } else {
            $self->ua->remove_handler("request_send");
            $self->ua->remove_handler("response_done");
        }
    }
}
 
sub _build_ua {
    my $self = shift;
 
    my $ua = LWP::UserAgent->new(%{$self->lwp_args});
 
    return $ua;
}
 
sub _json_request {
    my ($self, $http_method, $uri, $args, $content_type ) = @_;
 
    my $msg = $self->_prepare_request($http_method, $uri, $args, $content_type);
    my $res = $self->_send_request($msg);

    #Store response content
    $self->uar( $self->_parse_result ($res, $args ) );

    #And HTTP response RAW
    $self->uarh( $res );

    return $self->uar->{result};
}
 
sub _prepare_request {
    my ($self, $http_method, $uri, $args, $content_type ) = @_;
 
    my $msg;
 
    if( $http_method eq 'PUT' ) {
        $msg = PUT( $uri, Content => encode_json  $args  );
    }
    elsif ( $http_method =~ /^(?:GET|DELETE)$/ ) {
        $uri->query($self->_query_string_for($args)) if keys %$args;
        $msg = HTTP::Request->new($http_method, $uri);
    }
    elsif ( $http_method eq 'POST' ) {
        if( !$content_type or $content_type eq 'application/json' ) {
            $msg = POST( $uri,  Content_Type => 'application/json', Content =>  encode_json $args );
        }
        elsif ( $content_type eq "form-data" ) {
            $msg = POST($uri, Content_Type => 'form-data', Content => [ map { ref $_ ? $_ : encode_utf8 $_ } %$args ]);
        }
        else {
            $msg = POST($uri, Content => $args);
        }
    }
    else {
        croak "unexpected HTTP method: $http_method";
    }

    return $msg;
}

sub _query_string_for {
    my ( $self, $args ) = @_;

    my @pairs;
    while ( my ($k, $v) = each %$args ) {
        push @pairs, join '=', $k, $v;
    }

    return join '&', @pairs;
}

sub _send_request { shift->ua->request(shift) }

sub _parse_result {
    my ($self, $res, $args) = @_;

    my $content = $res->content;

    my $j_obj = length $content ? try { $self->from_json($content) } : {};

    #Die if message contains an API error (even on HTTP 200)
    if ( ref $j_obj && reftype $j_obj eq 'HASH' && (exists $j_obj->{error_code} || exists $j_obj->{msg} ) ) {
        die WWW::FBX::Error->new(fbx_error => $j_obj, http_response => $res);
    }

    #If no API error and HTTP is 200 and answer is json
    return $j_obj if $res->is_success && defined $j_obj;

    #API Download file does not return JSON!!
    #If answer is 200 and not json, return unchanged (but still pack it in an HashRef for uar type check..)
    return { result => { filename => $res->filename, content => $content } } if $res->filename and $res->is_success;

    #Else die on HTTP failures, which might contain a json response or not
    my $error = WWW::FBX::Error->new(http_response => $res);
    $error->fbx_error($j_obj) if ref $j_obj;

    die $error;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=for html <a href="https://travis-ci.org/architek/WWW-FBX"><img src="https://travis-ci.org/architek/WWW-FBX.svg?branch=master"></a>

=encoding utf-8

=head1 NAME

WWW::FBX - Freebox v6 OS Perl Interface

=head1 FREEBOX SDK API 3.0

This version provides the API 3.0 support through the APIv3 role but other version can be provided by creating a new role.

=head1 AUTHENTICATION

Authentication is provided through the Auth role but other authentication mechanism can be provided by creating a new role.

=head1 SYNOPSIS

    use WWW::FBX;
    use Scalar::Util 'blessed';

    my $res;
    eval {
        my $fbx = WWW::FBX->new(
            app_id => "APP ID",
            app_name => "APP NAME",
            app_version => "1.0",
            device_name => "MY DEVICE",
            track_id => "48",
            app_token => "2/g43EZYD8AO7tbnwwhmMxMuELtTCyQrV1goMgaepHWGrqWlloWmMRszCuiN2ftp",
            base_url => "http://12.34.56.78:3333",
            debug => 1,
        );
        print "You are now authenticated with track_id ", $fbx->track_id, " and app_token ", $fbx->app_token, "\n";
        print "App permissions are:\n";
        while ( my( $key, $value ) = each %{ $fbx->uar->{result}{permissions} } ) {
            print "\t $key\n" if $value;
        }

        $res = $fbx->connection;
        print "Your ", $res->{media}, " internet connection state is ", $res->{state}, "\n";
        $fbx->set_ftp_config( {enabled => \1} );
        $fbx->reset_freeplug( "F4:CA:E5:DE:AD:BE/reset" );
    };

    if ( my $err = $@ ) {
        die $@ unless blessed $err && $err->isa('WWW::FBX::Error');

        warn "HTTP Response Code: ", $err->code, "\n",
             "HTTP Message......: ", $err->message, "\n",
             "API Error.........: ", $err->error, "\n",
             "Error Code........: ", $err->fbx_error_code, "\n",
    }

=head1 DESCRIPTION

This module provides a perl interface to the L<Freebox|https://en.wikipedia.org/wiki/Freebox#V6_generation.2C_Freebox_Revolution> v6 APIs. 

See L<http://dev.freebox.fr/sdk/os/> for a full description of the APIs.

=head1 METHODS AND ARGUMENTS

 my $fbx = WWW::FBX->new( app_id => "APP ID", app_name => "APP NAME",
                          app_version => "1.0", device_name => "device" );

 my $fbx = WWW::FBX->new( app_id => "APP ID", app_name => "APP NAME",
                          app_version => "1.0", device_name => "device", 
                          track_id => "48", app_token => "2/g43EZYD8AO7tbnwwhmMxMuELtTCyQrV1goMgaepHWGrqWlloWmMRszCuiN2ftp",
                          base_url => "http://12.34.56.78:3333" ,
                          debug => 1 );

Mandatory constructor parameters are app_id, app_name, app_version, device_name. 
When track_id and app_token are also provided, they will be used to authenticate.
Otherwise, new track_id and app_token will be given by the freebox. These can be then used for later access.
base_url defaults to http://mafreebox.free.fr which is the base uri when accessing the freebox from the LAN side.

Note that adding the I<settings> or I<parental> permissions is only possible through the web interface (Paramètres de la Freebox -> Gestion des accès -> Applications)

The constructor takes care of detecting the API version and authentication.


The return value of all api methods is the L<result|http://dev.freebox.fr/sdk/os/#APIResponse.result> structure of APIResponse, or undef if no result is returned.

The full json response of the last request is available through the uar method (usefull when using the I<new> method) and the complete HTTP::Response is available through the uarh method.

Api methods will I<die> if the APIResponse is an error. It is up to the caller to handle this exception.

=head1 QUICK START

The list of currently available services implemented in this module is given in L<WWW::FBX::Role::API::APIv3>.

A script called fbx_test.pl is provided in the script directory.

You should first call it without argument to store a token in app_token on the disk. Once physically authenticated on the freebox itself, the token file will be reused for subsequent call. You can then grant all permissions on the freebox web interface if you will.

Witout parameter, a simple connection check is done, app permissions are shows and status of the internet connection is displayed.

Commands requiring a suffix can be send by adding a simple parameters on the command line. When more parameters are required, it is possible to send a json structure, see EXAMPLES. You need to escape the accolades in that case.

=head1 EXAMPLES

 fbx-test.pl --help
 fbx-test.pl --debug connection
 fbx-test.pl system
 fbx-test.pl call_log
 fbx-test.pl call_log 2053
 fbx-test.pl reboot
 fbx-test.pl reset_freeplug F4:CA:42:22:53:EF/reset
 fbx-test.pl cp '{"files":["Disque dur/ds.txt"], "dst":"Disque dur/Temp", "mode":"both"}'

=head1 LICENSE

Copyright (C) Laurent Kislaire.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Laurent Kislaire E<lt>teebeenator@gmail.comE<gt>

=cut

