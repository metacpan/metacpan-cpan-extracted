#!perl -T
use strict;
use Test::More;

if ($] >= 5.006) {
    plan skip_all => "Perl $] has its own warnings";
}
else {
    plan tests => 18;
}


# warnings have been enabled by Test::Harness, so we must disable them
# and try to clean up the software environment
no warnings;
delete $INC{'warnings.pm'};

# now we can test the local warnings.pm
is( $^W, 0, "before the C<use warnings>, warnings are disabled" );
use_ok('warnings');
is( $^W, 1, "after the C<use warnings>, warnings are enabled" );
eval "no warnings";
is( $@, '', "unimporting warnings" );
is( $^W, 0, "after the C<no warnings>, warnings are disabled" );

# check the API
can_ok(warnings => qw(enabled warn warnif));

my $r;
$r = eval { warnings::enabled() };
is( $@, '', "warnings::enabled()" );
ok( !$r, "warnings are currently disabled" );

$^W = 1;    # enable warnings
$r = eval { warnings::enabled() };
is( $@, '', "warnings::enabled()" );
ok( $r, "warnings are currently enabled" );

my $errmsg = "Ceci n'est pas un avertissement.";
my @warns;
$SIG{__WARN__} = sub { push @warns, @_ };

@warns = ();
eval { warnings::warn $errmsg };
is( $@, '', "warnings::warn()" );
like( $warns[0], "/^$errmsg/", "checking warnings" );

$^W = 1; @warns = ();
eval { warnings::warnif $errmsg };
is( $@, '', "warnings::warnif() with warnings enabled" );
is( scalar @warns, 1, "checking warnings: number of stored items" );
like( $warns[0], "/^$errmsg/", "checking warnings: value of stored items" );

$^W = 0; @warns = ();
eval { warnings::warnif $errmsg };
is( $@, '', "warnings::warnif() with warnings disabled" );
is( scalar @warns, 0, "checking warnings: number of stored items" );
ok( ! defined $warns[0], "checking warnings: value of stored items" );

