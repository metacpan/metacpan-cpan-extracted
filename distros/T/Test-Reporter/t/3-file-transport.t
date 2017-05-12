#!/usr/bin/perl -w

use strict;
use Test::More 0.88;
use File::Temp;
use File::Find;

$Test::Reporter::VERSION ||= 999; # dzil will set it for us on release

#--------------------------------------------------------------------------#

my $from = 'johndoe@example.net';
my $dir = File::Temp::tempdir( CLEANUP => 1 );

#--------------------------------------------------------------------------#

require_ok( 'Test::Reporter' );

my $reporter = Test::Reporter->new();
ok(ref $reporter, 'Test::Reporter');

$reporter->grade('pass');
$reporter->distribution('Mail-Freshmeat-1.20');
$reporter->distfile('ASPIERS/Mail-Freshmeat-1.20.tar.gz');
$reporter->from($from);

my $form = {
    key     => 123456789,
    via     => my $via = "Test::Reporter ${Test::Reporter::VERSION}",
    from    => $from,
    subject => $reporter->subject(),
    report  => $reporter->report(),
};

$reporter->transport("File", $dir);

eval { $reporter->send };
is( $@, "", "report sent ok" );

my @reports;
find( sub { 
    push @reports, $_ if -f; 
}, $dir );

is( scalar @reports, 1, "found a report in the directory" );

done_testing;
