#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

use Test::Mock::ExternalCommand;
use Capture::Tiny qw(capture);

my $m = Test::Mock::ExternalCommand->new();

$m->set_command( "my_dummy_command1", "AAA\n", 0  );

my ($stdout, $stderr) = capture {
    $m->set_command( "my_dummy_command1", "AAA\n", 0  );
};

like( $stderr, qr/my_dummy_command1: already defined/);

($stdout, $stderr) = capture {
    $m->set_command_by_coderef( "my_dummy_command1", sub { return "AAA\n" } );
};

like( $stderr, qr/my_dummy_command1: already defined/);

done_testing();
