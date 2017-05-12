#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

use Test::Mock::ExternalCommand;

my $m = Test::Mock::ExternalCommand->new();

$m->set_command( "my_dummy_command1", "", 0  );
$m->set_command( "my_dummy_command2", "", 1  );
$m->set_command( "my_dummy_command3", "", 1  );
$m->set_command_by_coderef( "my_dummy_command4", sub { return 1 }  );

system("my_dummy_command1 -x -y");
system("my_dummy_command2 --some-option");
`my_dummy_command3 -a -b`;
`my_dummy_command4`;
system("my_dummy_command4");

my $history_expected = [
    ["my_dummy_command1", "-x", "-y"],
    ["my_dummy_command2", "--some-option"],
    ["my_dummy_command3", "-a", "-b"],
    ["my_dummy_command4"],
    ["my_dummy_command4"],
];

is_deeply( [$m->history], $history_expected );

$m->reset_history();
is_deeply( [$m->history], [] );

done_testing();
