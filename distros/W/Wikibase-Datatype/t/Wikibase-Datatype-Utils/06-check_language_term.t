use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Wikibase::Datatype::Utils qw(check_language_term);

# Test.
my $self = {
	'key' => 'en',
};
my $ret = check_language_term($self, 'key');
is($ret, undef, 'Right language is present.');

# Test.
$self = {
	'key' => 'xx',
};
$Wikibase::Datatype::Utils::SKIP_CHECK_TERM_LANG = 1;
$ret = check_language_term($self, 'key');
is($ret, undef, 'Not supported language is present without error.');
$Wikibase::Datatype::Utils::SKIP_CHECK_TERM_LANG = 0;

# Test.
$self = {
	'key' => 'xx',
};
$Wikibase::Datatype::Utils::SKIP_CHECK_TERM_LANG = 0;
@Wikibase::Datatype::Utils::TERM_LANGUAGE_CODES = ('xx');
$ret = check_language_term($self, 'key');
is($ret, undef, 'Language is supported by user list.');
$Wikibase::Datatype::Utils::SKIP_CHECK_TERM_LANG = 0;
@Wikibase::Datatype::Utils::TERM_LANGUAGE_CODES = ();

# Test.
$self = {
	'key' => 'yy',
};
$Wikibase::Datatype::Utils::SKIP_CHECK_TERM_LANG = 0;
@Wikibase::Datatype::Utils::TERM_LANGUAGE_CODES = ('xx');
eval {
	check_language_term($self, 'key');
};
is($EVAL_ERROR, "Language code 'yy' isn't user defined terms language code.\n",
	"Language code 'yy' isn't user defined terms language code.");
clean();
$Wikibase::Datatype::Utils::SKIP_CHECK_TERM_LANG = 0;
@Wikibase::Datatype::Utils::TERM_LANGUAGE_CODES = ();

# Test.
$self = {
	'key' => 'yy',
};
$Wikibase::Datatype::Utils::SKIP_CHECK_TERM_LANG = 1;
@Wikibase::Datatype::Utils::TERM_LANGUAGE_CODES = ('xx');
$ret = check_language_term($self, 'key');
is($ret, undef, 'Not supported language is present without error.');
$Wikibase::Datatype::Utils::SKIP_CHECK_TERM_LANG = 0;
@Wikibase::Datatype::Utils::TERM_LANGUAGE_CODES = ();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_language_term($self, 'key');
};
is($EVAL_ERROR, "Language code 'foo' isn't code supported for terms by Wikibase.\n",
	"Language code 'foo' isn't code supported for terms by Wikibase.");
clean();

# Test.
$self = {
	'key' => 'xx',
};
eval {
	check_language_term($self, 'key');
};
is($EVAL_ERROR, "Language code 'xx' isn't code supported for terms by Wikibase.\n",
	"Language code 'xx' isn't code supported for terms by Wikibase.");
clean();

# Test.
$self = {
	'key' => 'und',
};
eval {
	check_language_term($self, 'key');
};
is($EVAL_ERROR, "Language code 'und' isn't code supported for terms by Wikibase.\n",
	"Language code 'und' isn't code supported for terms by Wikibase.");
clean();
