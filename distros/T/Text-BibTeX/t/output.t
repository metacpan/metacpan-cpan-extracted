# -*- cperl -*-
use strict;
use warnings;

use IO::Handle;
use Test::More tests => 20;

use vars qw($DEBUG);

use Cwd;
BEGIN {
  use_ok('Text::BibTeX');
  my $common = getcwd()."/t/common.pl";
  require $common;
}

use Fcntl;

# ----------------------------------------------------------------------
# entry output methods

my ($text, $entry, @warnings, @fields);
my ($new_text, $new_entry);

$text = <<'TEXT';
@article{homer97,
  author = "H{\"o}mer Simpson" # { \"und } # "Ned Flanders",
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  year = 1997
}
TEXT
ok($entry = Text::BibTeX::Entry->new($text), "new entry is defined");
ok($entry->parse_ok, "new entry parsed correctly");

$new_text = $entry->print_s;

like $new_text => qr/^\@article\{homer97,\s*$/m, 'we have type and key';
like $new_text =>
    qr/^\s*author\s*=\s*\{H\{\\"o\}mer Simpson \\"und Ned Flanders\},\s*$/m,
    'we have author';
like $new_text => qr/^\s*title\s*=\s*[{"]Territorial[^}"]*Suburbia[}"],\s*$/m,
    'we have title';
like $new_text => qr/^\s*journal\s*=\s*[{"]Journal[^\}]*Studies[}"],\s*$/m,
    'we have journal';
like $new_text => qr/^\s*year\s*=\s*[{"]1997[}"],\s*$/m, 'we have year'
;

$new_entry = Text::BibTeX::Entry->new($new_text);
ok($entry->parse_ok, "second entry parsed correctly");

is $entry->type => $new_entry->type, "entry type is correct";
is $entry->key  => $new_entry->key,  "entry key is correct";

ok(slist_equal ([sort $entry->fieldlist], [sort $new_entry->fieldlist]), "same field list");

@fields = $entry->fieldlist;
ok(slist_equal ([$entry->get (@fields)], [$new_entry->get (@fields)]));

my @test = map { "t/test$_.bib" } 1..3;
my ($bib);

END { unlink @test }

open (BIB, ">$test[0]") || die "couldn't create $test[0]: $!\n";
$entry->print (\*BIB);
close (BIB);

$bib = IO::File->new($test[1], O_CREAT|O_WRONLY)
   or die "couldn't create $test[1]: $!\n";
$entry->print ($bib);
$bib->close;

$bib = Text::BibTeX::File->new($test[2], {MODE => O_CREAT|O_WRONLY})
   or die "couldn't create $test[2]: $!\n";
$entry->write ($bib);
$bib->close;

my (@contents, $i);
for $i (0 .. 2)
{
   open (BIB, $test[$i]) || die "couldn't open $test[$i]: $!\n";
   $contents[$i] = join ('', <BIB>);
   close (BIB);
}

is $new_text => $contents[0], "Contents [0]";
is $new_text => $contents[1], "Contents [1]";
is $new_text => $contents[2], "Contents [2]";

my $clone = $entry->clone;
is ref($clone) => 'Text::BibTeX::Entry';
is $clone->get('title') => 'Territorial Imperatives in Modern Suburbia';
$clone->set('title', 'Changed title');
is $clone->get('title') => 'Changed title';
is $entry->get('title') => 'Territorial Imperatives in Modern Suburbia';
