use strict;
use warnings;
use open qw[:encoding(UTF-8) :std];
use charnames ":full";
use Test::More tests => 3;
use Text::Bidi qw(log2vis);

sub f($) { join(' ', map { sprintf("U+%04x(%s)", ord, lc charnames::viacode(ord)) } split //, shift ) }

sub t($$$) {
	my ($name, $try, $real) = @_;
	my $vis = log2vis($try);
	return ok(1, $name) if $vis eq $real;
	ok(0, $name);
	printf <<DUMP, f $try, f $vis, f $real;
#   log2vis('%s')
#   is '%s', 
#   while '%s' was expected
DUMP
}

t "default join"     => 
	"\N{ARABIC LETTER LAM}\N{ARABIC LETTER HAH}", 
	"\N{ARABIC LETTER HAH FINAL FORM}\N{ARABIC LETTER LAM INITIAL FORM}";
t "force non-join" => 
	"\N{ARABIC LETTER LAM}\N{ZERO WIDTH NON-JOINER}\N{ARABIC LETTER HAH}", 
	"\N{ARABIC LETTER HAH ISOLATED FORM}\N{ZERO WIDTH NON-JOINER}\N{ARABIC LETTER LAM ISOLATED FORM}";
t "force join" => 
	"\N{ARABIC LETTER LAM}\N{ZERO WIDTH JOINER}\N{ARABIC LETTER HAH}", 
	"\N{ARABIC LETTER HAH FINAL FORM}\N{ZERO WIDTH JOINER}\N{ARABIC LETTER LAM INITIAL FORM}";
