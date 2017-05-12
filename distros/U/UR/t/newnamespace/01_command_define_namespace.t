#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../lib";

use File::Temp;
use Cwd;

use UR;

my $current_dir = Cwd::cwd;
END { chdir $current_dir };  # so the temp dir can get cleaned up

my $tempdir = File::Temp::tempdir(CLEANUP => 1);
ok($tempdir, 'make temp dir');
chdir($tempdir);

push @INC,$tempdir; # so it can find the namespace modules it's creating

my $cmd = UR::Namespace::Command::Define::Namespace->create(nsname => 'NewNamespace');
ok($cmd, 'create UR::Namespace::Command::Define::Namespace');

my $got_to_end = 0;
END {
    unless ($got_to_end) {
        print STDERR "The test didn't finish, here the output from the define namespace command\n";
        print STDERR "*** STATUS messages:\n", join("\n", $cmd->status_messages),"\n\n";
        print STDERR "*** WARNING messages:\n", join("\n", $cmd->warning_messages),"\n\n";
        print STDERR "*** ERROR messages:\n", join("\n", $cmd->error_messages),"\n\n";
    }
}

$cmd->dump_status_messages(0);
$cmd->dump_error_messages(0);
$cmd->dump_warning_messages(0);
$cmd->queue_status_messages(1);
$cmd->queue_error_messages(1);
$cmd->queue_warning_messages(1);

ok($cmd->execute, 'execute');

my $namespace = UR::Namespace->get('NewNamespace');
ok($namespace, 'Namespace object created');

my $data_source = UR::DataSource->get('NewNamespace::DataSource::Meta');
ok($data_source, 'Metadata data source object created');

ok(-f 'NewNamespace.pm', 'NewNamespace.pm module exists');
ok(-d 'NewNamespace', 'NewNamespace directory exists');
ok(-d 'NewNamespace/DataSource', 'NewNamespace/DataSource directory exists');
ok(-f 'NewNamespace/DataSource/Meta.pm', 'NewNamespace/DataSource/Meta.pm module exists');
ok(-f 'NewNamespace/Vocabulary.pm', 'NewNamespace/Vocabulary.pm module exists');

my @messages = $cmd->status_messages();
is($messages[0], 'A   NewNamespace (UR::Namespace)', 'Message adding NewNamespace');
is($messages[1], 'A   NewNamespace::Vocabulary (UR::Vocabulary)', 'Message adding vocabulary');
is($messages[2], 'A   NewNamespace::DataSource::Meta (UR::DataSource::Meta)', 'Message adding meta datasource');
like($messages[3],
     qr(A   /.+/NewNamespace/DataSource/Meta\.sqlite3n?-dump [(]Metadata DB skeleton[)]),
     'Message adding metaDB dump file');

$got_to_end = 1;
