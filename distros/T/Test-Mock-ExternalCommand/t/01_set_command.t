#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

use Test::Mock::ExternalCommand;

my $m = Test::Mock::ExternalCommand->new();
ok(defined $m);

$m->set_command( "my_dummy_command1", "AAA\n", 0  );
$m->set_command( "my_dummy_command2", "BBB\n", 1  );

my $cmd = "my_dummy_command1";

is( `$cmd`, "AAA\n" );
is( `my_dummy_command2`, "BBB\n" );

my $ret1 = system($cmd);
is( $ret1>>8, 0);

my $ret2 = system("my_dummy_command2");
is( $ret2>>8, 1);

done_testing();
