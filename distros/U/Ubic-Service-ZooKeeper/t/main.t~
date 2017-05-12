#!/usr/bin/perl

use strict;
use warnings;

use parent qw(Test::Class);

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Perl6::Slurp qw(slurp);

use Test::More;
use Test::TCP;

use Ubic::Service::ZooKeeper;

# TODO: status checking tests

sub startup : Test(startup) {
    my $self = shift;
    $self->{tempdir} = tempdir(CLEANUP => 1);
}

sub _isa_ok : Test {
    my $s = Ubic::Service::ZooKeeper->new;
    isa_ok($s, 'Ubic::Service::ZooKeeper');
}

sub myid_file : Test {
    my $self = shift;

    my $s = Ubic::Service::ZooKeeper->new({
        dataDir => $self->{tempdir},
        myid    => 3,
    });

    $s->create_myid_file;

    my $content = slurp(catfile($self->{tempdir}, "myid"));
    is($content, "3\n", 'check myid file content');
}

sub cfg_file : Test {
    my $self = shift;

    my $cfg_params = {
        clientPort => 2181,
        dataDir => '/data',
        tickTime => 1000,
        dataLogDir => '/datalog',
        globalOutstandingLimit => 10,
        preAllocSize => 15,
        snapCount => 20,
        traceFile => '/trace/file',
        maxClientCnxns => 100,
        clientPortAddress => 4321,
        minSessionTimeout => 1000,
        maxSessionTimeout => 5000,
        electionAlg => 3,
        initLimit => 5,
        leaderServes => 'yes',
        syncLimit => 10,
        cnxTimeout => 5,
        forceSync => 'yes',
        skipACL => 'yes',
    };

    my $servers;
    for (1..9) {
        $servers->{$_} = { server => "host$_:300$_:400$_", weight => 1 };
    }
    $cfg_params->{servers} = $servers;
    $cfg_params->{groups} = {
        1 => [1, 2, 3],
        2 => [4, 5, 6],
        3 => [7, 8, 9],
    };

    my $gen_cfg = catfile($self->{tempdir}, "zoo.cfg");
    my $s = Ubic::Service::ZooKeeper->new({
        %$cfg_params,
        gen_cfg => $gen_cfg,
    });
    $s->create_cfg_file;


    my %expected = %$cfg_params;
    for (1..9) {
        $expected{"server.$_"} = "host$_:300$_:400$_";
        $expected{"weight.$_"} = 1;
    }
    %expected = (
        %expected,
        'group.1' => '1:2:3',
        'group.2' => '4:5:6',
        'group.3' => '7:8:9',
    );
    delete $expected{servers};
    delete $expected{groups};


    my $res = {};
    my $content = slurp($gen_cfg);
    my @lines = split(/\n/, $content);
    foreach my $line (@lines) {
        next unless ($line);
        my ($k, $v) = split(/=/, $line);
        $res->{$k} = $v;
    }

    is_deeply($res, \%expected, 'check .cfg file content');
}

sub bin : Test {
    my $self = shift;

    my $s = Ubic::Service::ZooKeeper->new({
        java => '/usr/bin/java',
        java_cp => '/usr/share/zookeeper.jar',
        jmx_enable => 1,
        jmx_local_only => 0,
        zoo_log_dir => '/log/zookeeper',
        zoo_log4j_prop => 'INFO',
        zoo_main_class => 'org.QuorumPeerMain',
        java_opts => "-D org.a.b=C",
        gen_cfg => '/tmp/zoo.cfg',
    });

    my $bin = $s->bin;
    my $expected = "/usr/bin/java -D org.a.b=C -cp /usr/share/zookeeper.jar " .
                   "-Dcom.sun.management.jmxremote ".
                   "-Dcom.sun.management.jmxremote.local.only=false " .
                   "-Dzookeeper.log.dir=/log/zookeeper " .
                   "-Dzookeeper.root.logger=INFO " .
                   "org.QuorumPeerMain ".
                   "/tmp/zoo.cfg";
    is_deeply($bin, [ $expected ], 'check cmd line');
}

__PACKAGE__->new->runtests;
