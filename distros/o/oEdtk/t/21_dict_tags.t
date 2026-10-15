#!/usr/bin/perl
#
# Non-regression tests for oEdtk::Dict (INI-backed dictionary).
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp qw(tempfile);
use TestOEdtk  qw(quiet_require);

quiet_require($_) for qw(oEdtk::Dict);

# --- oEdtk::Dict ------------------------------------------------------------
my ( $dfh, $dfile ) = tempfile( 'oedtk_dict_XXXXXX', SUFFIX => '.ini', UNLINK => 1 );
print $dfh "[DEFAULT]\na=alpha\nb=beta\n";
close($dfh);

my $dict = oEdtk::Dict->new( $dfile, {} );
isa_ok( $dict, 'oEdtk::Dict' );
is( $dict->translate('a'),   'alpha', 'Dict translate looks up a key' );
is( $dict->translate('A'),   'alpha', 'Dict translate is case-insensitive by default' );
is( $dict->translate('zzz'), 'zzz',   'Dict translate returns the word when absent' );
is( $dict->translate( 'zzz', 1 ),
	undef, 'Dict translate returns undef when absent and check is set' );

my $inv = oEdtk::Dict->new( $dfile, { invert => 1 } );
is( $inv->translate('alpha'), 'a', 'Dict invert swaps keys and values' );

# ignore_case is read as "$options->{ignore_case} || 1", so a falsy 0 silently
# keeps the default case-insensitive behaviour.
my $ci0 = oEdtk::Dict->new( $dfile, { ignore_case => 0 } );
is( $ci0->translate('a'), 'alpha', 'Dict translate with ignore_case=0 still matches' );
is( $ci0->translate('A'), 'alpha', '... because a falsy option falls back to 1' );

# substitue replaces every dictionary key (case-insensitive) inside a string.
my ( $sfh, $sfile ) = tempfile( 'oedtk_dictsub_XXXXXX', SUFFIX => '.ini', UNLINK => 1 );
print $sfh "[DEFAULT]\na=X\n";
close($sfh);
my $dsub = oEdtk::Dict->new( $sfile, {} );
is( $dsub->substitue('banana'), 'bXnXnX', 'Dict substitue expands keys in a string' );

done_testing();
