#!perl

use strict;
use warnings;
no warnings qw/redefine once/;
use utf8;
use AnyEvent;
use Coro::AnyEvent;
use File::Temp qw/tempdir tempfile/;
use Ukigumo::Client;
use Ukigumo::Client::VC::Callback;
use Ukigumo::Logger;
use Ukigumo::Agent;

use Test::More;

my $cv;
my $tmpfilename = '';

*Ukigumo::Client::new = sub {
    bless {
        logfh => File::Temp->new(UNLINK => 1),
        notifiers => +[],
        vc => Ukigumo::Client::VC::Callback->new(
            update_cb  => sub { },
            branch     => 'master',
            repository => 'git:...',
        ),
    }, 'Ukigumo::Client';
};

*Ukigumo::Client::send_to_server = sub {};

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

subtest 'timeout' => sub {
    my $fh;
    ($fh, $tmpfilename) = tempfile();

    *Ukigumo::Client::run = sub { sleep 10 };

    my $config = {
        work_dir     => tempdir(CLEANUP => 1),
        server_url   => '127.0.0.1',
        max_children => 1,
        timeout      => 1,
    };
    my $manager = Ukigumo::Agent::Manager->new(config => $config);

    $cv = AE::cv;

    $manager->register_job({
        repository => 'repos',
        branch     => 'branch',
    });

    *Ukigumo::Client::run = sub {}; # Do nothing

    $manager->register_job({
        repository => 'repos',
        branch     => 'branch',
    });

    $cv->wait;

    my $got = do { local $/; <$fh>; };

    like $got, qr/
        \ASpawned\ (\d+)\n
        \[child]\ timeout\n
        sending\ notification:\ master,\ 6\n
        \[child\ exit]\ pid:\ \1,\ status:\ 15\n
        \[child\ exit]\ run\ new\ job\n
        (?:Spawned\ (\d+)\n|\[child]\ finished\ to\ work\n)
        (?:Spawned\ (\d+)\n|\[child]\ finished\ to\ work\n)
        \[child\ exit]\ pid:\ \2,\ status:\ 0\n
        \[child\ exit]\ There\ is\ no\ jobs\.\ sleep\.\.\.\n\Z
    /x;
};

done_testing;

