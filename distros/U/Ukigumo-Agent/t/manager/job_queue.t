use strict;
use warnings;
no warnings qw/redefine/;
use utf8;
use File::Temp qw/tempdir/;
use Ukigumo::Agent::Manager;

use Test::More;

subtest 'register_job' => sub {
    *Ukigumo::Agent::Manager::run_job = sub {
        my ($self, $param) = @_;
        $self->{children}->{$param} = 'DUMMY';
        return 'running';
    };

    my $original_push_job = *Ukigumo::Agent::Manager::push_job{CODE};
    *Ukigumo::Agent::Manager::push_job = sub {
        my ($self, $param) = @_;
        $original_push_job->($self, $param);
        return 'pushed';
    };

    subtest 'single child' => sub {
        my $config = {
            work_dir     => tempdir(CLEANUP => 1),
            server_url   => '127.0.0.1',
            max_children => 1,
        };
        my $manager = Ukigumo::Agent::Manager->new(config => $config);

        is $manager->register_job('foo'), 'running';
        is $manager->register_job('bar'), 'pushed';
        is $manager->register_job('buz'), 'pushed';
        is_deeply $manager->{job_queue}, ['bar', 'buz'];

    };

    subtest 'single child without config' => sub {
        my $manager = Ukigumo::Agent::Manager->new(
            work_dir     => tempdir(CLEANUP => 1),
            server_url   => '127.0.0.1',
            max_children => 1,
        );

        is $manager->register_job('foo'), 'running';
        is $manager->register_job('bar'), 'pushed';
        is $manager->register_job('buz'), 'pushed';
        is_deeply $manager->{job_queue}, ['bar', 'buz'];

    };

    subtest 'multi children' => sub {
        my $config = {
            work_dir     => tempdir(CLEANUP => 1),
            server_url   => '127.0.0.1',
            max_children => 3,
        };
        my $manager = Ukigumo::Agent::Manager->new(config => $config);

        is $manager->register_job('foo'), 'running';
        is $manager->register_job('bar'), 'running';
        is $manager->register_job('buz'), 'running';
        is $manager->register_job('qux'), 'pushed';
        is_deeply $manager->{job_queue}, ['qux'];
    };
};

done_testing;

