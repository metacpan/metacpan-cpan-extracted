#!/usr/bin/perl
#
# Non-regression tests for oEdtk::Dict (INI-backed dictionary), oEdtk::C7Tag
# and oEdtk::C7Doc (Compuset tag builders).
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp qw(tempfile);
use TestOEdtk qw(quiet_require);

quiet_require($_) for qw(oEdtk::Dict oEdtk::C7Tag oEdtk::C7Doc);

# --- oEdtk::Dict ------------------------------------------------------------
my ($dfh, $dfile) = tempfile('oedtk_dict_XXXXXX', SUFFIX => '.ini', UNLINK => 1);
print $dfh "[DEFAULT]\na=alpha\nb=beta\n";
close($dfh);

my $dict = oEdtk::Dict->new($dfile, {});
isa_ok($dict, 'oEdtk::Dict');
is($dict->translate('a'), 'alpha', 'Dict translate looks up a key');
is($dict->translate('A'), 'alpha', 'Dict translate is case-insensitive by default');
is($dict->translate('zzz'), 'zzz', 'Dict translate returns the word when absent');
is($dict->translate('zzz', 1), undef, 'Dict translate returns undef when absent and check is set');

my $inv = oEdtk::Dict->new($dfile, { invert => 1 });
is($inv->translate('alpha'), 'a', 'Dict invert swaps keys and values');

# ignore_case is read as "$options->{ignore_case} || 1", so a falsy 0 silently
# keeps the default case-insensitive behaviour.
my $ci0 = oEdtk::Dict->new($dfile, { ignore_case => 0 });
is($ci0->translate('a'), 'alpha', 'Dict translate with ignore_case=0 still matches');
is($ci0->translate('A'), 'alpha', '... because a falsy option falls back to 1');

# substitue replaces every dictionary key (case-insensitive) inside a string.
my ($sfh, $sfile) = tempfile('oedtk_dictsub_XXXXXX', SUFFIX => '.ini', UNLINK => 1);
print $sfh "[DEFAULT]\na=X\n";
close($sfh);
my $dsub = oEdtk::Dict->new($sfile, {});
is($dsub->substitue('banana'), 'bXnXnX', 'Dict substitue expands keys in a string');

# --- oEdtk::C7Tag -----------------------------------------------------------
is(oEdtk::C7Tag->new('NOM', 'Jean  Paul')->emit, '<#NOM=Jean Paul>',
   'C7Tag collapses whitespace inside a value');
is(oEdtk::C7Tag->new('T', undef)->emit, '<T>',
   'C7Tag with an undefined value emits a bare tag');
is(oEdtk::C7Tag->new('BOX', { A => '1' })->emit, '<#BOX=<#A=1>>',
   'C7Tag with a hashref emits nested tags');
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	is(oEdtk::C7Tag->new('_include_', '/p/f')->emit, '<include>/p/f<SK>',
	   'C7Tag _include_ emits an include directive');
	like($w[0] // '', qr/Tag name too long/, '... and warns about the long name');
}
eval { oEdtk::C7Tag->new('X', []) };
like($@, qr/Unexpected value type/, 'C7Tag dies on an unsupported value type');

# --- oEdtk::C7Doc -----------------------------------------------------------
my $doc = oEdtk::C7Doc->new;
isa_ok($doc, 'oEdtk::C7Doc');
is($doc->line_break, "\n", 'C7Doc line_break is a newline');
is($doc->mktag('A', '1')->emit, '<#A=1>', 'C7Doc mktag builds a C7Tag');
$doc->append_table('ADDRESS', 'a', 'b');
is("$doc", '<#ADDRES00=a><#ADDRES01=b>',
   'C7Doc append_table names elements with a truncated table name and index');

done_testing();
