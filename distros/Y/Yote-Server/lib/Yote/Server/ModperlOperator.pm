package Yote::Server::ModperlOperator;

use strict;
no strict 'refs';

use Apache2::Cookie;
use Apache2::Const qw(:common);

use Data::Dumper;
use Text::Xslate qw(mark_raw);
use Encode;
use HTML::Entities;
use JSON;
use URI::Escape;

use Yote::Server;

sub new {
    my( $pkg, %options ) = @_;

    #
    # Setup the yote part of this
    #
    my $yote_root_dir = '/opt/yote';
    eval {
        require Yote::Server::ConfigData;
        $yote_root_dir = Yote::Server::ConfigData->config( 'yote_root' );
    };
    unshift @INC, "$yote_root_dir/lib";
    my $yote_options = Yote::Server::load_options( $yote_root_dir );
    my $server  = new Yote::Server( $yote_options );
    my $store   = $server->store;
    my $root    = $store->fetch_server_root;


    bless {
        apps          => $options{apps}, # hash of app -> app info
        template_path => $options{template_path},
        root          => $root,
        server        => $server,
        tx            => new Text::Xslate(
            function => {
                html_encode => sub {
                    # have to convert the text from perl interlal to octets
                    my $txt = shift;
                    if( length($txt) != length( Encode::decode('utf8', $txt ) ) ) {
                        $txt = Encode::decode( 'utf8', $txt );
                    }
                    mark_raw( encode_entities($txt));
                },
            }
            ),
    }, $pkg;

} #new

sub handle_request {
    my( $self, $req ) = @_;

    my $ruri = $req->uri;
    $ruri =~ s!^/!!;
    my( $app_path, @path  ) = split '/', $ruri;

    my $jar = Apache2::Cookie::Jar->new($req);
    my $token_cookie = $jar->cookies("yoken");
    my $root = $self->{root};
    my $appinfo = $self->{apps}{$app_path};

    my( $app, $login, $session );
    $session = $root ? $root->fetch_session( $token_cookie ? $token_cookie->value : 0 ) : undef;
    unless( $token_cookie && $token_cookie->value eq $session->get__token ) {
        my $cookie_path = "/$appinfo->{cookie_path}";
        $token_cookie = Apache2::Cookie->new( $req,
                                              -name => "yoken",
                                              -expires => '+1D',
                                              -path => $cookie_path,
                                              -value => $session->get__token );
       $token_cookie->bake( $req );
    }
    my $template = $appinfo->{main_template} || 'main';
    if( $appinfo && $root ) {
        $root->{SESSION} = $session;
        ( $app, $login ) = $root->fetch_app( $appinfo->{app_name} );
        $app->{SESSION}  = $session;
        if( $login ) {
            $login->{SESSION} = $session;
        }
        $template = "$app_path/$template";
    }

    #
    # assume the path is split into key/val pairs.
    # this is presumptuous, but some things might use it
    # maybe shouldn't include this?
    #
    my( $path_args );
    my $path = [ @path ];
    while( @path ) {
        my $k = shift @path;
        my $v = shift @path;
        $path_args->{$k} = $v;
    }

    my $state_manager_class = $appinfo->{state_manager_class} || 'Yote::Server::ModperlOperatorStateManager';
    my $state_manager = "$state_manager_class"->new( {
        app_info  => $appinfo,
        app_path  => $app_path,
        path_args => $path_args,
        app       => $app,
        login     => $login,
        op        => $self,       #this operator
        req       => $req,
        session   => $session,
        path      => $path,
        template  => $template,
        uri       => $ruri,
    } );

    my $res;
    eval {
        $state_manager->_check_actions();
        $res = $self->make_page( $state_manager );
        $root->{STORE}->stow_all;
    };
    if( $@ ) {
        print STDERR Data::Dumper->Dump([$@,"ERRY"]);
    }
    return $res;

} #handle_request

sub handle_json_request {
    my( $self, $req ) = @_;

    my $json_payload = uri_unescape(scalar($req->param('p')));

    my $in_json = decode_json( $json_payload );

    my( $out_json, @uploads );

    #
    # scan the payload for files
    #
    my $filecount = $req->param('f');
    for (0..($filecount-1)) {
        my $f = $req->upload( "f$_" );
        push @uploads, $f;
    }
    eval {
        $out_json = $self->{server}->invoke_payload( $json_payload, \@uploads );
    };
    if( $@ ) {
        my $err = ref $@ ? $@ : { err => "INTERNAL ERROR" };
        $out_json = to_json( $err );
    }
    $req->content_type('text/json; charset=utf-8');
    $out_json = Encode::decode('utf8',$out_json);
    $req->print( mark_raw($out_json) );
    return OK;
} #handle_json_request


sub tmpl {
    my( $self, @path ) = @_;
    join( '/', $self->{template_path}, @path ).'.tx';
}

sub make_page {
    my( $self, $state_manager ) = @_;

    my $req = $state_manager->{req};
    if( $state_manager->{redirect} ) {
        $req->headers_out->set(Location => $state_manager->{redirect});
        return REDIRECT;
    }
    $req->content_type('text/html');
    my $template = $state_manager->template;

    my $html = $self->{tx}->render( $self->tmpl( $template ), {%$state_manager} );

    $req->print( mark_raw($html) );

    return OK;
} #make_page

package Yote::Server::ModperlOperatorStateManager;

sub new {
    my( $pkg, $args ) = @_;
    my $self = {%$args};
    bless $self, $pkg;
}

#
# Can be overridden. Template to render this request.
#
sub template {
    shift->{template};
}

sub logout {
    my( $self ) = @_;

    my $req = $self->{req};
    my $app = $self->{app};
    if( $app ) {
        $app->logout();
    }
    my $appinfo = $self->{app_info};
    my $cookie_path = "/$appinfo->{cookie_path}";
    my $token_cookie = Apache2::Cookie->new( $req,
                                             -name => "yoken",
                                             -path => $cookie_path,
                                             -value => 0 );
    $token_cookie->bake( $req );
}

#
# Render a template with the given path (list)
#
sub tmpl {
    my( $self, @path ) = @_;
    $self->{op}->tmpl( $self->{app_info}{template_path}, @path);
}

sub upload {
    my( $self, $name ) = @_;

    my $upload = $self->{req}->upload( $name );
    
    if( $upload ) {
        my $fn = $upload->filename;
        my( $original_name, $extension )  = ( $fn =~ m!([^/]+\.([^/\.]+))$! );

        my $tmprand = "/tmp/".UUID::Tiny::create_uuid_as_string();
        $upload->link( $tmprand );

        my $img = $self->{session}->{STORE}->newobj( {
            file_name      => $original_name,
            file_extension => $extension,
            file_path      => $tmprand,
                                          } );
        return $img;
    }
} #upload

sub _check_actions {
    my( $self );
    # login check, et al go here
}

1;

__END__

=head1 NAME

Yote::Server::ModperlOperator - marry the yote server to xslate templates



=cut
