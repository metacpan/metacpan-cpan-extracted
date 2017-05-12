# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $loaded;

BEGIN { $| = 1; print "1..13\n"; $^W = 1 }
END { print "not ok 1\n" unless $loaded; }
use YAPE::Regex;
use strict;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $i = 2;

until (eof DATA) {
  my ($input,$expected,$code) = getData();
  my $output;
  
  eval $code;
  warn $@ if $@;

  print "not " if $output ne $expected;
  print "ok ", $i++, "\n";
  print "  {$output}\n  {$expected}\n" if $output ne $expected;
}


sub getData {
  my ($in,$out,$code);
  local $/;

  $/ = "\n";
  <DATA>;  # just for information
  
  $/ = "\n__EOI__\n";
  chomp ($in = <DATA>);

  $/ = "\n__EOO__\n";
  chomp ($out = <DATA>);
  
  $/ = "__EOC__\n\n";
  chomp ($code = <DATA>);

  return ($in,$out,$code);
}


__DATA__
# TEST 2 -- simple regex handling
[aeiou][^aeiou]+[aeiou]
__EOI__
(?-imsx:[aeiou][^aeiou]+[aeiou])
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 3 -- medium regex handling
[aeiou]([^aeiou]+[aeiou])\1+
__EOI__
(?-imsx:[aeiou]([^aeiou]+[aeiou])\1+)
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 4 -- difficult regex handling
(?sm:((?<=foo)|(?=ae|io|u))?(?(1)bar|\x20{4,6}))
__EOI__
(?-imsx:(?ms:((?<=foo)|(?=ae|io|u))?(?(1)bar|\x20{4,6})))
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 5 -- range mistake
a{9,5}
__EOI__
upper bound lower than lower bound ({9,5})
__EOO__
my $parser = YAPE::Regex->new($input);
$parser->parse;
$output = $parser->error;
__EOC__

# TEST 6 -- nested ++
a++
__EOI__
unexpected token '+' during 'text'
__EOO__
my $parser = YAPE::Regex->new($input);
$parser->parse;
$output = $parser->error;
__EOC__

# TEST 7 -- (?{ ... }) and (??{ ... })
this (?{ $x++ }) (??{ $y-- }) that
__EOI__
(?-imsx:this (?{ $x++ }) (??{ $y-- }) that)
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 8 -- (?(?=...)...)
foo (?(?=bar)b)
__EOI__
(?-imsx:foo (?(?=bar)b))
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 9 -- (?(?!...)...)
foo (?(?!bar)b)
__EOI__
(?-imsx:foo (?(?!bar)b))
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 10 -- (?(?<=...)...)
foo (?(?<=bar)b)
__EOI__
(?-imsx:foo (?(?<=bar)b))
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 11 -- (?(?<!...)...)
foo (?(?<!bar)b)
__EOI__
(?-imsx:foo (?(?<!bar)b))
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 12 -- (?(?{...})...)
foo (?(?{bar})b)
__EOI__
(?-imsx:foo (?(?{bar})b))
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

# TEST 13 -- (?(??{...})...)
foo (?(??{bar})b)
__EOI__
(?-imsx:foo (?(??{bar})b))
__EOO__
my $parser = YAPE::Regex->new($input);
$output = $parser->display;
__EOC__

