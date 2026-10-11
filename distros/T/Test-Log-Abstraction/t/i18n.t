use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings;
use Encode ();
use Test::Log::Abstraction;
use Capture qw(capture_diag);

# White-box tests of the message layer.  i18n() is meant for subclasses,
# and is called directly here.

$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

my $class = 'Test::Log::Abstraction';

# A logger whose only English template is the one under test
sub with_template {
	my ($template, %options) = @_;

	my $lang = delete($options{'lang'}) || 'en';
	return $class->new(diag => 'none', lang => $lang, i18n => { $lang => { t => $template } }, %options);
}

subtest 'interpolation' => sub {
	is(with_template('%{a}s then %{b}s')->i18n('t', { a => 1, b => 2 }), '1 then 2', 'named placeholders');
	is(with_template('%{b}s before %{a}s')->i18n('t', { a => 1, b => 2 }), '2 before 1', 'placeholders can be reordered');
	is(with_template('100%%')->i18n('t'), '100%', '%% is a literal percent sign');
	is(with_template('%{ratio}.2f')->i18n('t', { ratio => 1 / 3 }), '0.33', 'sprintf conversions apply');
	is(with_template('[%{n}5s]')->i18n('t', { n => 'ab' }), '[   ab]', 'widths apply');
	is(with_template('%{class}s')->i18n('t'), $class, 'class defaults to the invocant class');

	my @warnings;
	local $SIG{'__WARN__'} = sub { push @warnings, @_ };
	is(with_template('%{missing}s!')->i18n('t'), 'undef!', 'missing value renders as undef');
	is(with_template('%{n}d items')->i18n('t', { n => 'many' }), 'many items', 'non-numeric value for %d is kept, not zeroed');
	is(with_template('%{n}n')->i18n('t', { n => 1 }), '%{n}n', '%n is not a permitted conversion');
	is(scalar(@warnings), 0, 'no warnings from bad values') or diag(@warnings);
};

subtest 'plural forms' => sub {
	my $forms = { zero => 'none', one => '%{count}d item', other => '%{count}d items' };
	my $en = with_template($forms);
	is($en->i18n('t', { count => 0 }), 'none', 'zero form for 0');
	is($en->i18n('t', { count => 1 }), '1 item', 'one form for 1');
	is($en->i18n('t', { count => 2 }), '2 items', 'other form for 2');
	is($en->i18n('t'), 'undef items', 'no count: other form');

	# French counts 0 as singular; with no zero form that is what is used
	my $fr = with_template({ one => '%{count}d objet', other => '%{count}d objets' }, lang => 'fr');
	is($fr->i18n('t', { count => 0 }), '0 objet', 'French 0 is singular');
	is($fr->i18n('t', { count => 2 }), '2 objets', 'French 2 is plural');

	# Chinese has no plural: always other
	my $zh = with_template({ one => 'one', other => 'other' }, lang => 'zh');
	is($zh->i18n('t', { count => 1 }), 'other', 'Chinese always uses other');

	# English with only an other form
	is(with_template({ other => 'x%{count}d' })->i18n('t', { count => 1 }), 'x1', 'missing category falls back to other');
};

subtest 'gender forms' => sub {
	my $logger = with_template({
		male => { one => 'he logged %{count}d', other => 'he logged %{count}d lines' },
		female => 'she logged',
		other => 'they logged',
	});
	is($logger->i18n('t', { gender => 'female' }), 'she logged', 'female form');
	is($logger->i18n('t', { gender => 'male', count => 1 }), 'he logged 1', 'gender then plural');
	is($logger->i18n('t', { gender => 'male', count => 3 }), 'he logged 3 lines', 'gender then plural, other');
	is($logger->i18n('t', { gender => 'neuter' }), 'they logged', 'unknown gender falls back to other');
	is($logger->i18n('t'), 'they logged', 'no gender falls back to other');
	is(with_template({ male => 'm' })->i18n('t'), '', 'no applicable form renders empty, not undef');
};

subtest 'catalogue lookup and fallback' => sub {
	my $de = $class->new(lang => 'de');
	like($de->i18n('needs_pattern', { method => 'like' }), qr/like\(\) ben\x{f6}tigt ein Muster/, 'German template used');
	is($de->i18n('entry', { level => 'warn', message => 'm' }), '    [warn] m', 'missing German key falls back to English');
	is($de->i18n('no_such_key'), 'no_such_key', 'unknown key is returned as it is');

	my $override = $class->new(lang => 'de', i18n => { de => { no_method => 'eigene %{method}s' } });
	is($override->i18n('no_method', { method => 'x' }), 'eigene x', 'i18n option overrides the catalogue');
	is($class->new(lang => 'de')->i18n('no_method', { method => 'x' }), "$class: keine Methode 'x'", 'override is per logger');

	my $custom = $class->new(lang => 'xx', i18n => { xx => { no_method => 'xx %{method}s' } });
	is($custom->lang(), 'xx', 'a language supplied by the i18n option is accepted');
	is($custom->i18n('no_method', { method => 'y' }), 'xx y', 'and used');
	is($custom->i18n('needs_level', { method => 'z' }), "$class: z() needs a level name", 'and falls back to English');

	is($class->new(lang => 'ja')->lang(), 'en', 'language without a catalogue falls back to English');
	is($class->new(lang => 'de_AT.UTF-8')->lang(), 'de', 'locale name reduced to its language');
	is($class->i18n('no_method', { method => 'x' }), "$class: no method 'x'", 'class call uses %config language');
	{
		local $Test::Log::Abstraction::config{'lang'} = 'fr';
		like($class->i18n('no_method', { method => 'x' }), qr/aucune m\x{e9}thode/, 'class call follows %config');
	}
};

subtest 'translated diagnostics are printed as UTF-8 without warnings' => sub {
	my $logger = $class->new(lang => 'zh', diag => 'none');
	my $out = capture_diag { $logger->nolevel('x') };
	my $expected = Encode::encode('UTF-8', $logger->i18n('no_method', { method => 'nolevel' }));
	like($out, qr/\Q$expected\E/, 'notice is UTF-8 encoded');

	# Regression: French and German text has no character above 0xFF, and
	# was printed as Latin-1 instead of UTF-8
	my $fr = $class->new(lang => 'fr', diag => 'none');
	$out = capture_diag { $fr->nolevel('x') };
	like($out, qr/aucune m\xc3\xa9thode 'nolevel'/, 'French notice is UTF-8, not Latin-1');

	# A character string logged by the code under test is encoded too
	my $en = $class->new(diag => 'all');
	$out = capture_diag { $en->warn("snowman \x{2603}") };
	like($out, qr/snowman \xe2\x98\x83/, 'wide character message encoded');

	# Byte strings are printed untouched
	$out = capture_diag { $en->warn("caf\xc3\xa9") };
	like($out, qr/caf\xc3\xa9/, 'byte string not re-encoded');
};

done_testing();
