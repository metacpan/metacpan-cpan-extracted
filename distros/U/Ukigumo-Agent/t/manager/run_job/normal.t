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

subtest 'normal case' => sub {
    *Ukigumo::Client::run = sub { sleep 1 };

    subtest 'single child' => sub {
        my $fh;
        ($fh, $tmpfilename) = tempfile();

        my $config = {
            work_dir     => tempdir(CLEANUP => 1),
            server_url   => '127.0.0.1',
            max_children => 1,
        };
        my $manager = Ukigumo::Agent::Manager->new(config => $config);

        $cv = AE::cv;

        $manager->register_job({
            repository => 'repos',
            branch     => 'branch',
        });

        $manager->register_job({
            repository => 'repos',
            branch     => 'branch',
        });

        $cv->wait;

        my $got = do { local $/; <$fh>; };
        like $got, qr/
            \ASpawned\ (\d+)\n
            \[child]\ finished\ to\ work\n
            \[child\ exit]\ pid:\ \1,\ status:\ 0\n
            \[child\ exit]\ run\ new\ job\n
            Spawned\ (\d+)\n
            \[child]\ finished\ to\ work\n
            \[child\ exit]\ pid:\ \2,\ status:\ 0\n
            \[child\ exit]\ There\ is\ no\ jobs\.\ sleep\.\.\.\n\Z
        /x;
        close $fh;
    };

    subtest 'multi children' => sub {
        my $fh;
        ($fh, $tmpfilename) = tempfile();

        my $config = {
            work_dir     => tempdir(CLEANUP => 1),
            server_url   => '127.0.0.1',
            max_children => 2,
        };
        my $manager = Ukigumo::Agent::Manager->new(config => $config);

        $cv = AE::cv;

        $manager->register_job({
            repository => 'repos',
            branch     => 'branch',
        });
        $manager->register_job({
            repository => 'repos',
            branch     => 'branch',
        });
        $manager->register_job({
            repository => 'repos',
            branch     => 'branch',
        });

        $cv->wait;

        $cv = AE::cv;
        Coro::AnyEvent::sleep 2; # XXX buffering
        $cv->send;
        $cv->wait;

        my $got = do { local $/; <$fh>; }; # TODO remove
        like $got, qr/(?:
            Spawned\ (\d+)\n
            Spawned\ (\d+)\n
            \[child]\ finished\ to\ work\n
            \[child]\ finished\ to\ work\n
            \[child\ exit]\ pid:\ (?:\1|\2),\ status:\ 0\n
            \[child\ exit]\ run\ new\ job\n
            Spawned\ (\d+)\n
            \[child\ exit]\ pid:\ (?:\1|\2),\ status:\ 0\n
            \[child\ exit]\ There\ is\ no\ jobs\.\ sleep\.\.\.\n
            \[child]\ finished\ to\ work\n
            \[child\ exit]\ pid:\ \3,\ status:\ 0\n
            \[child\ exit]\ There\ is\ no\ jobs\.\ sleep\.\.\.\n
            |
            Spawned\ (\d+)\n
            Spawned\ (\d+)\n
            \[child]\ finished\ to\ work\n
            \[child\ exit]\ pid:\ (?:\4|\5),\ status:\ 0\n
            \[child\ exit]\ run\ new\ job\n
            Spawned\ (\d+)\n
            \[child]\ finished\ to\ work\n
            \[child\ exit]\ pid:\ (?:\4|\5),\ status:\ 0\n
            \[child\ exit]\ There\ is\ no\ jobs\.\ sleep\.\.\.\n
            \[child]\ finished\ to\ work\n
            \[child\ exit]\ pid:\ \6,\ status:\ 0\n
            \[child\ exit]\ There\ is\ no\ jobs\.\ sleep\.\.\.\n
        )/x;

        close $fh;
        ok 1;
    };
};

done_testing;

