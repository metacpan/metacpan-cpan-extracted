use strict;
use warnings;
use Carp ();
use Path::Class ();
use File::Temp ();
use Test::More;
use Test::Exception;
use LWP::UserAgent;

BEGIN { use_ok 'Test::Groonga' }

my $bin = Test::Groonga::_find_groonga_bin();
my $cmd_version = 1;

subtest 'get test tcp instance as groonga server' => sub {

    plan skip_all => 'groonga binary is not found' unless defined $bin;

    subtest 'gqtp mode' => sub {

        my $server;
        lives_ok { $server = Test::Groonga->create(protocol => 'gqtp', default_command_version => $cmd_version) } "create Test::TCP instance.";

        my $port = $server->port;
        ok $port, "port: $port";

        my $json = `$bin -p $port -c 127.0.0.1 status`;
        ok $json =~ m/^\[\[0/, "groonga server is running in gqtp mode.";

        $server->stop;
    };

    subtest 'http mode' => sub {

        my $server;
        lives_ok { $server = Test::Groonga->create( protocol => 'http', default_command_version=>$cmd_version) } "create Test::TCP instance.";

        my $port = $server->port;
        ok $port, "port: $port";

        my $url = "http://127.0.0.1:$port/d/status";
        my $res = LWP::UserAgent->new()->get($url);
        is $res->code, 200, "groonga server is running in http mode";
        diag "content: " . $res->content;

        $server->stop;
    };
};

subtest 'providing groonga db prepared schema' => sub {

    plan skip_all => 'groonga binary is not found' unless defined $bin;

    my $schema_file = _get_tmp_schema_file();

    subtest 'in gqtp mode' => sub {

        my $server;
        lives_ok {
            $server = Test::Groonga->create( protocol => 'gqtp', 'default_command_version' => $cmd_version, preload => $schema_file->stringify );
        };

        my $port = $server->port;

        my $json = `$bin -p $port -c 127.0.0.1 select --table LocalNames`;
        ok $json =~ m/^\[\[0/, "groonga server is running in gqtp mode.";

        $server->stop;
    };

    subtest 'in http mode' => sub {

        my $server;
        lives_ok {
            $server = Test::Groonga->create( protocol => 'http', 'default_command_version' => $cmd_version, preload => $schema_file->stringify );
        };

        my $port = $server->port;

        my $url = "http://127.0.0.1:$port/d/select?table=LocalNames";
        my $res = LWP::UserAgent->new()->get($url);
        is $res->code, 200, "groonga server is running in http mode";
        diag "content: " . $res->content;
 
        $server->stop;
    };
};

done_testing;

sub _get_tmp_schema_file {
    my ( $fh, $filename ) = File::Temp::tempfile( UNLINK => 1 );
    $fh->close;

    my $schema_file = Path::Class::File->new($filename);
    $schema_file->openw->print(
        do { local $/; <DATA>; }
    );
    
    return $schema_file;
}

__DATA__
table_create LocalNames 48 ShortText
table_create Entries 48 ShortText
column_create Entries local_name 0 LocalNames
column_create LocalNames Entries_local_name 2 Entries local_name

