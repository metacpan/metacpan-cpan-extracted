package t::Util;
use strict;
use warnings;
use utf8;
use Plack::Loader;
use File::Temp qw(tempdir);
use Test::TCP;

sub build_ukigumo_agent {
    my (@opt) = @_;

    my $server = Test::TCP->new(
        code => sub {
            my ($port) = @_;
            my $app = sub {
                [200, [], ['OK']];
            };
            my $loader = Plack::Loader->auto(
                port => $port,
            );
            $loader->run($app);
        },
    );

    Test::TCP->new(
        code => sub {
            my ($port) = @_;
            my $work_dir = tempdir();
            @ARGV = ('--host=127.0.0.1', "--port=$port", "--work_dir=$work_dir", "--server_url=http://127.0.0.1:@{[ $server->port ]}/", "@opt");
            do 'script/ukigumo-agent';
            exit 0;
        },
    );
}

1;

