BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use Test::More tests => 13 + 38;

$SIG{__DIE__} = sub { require Carp; Carp::confess() };
$SIG{__WARN__} = sub { require Carp; Carp::confess() };

BEGIN { use_ok('Thread::Pool::Resolve') }

can_ok( 'Thread::Pool::Resolve',qw(
 add
 autoshutdown
 line
 lines
 maxjobs
 minjobs
 new
 rand_domain
 rand_ip
 read
 remove
 resolved
 resolver
 self
 shutdown
 todo
 workers
) );

our $optimize = 'cpu';
my $require = 'resolveit';
$require = "t/$require" unless $ENV{PERL_CORE};
require $require;
