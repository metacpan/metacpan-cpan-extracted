#####################################################################
#
#  Test suite for 'Weather::Com::L10N'
#
#  Before `make install' is performed this script should be runnable
#  with `make test'. After `make install' it should work as
#  `perl t/L10N.t'
#
#####################################################################
#
# initialization
#
no warnings;
use Test::More tests => 7;

BEGIN {
	use_ok('Weather::Com::L10N');
}

#####################################################################
#
# Testing object instantiation (do we use the right class)?
#
my $wind = Weather::Com::L10N->get_handle('de');
isa_ok( $wind, "Weather::Com::L10N",   'Is a Weatcher::Com::L10N object' );
isa_ok( $wind, "Locale::Maketext", 'Is a Locale::Maketext object' );

# test for existing translations
is($wind->maketext('unknown'), 'unbekannt', 'Translation of known words');
is($wind->maketext('NNE'), 'NNO', 'Translation of known words');

# test for non-existent translations
is($wind->maketext('hello'), 'hello', 'Translation of unknown words');

# test for non-existent languages
$wind = Weather::Com::L10N->get_handle('kr');
is($wind->maketext('unknown'), 'unknown', 'Test for default language');


