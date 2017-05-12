#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use TheSchwartz::Simple;

my $dbname = shift @ARGV or die "DB name required";
my $dbh = DBI->connect("dbi:mysql:$dbname", "root", "", { RaiseError => 1 });
my $client = TheSchwartz::Simple->new([ $dbh ]);
$client->insert('MyWorker', { msg => "Hello" });

my $job = TheSchwartz::Simple::Job->new;
$job->funcname('MyWorker');
$job->arg({ msg => "This is priority 100!" });
$job->priority(100);
$client->insert($job);

$job = TheSchwartz::Simple::Job->new;
$job->funcname('MyWorker');
$job->arg({ msg => "This should be run after 10 seconds" });
$job->run_after(time + 10);
$client->insert($job);



