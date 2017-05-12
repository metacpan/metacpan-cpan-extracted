#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

use Test::Mock::ExternalCommand;

subtest 'unset_all', sub {
    my $m = Test::Mock::ExternalCommand->new();
    $m->set_command( "my_dummy_command1", "AAA\n", 0  );
    $m->set_command_by_coderef( "my_dummy_command2", sub { return "AAA" }  );


    my $m2 = Test::Mock::ExternalCommand->new();
    $m2->set_command( "my_dummy_command3", "AAA\n", 0  );

    is_deeply( [$m->commands()], [ "my_dummy_command1", "my_dummy_command2" ]);
    is_deeply( [Test::Mock::ExternalCommand::_registered_commands()], [ "my_dummy_command1", "my_dummy_command2", "my_dummy_command3" ]);

    $m->_unset_all_commands();

    is_deeply( [$m->commands()], []);
    is_deeply( [Test::Mock::ExternalCommand::_registered_commands()], ["my_dummy_command3"]);
};


subtest 'unset_all(history)', sub {
    my $m = Test::Mock::ExternalCommand->new();
    $m->set_command( "my_dummy_command1", "AAA\n", 0  );
    $m->set_command_by_coderef( "my_dummy_command2", sub { return "AAA" }  );

    `my_dummy_command2`;

    $m->_unset_all_commands();
    is_deeply([$m->history], []);
};


subtest 'destroy', sub {
    my $m = Test::Mock::ExternalCommand->new();
    $m->set_command( "my_dummy_command1", "AAA\n", 0  );
    $m->set_command_by_coderef( "my_dummy_command2", sub { return "AAA" }  );

    my $m2 = Test::Mock::ExternalCommand->new();
    $m2->set_command( "my_dummy_command3", "AAA\n", 0  );

    is_deeply( [Test::Mock::ExternalCommand::_registered_commands()], [ "my_dummy_command1", "my_dummy_command2", "my_dummy_command3" ]);

    $m = undef; #DESTROY

    is_deeply( [Test::Mock::ExternalCommand::_registered_commands()], ["my_dummy_command3"]);
};

done_testing();
