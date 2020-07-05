BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 5;

BEGIN { use_ok('threads') }
BEGIN { use_ok('threads::farm') }

my $farm = threads::farm->new({
	autoshutdown => 1, # default: 1 = yes
	workers => 5,      # default: 1
	pre => sub {shift; print "starting worker with @_\n" },
	do => sub {shift; print "doing job for @_\n"; reverse @_},
	post => sub {shift; print "stopping worker with @_\n"}
}, qw(a b c) );

my $jobid = $farm->job( qw(d e f) );              # not interested in result

is($jobid, 1, 'JOB ID');

$jobid = $farm->job( qw(g h i) );

is($jobid, 2);

my @result = $farm->result( $jobid );    # wait for result to be ready

is_deeply(\@result, ['i', 'h', 'g']);

done_testing;

