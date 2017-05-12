#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

use Test::Mock::ExternalCommand;

my $m = Test::Mock::ExternalCommand->new();
$m->set_command_by_coderef( "my_dummy_command1", sub { return 0 });
$m->set_command_by_coderef( "my_dummy_command2", sub { return 1 });
$m->set_command_by_coderef( "my_dummy_command3", sub { return "CCC\n" });
$m->set_command_by_coderef( "my_dummy_command4", sub { return "DDD\n" });

my $ret1 = system("my_dummy_command1");
is( $ret1>>8, 0);

my $ret2 = system("my_dummy_command2");
is( $ret2>>8, 1);

is( `my_dummy_command3`, "CCC\n" );
is( `my_dummy_command4`, "DDD\n" );

is_deeply( [$m->commands()], ["my_dummy_command1", "my_dummy_command2", "my_dummy_command3", "my_dummy_command4" ]);

done_testing();
