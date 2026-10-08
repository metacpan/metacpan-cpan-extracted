#!/usr/bin/perl
#
# Non-regression tests for the Field family:
# oEdtk::Field, oEdtk::FPField, oEdtk::SignedField, oEdtk::DateField,
# oEdtk::AddrField.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use TestOEdtk qw(quiet_require);

quiet_require($_) for qw(oEdtk::Field oEdtk::FPField oEdtk::SignedField
                         oEdtk::DateField oEdtk::AddrField);

# --- oEdtk::Field : base class, identity processing -------------------------
my $f = oEdtk::Field->new('NOM', 10);
isa_ok($f, 'oEdtk::Field');
is($f->get_name, 'NOM', 'Field get_name');
is($f->get_len, 10, 'Field get_len');
is($f->process('abc'), 'abc', 'Field process is the identity');
$f->set_name('X');
is($f->get_name, 'X', 'Field set_name');

# --- oEdtk::FPField : implicit decimal point --------------------------------
my $fp = oEdtk::FPField->new('MNT', 6, 2);
isa_ok($fp, 'oEdtk::FPField');
is($fp->get_len, 8, 'FPField length is intlen + fraclen');
is($fp->process('1234'), '12.34', 'FPField inserts the implicit decimal point');
is($fp->process('1 234'), '12.34', 'FPField strips spaces');
is($fp->process(''), '', 'FPField keeps the empty string');
is($fp->process('12.34'), '12.34', 'FPField keeps an explicit decimal point');
is($fp->process('12.3'), '12.30', 'FPField re-formats to fraclen');
is(oEdtk::FPField->new('X', 4, 0)->process('42'), '42', 'FPField with fraclen 0');

# --- oEdtk::SignedField : Infinite-style signed amounts ---------------------
my $sf = oEdtk::SignedField->new('MNT', 3, 2);
isa_ok($sf, 'oEdtk::SignedField');
is($sf->process('1234q'), '-123.41', 'SignedField decodes the q sign');
is($sf->process('1234'), '12.34', 'SignedField without sign');
is($sf->process('12p'), '-1.20', 'SignedField decodes the p sign');
is($sf->process(''), '0.00', 'SignedField empty becomes 0.00');
is(oEdtk::SignedField->new('M', 5, 0)->process('3x'), -38, 'SignedField fraclen 0 decodes x');
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	is(oEdtk::SignedField->new('M', 5, 0)->process('abc'), 'abc',
	   'SignedField keeps a non-numeric value');
	like($w[0] // '', qr/Unexpected numerical value/, '... and warns');
}

# --- oEdtk::DateField : YYYYMMDD -> DD/MM/YYYY -------------------------------
my $df = oEdtk::DateField->new('D', 8);
isa_ok($df, 'oEdtk::DateField');
is($df->process('20240115'), '15/01/2024', 'DateField formats YYYYMMDD');
is($df->process('20240115X'), '15/01/2024', 'DateField ignores trailing characters');
is($df->process('bad'), 'bad', 'DateField keeps an unparseable value');

# --- oEdtk::AddrField : trim + strip accents + upper-case -------------------
my $af = oEdtk::AddrField->new('A', 38);
isa_ok($af, 'oEdtk::AddrField');
is($af->process(" caf\xE9  "), 'CAFE', 'AddrField trims, strips accents and upper-cases');
is($af->process('  jean  pierre '), 'JEAN  PIERRE', 'AddrField keeps inner spaces');

done_testing();
