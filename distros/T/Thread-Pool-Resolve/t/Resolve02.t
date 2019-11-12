BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use Test::More tests => 12 + 38;

$SIG{__DIE__} = sub { require Carp; Carp::confess() };
$SIG{__WARN__} = sub { require Carp; Carp::confess() };

BEGIN { use_ok('Thread::Pool::Resolve') }

our $optimize = 'memory';
my $require = 'resolveit';
$require = "t/$require" unless $ENV{PERL_CORE};
require $require;
