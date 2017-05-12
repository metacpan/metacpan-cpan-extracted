#!/usr/bin/perl
package MyWorker;
use base qw( TheSchwartz::Worker );

sub work {
    my $class = shift;
    my $job   = shift;

    my $arg = $job->arg;
    warn $arg->{msg};

    $job->completed;
}

package main;
use TheSchwartz;

my $dbname = shift @ARGV or die "dbname required";

my $client = TheSchwartz->new(databases => [ { dsn => "dbi:mysql:$dbname", user => 'root' } ]);
$client->set_prioritize(1);
$client->can_do('MyWorker');
$client->work_once;

1;
