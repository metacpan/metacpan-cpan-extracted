#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::XML;
use Test::Fatal;
use Test::Deep;
use Test::File;

use Test::Fake::HTTPD 0.06 ();
use Class::Monkey qw( Test::Fake::HTTPD );

use HTTP::Request::Params ();
use Path::Class ();
use File::Temp ();

my $t_lib_dir = Path::Class::Dir->new('t/lib/mock_mirth/');

_monkey_patch_httpd();
my $httpd = _get_httpd();

ok( defined $httpd, 'Got a test HTTP server (HTTPS)' );

my $class = 'WebService::Mirth';
use_ok($class);

my ( $server, $port ) = split /:/, $httpd->host_port;

{
    like(
        exception {
            my $mirth = $class->new(
                server   => $server,
                port     => $port,
                username => 'admin',
                password => 'incorrect',
            );
        },
        qr/failed.*?HTTP.*?500/i,
        'Login (upon construction) with bad credentials causes exception'
    );
}

my $mirth;

is(
    exception {
        $mirth = $class->new(
            server   => $server,
            port     => $port,
            username => 'admin',
            password => 'admin',
        );
    },
    undef,
    'Login (upon construction) with good credentials'
);

{
    my $global_scripts = $mirth->get_global_scripts;

    my $content = $global_scripts->get_content;
    is_xml(
        $content, _get_global_scripts_fixture(),
        "XML received for global scripts is correct"
    );
}

{
    my $code_templates = $mirth->get_code_templates;

    my $content = $code_templates->get_content;
    is_xml(
        $content, _get_code_templates_fixture(),
        "XML received for code templates is correct"
    );
}

{
    my $name = 'quux';
    my $id   = 'dc444818-9b64-42db-9d59-3d478c9ea3ef';

    my $channel = $mirth->get_channel($name);
    ok( defined $channel, 'Got a value for a valid channel' );

    is $channel->name, $name, 'Parsed name is correct';
    is $channel->id,   $id,   'Parsed ID is correct';
    is $channel->enabled, 'true', 'Parsed enabled is correct';

    my $content = $channel->get_content;
    is_xml(
        $content, _get_channel_fixture($name),
        "XML received for $name is correct"
    );
}

{
    my $channels = {
        foobar => 'a25ea24c-d8f4-439a-9063-62f8a2b6a4b1',
        quux   => 'dc444818-9b64-42db-9d59-3d478c9ea3ef',
    };

    cmp_deeply(
        $mirth->channel_list,
        $channels,
        'List of channels is correct'
    );
}

{
    my $export_dir =
        File::Temp->newdir(
            $t_lib_dir->subdir('export.XXXX')->stringify
        );

    {
        $mirth->export_global_scripts({
            to_dir => $export_dir . '',
        });

       file_not_empty_ok(
           "${export_dir}/global_scripts.xml",
           "Global scripts have been exported"
       );

       my $xml_content = _get_global_scripts_exported({
           export_dir => $export_dir . '',
       });

       is_xml(
           $xml_content, _get_global_scripts_fixture(),
           "XML file exported for global scripts is correct"
       );
    }
    {
        $mirth->export_code_templates({
            to_dir => $export_dir . '',
        });

       file_not_empty_ok(
           "${export_dir}/code_templates.xml",
           "Code templates have been exported"
       );

       my $xml_content = _get_code_templates_exported({
           export_dir => $export_dir . '',
       });

       is_xml(
           $xml_content, _get_code_templates_fixture(),
           "XML file exported for code templates is correct"
       );
    }
    {
        $mirth->export_channels({
            to_dir => $export_dir . '',
        });

        foreach my $channel_name ( qw( foobar quux ) ) {
            file_not_empty_ok(
                "${export_dir}/${channel_name}.xml",
                "$channel_name channel has been exported"
            );

            my $xml_content = _get_channel_exported({
                channel    => $channel_name,
                export_dir => $export_dir . '',
            });

            is_xml(
                $xml_content, _get_channel_fixture($channel_name),
                "XML file exported for $channel_name is correct"
            );
        }
    }
}

is( exception { undef $mirth }, undef, 'Logout (upon destruction)' );

sub _get_global_scripts_exported {
    my ($args) = @_;
    my $export_dir = $args->{export_dir};

    $export_dir = Path::Class::Dir->new($export_dir);
    my $global_scripts = $export_dir->file('global_scripts.xml');

    my $global_scripts_xml = $global_scripts->slurp;

    return $global_scripts_xml;
}

sub _get_global_scripts_fixture {
    my $global_scripts = $t_lib_dir->file("global_scripts.xml");

    my $global_scripts_xml = $global_scripts->slurp;

    return $global_scripts_xml;
}

