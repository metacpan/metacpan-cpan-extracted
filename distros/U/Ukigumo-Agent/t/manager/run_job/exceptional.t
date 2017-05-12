#!perl

use strict;
use warnings;
no warnings qw/redefine once/;
use utf8;
use AnyEvent;
use Coro::AnyEvent;
use File::Temp qw/tempdir tempfile/;
use Ukigumo::Client;
use Ukigumo::Logger;
use Ukigumo::Agent;

use Test::More;

my $cv;
my $tmpfilename = '';

*Ukigumo::Client::new = sub {
    bless {
        logfh => File::Temp->new(UNLINK => 1)
    }, 'Ukigumo::Client';
};

my $original_agent__take_a_break = *Ukigumo::Agent::Manager::_take_a_break{CODE};
*Ukigumo::Agent::Manager::_take_a_break = sub {
    my ($self) = @_;
    $original_agent__take_a_break->($self);
    Coro::AnyEvent::sleep 1; # to buffer
    $cv->send;
};

*Ukigumo::Logger::infof = sub {
    my ($self, @info) = @_;
    open my $fh, '>>', $tmpfilename;
    print $fh "@info" . "\n";
};

*Ukigumo::Logger::warnf = sub {
    my ($self, @warn) = @_;
    open my $fh, '>>', $tmpfilename;
    print $fh "@warn" . "\n";
};

subtest 'exceptional' => sub {
    my $config = {
        work_dir     => tempdir(CLEANUP => 1),
        server_url   => '127.0.0.1',
    };
    my $manager = Ukigumo::Agent::Manager->new(config => $config);

    subtest 'client died' => sub {
        *Ukigumo::Client::run = sub { die };

        my $fh;
        ($fh, $tmpfilename) = tempfile();

        $cv = AE::cv;

        $manager->register_job({
            repository => 'repos',
            branch     => 'branch',
        });

        $cv->wait;

        my $got = do { local $/; <$fh>; };
        like $got, qr!
            Spawned\ (\d+)\n
            \[child]\ error:\ Died\ at\ t/manager/run_job/exceptional\.t\ line\ \d+\.\n
            \n
            \[child]\ finished\ to\ work\n
            \[child\ exit]\ pid:\ \1,\ status:\ 0\n
            \[child\ exit]\ There\ is\ no\ jobs\.\ sleep\.\.\.\n
        !x;

        close $fh;
    };

    subtest 'lack arguments' => sub {
        eval{ $manager->register_job() };
        ok $@;

        eval{ $manager->register_job({repository => 'repos'}) };
        ok $@;

        eval{ $manager->register_job({branch => 'branch'}) };
        ok $@;
    };
};

done_testing;

