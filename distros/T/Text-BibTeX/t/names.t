# -*- cperl -*-
use strict;
use warnings;
use vars qw($DEBUG);

use IO::Handle;
use Test::More tests => 61;
use utf8;
use Encode 'encode';
use Text::BibTeX;

use Cwd;
my $common = getcwd()."/t/common.pl";
require $common;

$DEBUG = 0;

#setup_stderr;

sub test_name {
    my ($name, $parts) = @_;
    my $ok = 1;
    my @partnames = qw(first von last jr);
    my $i;

    for $i (0 .. $#partnames)  {
        if (defined $parts->[$i]) {
            $ok &= ($name->part ($partnames[$i]))
              && slist_equal ($parts->[$i], [$name->part ($partnames[$i])]);
        }
        else {
            $ok &= ! $name->part ($partnames[$i]);
        }
    }
    # Only 5 keys max: first, von, last, jr AND encoding, normalization
    ok(keys %$name <= 6 && $ok);
}


# ----------------------------------------------------------------------
# processing of author names

my (@names, @unames, @pnames, %names, @orig_namelist, $namelist, @namelist);
my ($text, $entry, $pentry, $uentry);

# first just a big ol' list of names, not attached to any entry
%names =
 ('van der Graaf'          => '|van+der|Graaf|',
  'Jones'                  => '||Jones|',
  'van'                    => '||van|',
  'John Smith'             => 'John||Smith|',
  'John van Smith'         => 'John|van|Smith|',
  'John van Smith Jr.'     => 'John|van|Smith+Jr.|',
  'John Smith Jr.'         => 'John+Smith||Jr.|',
  'John van'               => 'John||van|',
  'John van der'           => 'John|van|der|',
  'John van der Graaf'     => 'John|van+der|Graaf|',
  'John van der Graaf foo' => 'John|van+der|Graaf+foo|',
  'foo Foo foo'            => '|foo|Foo+foo|',
  'Foo foo'                => 'Foo||foo|',
  'foo Foo'                => '|foo|Foo|'
 );

@orig_namelist = keys %names;
$namelist = join (' and ', @orig_namelist);
@namelist = Text::BibTeX::split_list
   ($namelist, 'and', 'test', 0, 'name');
is_deeply(\@orig_namelist, \@namelist, "same lists...");

my $i;
foreach $i (0 .. $#namelist)
{
   is($namelist[$i], $orig_namelist[$i]);
   my %parts;
   Text::BibTeX::Name::_split (\%parts, $namelist[$i], 'test', 0, $i, 0);
   ok (keys %parts <= 4, "number keys is OK");

   my @name = map { join ('+', ref $_ ? @$_ : ()) }
     @parts{'first','von','last','jr'};
   is (join ('|', @name), $names{$orig_namelist[$i]});
}

# now an entry with some names in it

$text = <<'TEXT';
@article{homer97,
  author = {  Homer  Simpson    and
              Flanders, Jr.,    Ned Q. and
              {Foo  Bar and Co.}},
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  year = 1997
}
TEXT

my $protected_test = <<'PROT';
@article{prot1,
  author = {{U.S. Department of Health and Human Services, National Institute of Mental Health, National Heart, Lung and Blood Institute}}
}
PROT

my $uname = Text::BibTeX::Name->new({binmode => 'utf-8'},'фон дер Иванов, И. И.');
is (join('', $uname->part('last')), 'Иванов', "Testing unicode...");
is (join('', $uname->part('first')), 'И.И.');
is (join(' ', $uname->part('von')), 'фон дер');# 2-byte UTF-8 lowercase

$uname = Text::BibTeX::Name->new({binmode => 'utf-8'},'ꝥaa Smith, John');
is (join('', $uname->part('von')), 'ꝥaa');# 3-byte UTF-8 lowercase (U+A765)
$uname = Text::BibTeX::Name->new({binmode => 'utf-8'},'𝓺aa Smith, John');
is (join('', $uname->part('von')), '𝓺aa');# 4-byte UTF-8 lowercase (U+1D4FA)

$uname = Text::BibTeX::Name->new({binmode => 'raw'},'𝓺aa Smith, John');
is (join('', $uname->part('von')), encode('UTF-8','𝓺aa'), "check raw mode");# 4-byte UTF-8 lowercase (U+1D4FA)


ok ($pentry = Text::BibTeX::Entry->new($protected_test), "Got an Entry");
my $pauthor = $pentry->get ('author');
is ($pauthor, '{U.S. Department of Health and Human Services, National Institute of Mental Health, National Heart, Lung and Blood Institute}', "Protected test author is correct");
@pnames = $pentry->split ('author');
ok (@pnames == 1 && $pnames[0] eq '{U.S. Department of Health and Human Services, National Institute of Mental Health, National Heart, Lung and Blood Institute}');
@pnames = $pentry->names ('author');
ok (@pnames == 1);
test_name ($pnames[0], [undef, undef, ['{U.S. Department of Health and Human Services, National Institute of Mental Health, National Heart, Lung and Blood Institute}'], undef]);


ok ($entry = Text::BibTeX::Entry->new($text));
my $author = $entry->get ('author');
is ($author, 'Homer Simpson and Flanders, Jr., Ned Q. and {Foo Bar and Co.}');
@names = $entry->split ('author');
ok (@names == 3 &&
    $names[0] eq 'Homer Simpson' &&
    $names[1] eq 'Flanders, Jr., Ned Q.' &&
    $names[2] eq '{Foo Bar and Co.}');
@names = $entry->names ('author');
ok (@names == 3);
test_name ($names[0], [['Homer'], undef, ['Simpson'], undef]);
test_name ($names[1], [['Ned', 'Q.'], undef, ['Flanders'], ['Jr.']]);
test_name ($names[2], [undef, undef, ['{Foo Bar and Co.}']]);
