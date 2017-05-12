#!/usr/bin/perl

use strict;
use warnings;
use t::Utils;
use TheSchwartz::Moosified;
use File::Spec qw();

plan tests => 18;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $client = TheSchwartz::Moosified->new( scoreboard => 1 );
    $client->databases([$dbh]);
    $client->prefix($::prefix) if $::prefix;

    my $sb_file = $client->scoreboard;
    
    {
        my $handle = $client->insert("Worker::Addition",
                                     {numbers => [1, 2]});
        my $job    = Worker::Addition->grab_job($client);

        my $rv = eval { Worker::Addition->work_safely($job); };
        ok(length($@) == 0, 'Finished job with out error');

        unless (ok(-e $sb_file, "Scoreboard file exists")) {
            return;
        }

        open(FH, $sb_file) or die "Can't open '$sb_file': $!\n";

        my %info = map { chomp; /^([^=]+)=(.*)$/ } <FH>;
        close(FH);

        ok($info{pid} == $$, 'Has our PID');
        ok($info{funcname} eq 'Worker::Addition', 'Has our funcname');
        ok($info{started} =~ /\d+/, 'Started time is a number');
        ok($info{started} <= time, 'Started time is in the past');
        ok($info{arg} =~ /^numbers=ARRAY/, 'Has right args');
        ok($info{done} =~ /\d+/, 'Job has done time');
    }

    {
        $client->DEMOLISH;
        ok(! -e $sb_file, 'Scoreboard file goes away when worker finishes');
    }
};

}

############################################################################
package Worker::Addition;
use base 'TheSchwartz::Moosified::Worker';

sub work {
    my ($class, $job) = @_;
    sleep 3;
}

1;
