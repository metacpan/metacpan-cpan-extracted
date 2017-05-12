use strict;
use warnings;
use Test::Exception;
use Test::More;
use Test::TypeTiny;

use Types::Standard qw/Num/;
use Types::PerlVersion qw/PerlVersion/;
use Perl::Version;

ok( PerlVersion->has_coercion,        "has_coercion" );
ok( !PerlVersion->is_anon,            "not is_anon" );
ok( !PerlVersion->is_parameterized,   "not is_parameterized" );
ok( !PerlVersion->is_parameterizable, "not is_parameterizable" );

# coerced and Perl::Version objects should pass given sane args
foreach my $i (qw(1 1.2.3 v1.2.3 1.002_001)) {
    should_pass( PerlVersion->coerce($i), PerlVersion, "coerce $i" );
    should_pass( Perl::Version->new($i),  PerlVersion, "P::V->new $i" );
}

# scalars and undef should fail constraint checking
should_fail( 1,     PerlVersion );
should_fail( "a",   PerlVersion );
should_fail( undef, PerlVersion );

# check for some failed coercions
throws_ok(
    sub { PerlVersion->coerce("q") },
    qr/Illegal version string/,
    "version bad: q"
);

# Perl::Version
lives_ok( sub { PerlVersion->coerce(undef) },
    "we can coerce undef since Perl::Version allow this (weird huh?)" );

done_testing;