sub _get_code_templates_exported {
    my ($args) = @_;
    my $export_dir = $args->{export_dir};

    $export_dir = Path::Class::Dir->new($export_dir);
    my $code_templates = $export_dir->file('code_templates.xml');

    my $code_templates_xml = $code_templates->slurp;

    return $code_templates_xml;
}

sub _get_code_templates_fixture {
    my $code_templates = $t_lib_dir->file("code_templates.xml");

    my $code_templates_xml = $code_templates->slurp;

    return $code_templates_xml;
}

sub _get_channel_exported {
    my ($args)         = @_;
    my $channel_to_get = $args->{channel};
    my $export_dir     = $args->{export_dir};

    $export_dir = Path::Class::Dir->new($export_dir);
    my $channel = $export_dir->file("${channel_to_get}.xml");

    my $channel_xml = $channel->slurp;

    return $channel_xml;
}

sub _get_channel_fixture {
    my ($channel_to_get) = @_;

    my $channels_dir = $t_lib_dir->subdir('channels');
    my $channel      = $channels_dir->file("${channel_to_get}.xml");

    my $channel_xml = $channel->slurp;

    return $channel_xml;
}

done_testing;

sub _monkey_patch_httpd {
    # XXX Monkey patch for HTTPS certs/ location:
    # mostly copy and paste the original method :-/
    override 'run' => sub {
        my $cert_dir = $t_lib_dir->subdir('certs');

        my %certs_args = (
            SSL_key_file  => $cert_dir->file('server-key.pem')->stringify,
            SSL_cert_file => $cert_dir->file('server-cert.pem')->stringify,
        );

        eval <<'!STUFFY!FUNK!';
    my ($self, $app) = @_;
    
    $self->{server} = Test::TCP->new(
        code => sub {
            my $port = shift;
    
            my $d;
            for (1..10) {
                $d = $self->_daemon_class->new(
                    %certs_args, # XXX Monkey patch
                    LocalAddr => '127.0.0.1',
                    LocalPort => $port,
                    Timeout   => $self->{timeout},
                    Proto     => 'tcp',
                    Listen    => $self->{listen},
                    ($self->_is_win32 ? () : (ReuseAddr => 1)),
                ) and last;
                Time::HiRes::sleep(0.1);
            }
    
            croak("Can't accepted on 127.0.0.1:$port") unless $d;
    
            $d->accept; # wait for port check from parent process
    
            while (my $c = $d->accept) {
                while (my $req = $c->get_request) {
                    my $res = $self->_to_http_res($app->($req));
                    $c->send_response($res);
                }
                $c->close;
                undef $c;
            }
        },
        ($self->{port} ? (port => $self->{port}) : ()),
    );
    
    weaken($self);
    $self;
!STUFFY!FUNK!
    }, qw( Test::Fake::HTTPD );
}

# Mock a Mirth Connect server
sub _get_httpd {
    my $httpd = Test::Fake::HTTPD->new( scheme => 'https' );
    $httpd->run( sub {
        my $params = HTTP::Request::Params->new( { req => $_[0] } )->params;

        my $response;
        if ( $params->{op} eq 'login' ) {
            my ( $username, $password )
                = map { $params->{$_} } qw( username password );

            my $is_auth =
                $username eq 'admin' && $password eq 'admin' ? 1 : 0;

            # TODO Return a cookie

            if ($is_auth) {
                $response = [
                    200,
                    [ 'Content-Type' => 'text/plain' ],
                    [ 'true' ]
                ];
            }
            else {
                $response = [ 500, [], [] ];
            }
        }
        elsif ( $params->{op} eq 'getCodeTemplate' ) {
            my $code_templates_xml = _get_code_templates_fixture();

            $response = [
                200,
                [ 'Content-Type' => 'application/xml' ],
                [ $code_templates_xml ]
            ];
        }
        elsif ( $params->{op} eq 'getGlobalScripts' ) {
            my $global_scripts_xml = _get_global_scripts_fixture();

            $response = [
                200,
                [ 'Content-Type' => 'application/xml' ],
                [ $global_scripts_xml ]
            ];
        }
        elsif ( $params->{op} eq 'getChannel' ) {
            my $foobar_xml = _get_channel_fixture('foobar');
            my $quux_xml   = _get_channel_fixture('quux');

            my $channels_xml = <<"END_XML";
<list>
$foobar_xml
$quux_xml
</list>
END_XML

            $response = [
                200,
                [ 'Content-Type' => 'application/xml' ],
                [ $channels_xml ]
            ];
        }
        elsif ( $params->{op} eq 'logout' ) {
            $response = [ 200, [], [] ];
        }

        return $response;
    });

    return $httpd;
}
