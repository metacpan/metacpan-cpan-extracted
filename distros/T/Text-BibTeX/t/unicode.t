# -*- cperl -*-
use strict;
use warnings;
use utf8;

use Test::More;
use Encode qw(encode);
use Unicode::Normalize qw(NFD NFC);

use Text::BibTeX qw(purify_string change_case);
use Text::BibTeX::Name;
use Text::BibTeX::NameFormat;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

sub parts {
   my $name = Text::BibTeX::Name->new(@_);
   return join ' / ', map { my @p = $name->part($_); join ' ', grep { defined } @p } qw(first von last jr);
}

# "von" particles are found by the case of their first letter, in any script
is(parts('Ludwig van Beethoven'), 'Ludwig / van / Beethoven / ', 'ASCII von');
is(parts('Αλέξανδρος του Μακεδόνα'), 'Αλέξανδρος / του / Μακεδόνα / ', 'Greek von');
is(parts('Иван фон дер Иванов'), 'Иван / фон дер / Иванов / ', 'Cyrillic von');
is(parts('𝓺aa Smith, John'), 'John / 𝓺aa / Smith / ', '4-byte lowercase letter');
is(parts('Émile Zola'), 'Émile /  / Zola / ', 'uppercase accented letter is not von');
is(parts('李 小龙'), '李 /  / 小龙 / ', 'caseless script');

# Initials are whole characters, including combining marks
my $initials = Text::BibTeX::NameFormat->new('f', 1);
is(Text::BibTeX::Name->new('Émile Zola')->format($initials), 'É.', 'precomposed initial');
is(Text::BibTeX::Name->new({ normalization => 'NFD' }, NFD('Émile Zola'))->format($initials),
   NFD('É.'), 'decomposed initial keeps its combining mark');
is(Text::BibTeX::Name->new('Jean-Émile Dupont')->format($initials), 'J.-É.', 'hyphenated initials');
is(Text::BibTeX::Name->new('Ǆemal Bijedić')->format($initials), 'Ǆ.', 'digraph initial');
is(Text::BibTeX::Name->new('Mesut {\"O}zil')->format($initials), 'M.', 'special char untouched');
is(Text::BibTeX::Name->new('{\"O}zil Mesut')->format($initials), '{\"O}.', 'TeX special character initial');

# purify keeps letters, digits and combining marks in any script
is(purify_string('Gödel, Escher; Bach!'), 'Gödel Escher Bach', 'purify Latin');
is(purify_string(NFD('Gödel')), NFD('Gödel'), 'purify keeps combining marks');
is(purify_string('Περὶ ψυχῆς: σύνοψις'), 'Περὶ ψυχῆς σύνοψις', 'purify Greek');
is(purify_string('१९८७–०१'), '१९८७०१', 'purify keeps non-ASCII digits, drops dashes');
is(purify_string('G{\"o}del'), 'Godel', 'purify special characters as before');

# change_case uses full Unicode case mappings
is(change_case('u', 'straße'), 'STRASSE', 'uppercase ß');
is(change_case('l', 'İSTANBUL'), "i\x{307}stanbul", 'lowercase dotted I');
is(change_case('t', 'ǆungla, ǆungla. ǆungla'), 'ǅungla, ǆungla. ǅungla', 'titlecase digraph');
is(change_case('u', 'Περὶ ψυχῆς'), "ΠΕΡῚ ΨΥΧΗ\x{342}Σ", 'uppercase Greek');
is(change_case('t', 'ÉCOLE {ÉCOLE} {\\\'E}COLE'), 'École {ÉCOLE} {\\\'e}cole', 'titlecase with braces');
is(change_case('u', '{\\ss} {\\oe}uvre'), '{SS} {\\OE}UVRE', 'foreign letters (BibTeX rules)');
ok(utf8::is_utf8(change_case('u', 'é')), 'character string in, character string out');
is(change_case('u', encode('UTF-8', 'é')), encode('UTF-8', 'É'), 'bytes in, bytes out');

# Entries: names, macros and values in Unicode, TeX passed through
{
   local $Text::BibTeX::Error::Handler = sub { };
   my $entry = Text::BibTeX::Entry->new(<<'BIB');
@ARTÏCLE{Clé,
  ÉDITOR = {Ångström, Anders},
  Tïtle = {Über {\"U}ber \emph{alles}} # " " # MÄC,
}
BIB
   ok($entry->parse_ok, 'Unicode entry parses');
   is($entry->type, 'artïcle', 'entry type lowercased');
   is($entry->key, 'Clé', 'key unchanged');
   is_deeply([$entry->fieldlist], ['éditor', 'tïtle'], 'field names lowercased');
   is($entry->line('tïtle'), 3, 'line numbers of Unicode field names');
   ok($entry->exists('ÉDITOR') || $entry->exists('éditor'), 'exists');
   is($entry->get('tïtle'), 'Über {\"U}ber \emph{alles}', 'TeX passed through, undefined macro empty');
   ok(utf8::is_utf8($entry->get('tïtle')), 'values are character strings');
}
{
   Text::BibTeX::Entry->new('@string{Mäc = "Größe"}');
   my $entry = Text::BibTeX::Entry->new('@misc{k, title = mÄc # MÄC}');
   is($entry->get('title'), 'GrößeGröße', 'macro names are case-insensitive in Unicode');
   Text::BibTeX::delete_macro('MÄC');
   is(Text::BibTeX::macro_length('mäc'), 0, 'delete_macro is case-insensitive');
}

# Normalization: NFC by default, NFD on request; lookups normalise too
{
   my $bib = encode('UTF-8', NFD('@misc{k, title = {Gödel}, Größe = {x}}'));
   my $entry = Text::BibTeX::Entry->new($bib);
   is($entry->get('title'), NFC('Gödel'), 'NFC by default');
   is($entry->get(NFD('größe')), 'x', 'lookup with NFD key');

   $entry = Text::BibTeX::Entry->new({ normalization => 'NFD' });
   $entry->parse_s($bib);
   is($entry->get('title'), NFD('Gödel'), 'NFD on request');
   is($entry->get(NFC('größe')), 'x', 'lookup with NFC key');

   # encoded (byte string) arguments still work, as code written for
   # older versions expects
   is($entry->get(encode('UTF-8', 'größe')), 'x', 'lookup with UTF-8 bytes');
}

# Invalid UTF-8 in a string to parse
{
   my @w;
   local $Text::BibTeX::Error::Handler = sub { push @w, shift };
   my $entry = Text::BibTeX::Entry->new("\@misc{k, title = {caf\xE9 \xFF}}");
   is($entry->get('title'), "caf\x{FFFD} \x{FFFD}", 'invalid bytes replaced');
   is(scalar(grep { $_->message =~ /invalid UTF-8/ } @w), 1, 'one warning per line');
}

is(Text::BibTeX::unicode_version(), Unicode::UCD::UnicodeVersion(),
   "tables match this perl's Unicode version")
   if require Unicode::UCD;

done_testing;
