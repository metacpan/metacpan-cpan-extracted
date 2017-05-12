# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $loaded;

BEGIN { $| = 1; print "1..49\n"; }
END {print "not ok 1\n" unless $loaded;}
use YAPE::HTML;
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
# TEST 2 -- no tag display
<b><i><u>Content</u></i></b>
__EOI__
Content
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->display(0);
__EOC__

# TEST 3 -- one level of tag display
<b><i><u>Content</u></i></b>
__EOI__
<b>Content</b>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->display(1);
__EOC__

# TEST 4 -- 2 levels of tag display
<b><i><u>Content</u></i></b>
__EOI__
<b><i>Content</i></b>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->display(2);
__EOC__

# TEST 5 -- 3 levels of tag display
<b><i><u>Content</u></i></b>
__EOI__
<b><i><u>Content</u></i></b>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->display(3);
__EOC__

# TEST 6 -- complete tag display
<b><i><u>Content</u></i></b>
__EOI__
<b><i><u>Content</u></i></b>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->display;
__EOC__

# TEST 7 -- tag display w/o <i> tags
<b><i><u>Content</u></i></b>
__EOI__
<b><u>Content</u></b>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->display(['i']);
__EOC__

# TEST 8 -- 2 levels of tag display w/o <b> tags
<b><i><u>Content</u></i></b>
__EOI__
<i>Content</i>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->display(['b'],2);
__EOC__

# TEST 9 -- complete content output via root()
<HTML>
<head>
<TItle>Sample Page</tiTLE>
</head>
<body bgcolor='#ffffff' TEXT="#0000ff">
<p>Content</p>
</body>
</html>
__EOI__
<html>
<head>
<title>Sample Page</title>
</head>
<body bgcolor="#ffffff" text="#0000ff">
<p>Content</p>
</body>
</html>
__EOO__
my $parser = YAPE::HTML->new($input);
$parser->parse;
$output = $parser->root->[0]->fullstring;
__EOC__

# TEST 10 -- complete content output via top()
<HTML>
<head>
<TItle>Sample Page</tiTLE>
</head>
<body bgcolor='#ffffff' TEXT="#0000ff">
<p>Content</p>
</body>
</html>
__EOI__
<html>
<head>
<title>Sample Page</title>
</head>
<body bgcolor="#ffffff" text="#0000ff">
<p>Content</p>
</body>
</html>
__EOO__
my $parser = YAPE::HTML->new($input);
$parser->parse;
$output = $parser->top->fullstring;
__EOC__

# TEST 11 -- empty tag
<b>Some<p />Content</b>
__EOI__
<p />
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->extract(p => [])->()->fullstring;
__EOC__

# TEST 12 -- empty tag under strict
<b>Some<p />Content</b>
__EOI__
<p />
__EOO__
my $parser = YAPE::HTML->new($input,1);
$output = $parser->extract(p => [])->()->fullstring;
__EOC__

# TEST 13 -- automatic tag closure
<b>Some<i>Content</b>
__EOI__
<i>Content</i>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->extract(i => [])->()->fullstring;
__EOC__

# TEST 14 -- tag not closed, caught under strict
<b>Some<i>Content</b>
__EOI__
wanted '</i>', found '</b>'
__EOO__
my $parser = YAPE::HTML->new($input,1);
$parser->parse;
$output = $parser->error;
__EOC__

# TEST 15 -- tag never closed, caught under strict
<b>Content
__EOI__
'<b>' never closed
__EOO__
my $parser = YAPE::HTML->new($input,1);
$parser->parse;
$output = $parser->error;
__EOC__

# TEST 16 -- tag never closed, automatically done
<b>Content
__EOI__
<b>Content</b>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->extract(b => [])->()->fullstring;
__EOC__

# TEST 17 -- extract <H1>, <H2>, ... tags
<h1>This</h1>
<h2>That</h2>
<hr>
<h3>Those</h3>
__EOI__
<h1>This</h1><h2>That</h2><h3>Those</h3>
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(qr/^h\d$/ => []);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 18 -- extract <H...> tags other than <H1>, <H2>, ...
<h1>This</h1>
<h2>That</h2>
<hr>
<h3>Those</h3>
__EOI__
<hr>
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(qr/^h\D$/ => []);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 19 -- <Hn> tags with 'align' an attribute
<h1>This</h1>
<h2 align="right">That</h2>
<hr>
<h3 align="center">Those</h3>
__EOI__
<h2 align="right">That</h2><h3 align="center">Those</h3>
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(qr/^h\d/ => ['align']);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 20 -- extracting all text
<h1>This</h1>
<h2 align="right">That</h2>
<hr>
<h3 align="center">Those</h3>
__EOI__
ThisThose
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(-TEXT => ['s']);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 21 -- extracting all tags
<h1>This</h1>
<h2 align="right">That</h2>
Extraneous
<h3 align="center">Those</h3>
__EOI__
<h1>This</h1><h2 align="right">That</h2><h3 align="center">Those</h3>
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(-TAG => []);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 22 -- extracting all comments
<h1>This</h1>
<h2 align="right">That</h2>
<!-- Extraneous -->
<h3 align="center">Those</h3>
__EOI__
<!-- Extraneous -->
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(-COMMENT => []);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 23 -- extracting all comments and text
This
<!-- Over-rated -->
<h2 align="right">That</h2>
<!-- Extraneous -->
<h3 align="center">Those</h3>
<!-- Spare -->
These
__EOI__
This
<!-- Over-rated -->
That
<!-- Extraneous -->
Those

These
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(-COMMENT => [qr/[Ou]/], -TEXT => []);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 24 -- extracting all comments and tags
This
<h2 align="right">That</h2>
<!-- Extraneous -->
<h3 align="center">Those</h3>
__EOI__
<h2 align="right">That</h2><!-- Extraneous --><h3 align="center">Those</h3>
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(-COMMENT => [], -TAG => []);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 25 -- extracting all comments and <H2> tags
This
<h2 align="right">That</h2>
<!-- Extraneous -->
<h3 align="center">Those</h3>
__EOI__
<h2 align="right">That</h2><!-- Extraneous -->
__EOO__
my $parser = YAPE::HTML->new($input);
my $extor = $parser->extract(-COMMENT => [], h2 => []);
while (my $tag = $extor->()) { $output .= $tag->fullstring }
__EOC__

# TEST 26 -- intercepting text, whitespace included
This < That < Those
<h2 align="right">That</h2>
<!-- Extraneous -->

<h3 align="center">Those</h3>
__EOI__
5
__EOO__
my $parser = YAPE::HTML->new($input);
while (my $chunk = $parser->next) {
  $output++ if $chunk->type eq 'text';
}
__EOC__

# TEST 27 -- intercepting text, whitespace excluded
This < That < Those
<h2 align="right">That</h2>
<!-- Extraneous -->

<h3 align="center">Those</h3>
__EOI__
3
__EOO__
my $parser = YAPE::HTML->new($input);
while (my $chunk = $parser->next) {
  $output++ if $chunk->type eq 'text' and $chunk->text =~ /\S/;
}
__EOC__

# TEST 28 -- intercepting open tags
This < That < Those
<h2 align="right">That</h2>
<!-- Extraneous -->

<h3 align="center">Those</h3>
__EOI__
2
__EOO__
my $parser = YAPE::HTML->new($input);
while (my $chunk = $parser->next) {
  $output++ if $chunk->type eq 'tag';
}
__EOC__

# TEST 29 -- intercepting all tags
This < That < Those
<h2 align="right">That</h2>
<!-- Extraneous -->

<h3 align="center">Those</h3>
__EOI__
4
__EOO__
my $parser = YAPE::HTML->new($input);
while (my $chunk = $parser->next) {
  $output++ if $chunk->type =~ 'tag';
}
__EOC__

# TEST 30 -- DTD handler
<!DOCTYPE WHAT GOES "HERE" "PLEASE">
This < That < Those
<h2 align="right">That</h2>
<!-- Extraneous -->

<h3 align="center">Those</h3>
__EOI__
<!DOCTYPE WHAT GOES "HERE" "PLEASE">
This < That < Those
<h2 align="right">That</h2>
<!-- Extraneous -->

<h3 align="center">Those</h3>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->display;
__EOC__

# TEST 31 -- quoting 1
100
__EOI__
100
__EOO__
$output = YAPE::HTML::quote($input);
__EOC__

# TEST 32 -- quoting 2
100.2
__EOI__
"100.2"
__EOO__
$output = YAPE::HTML::quote($input);
__EOC__

# TEST 33 -- quoting 3
"that's cool"
__EOI__
"&quot;that's cool&quot;"
__EOO__
$output = YAPE::HTML::quote($input);
__EOC__

# TEST 34 -- new tag automatically closed
<b>Some<NEW>Content</b>
__EOI__
<new>Content</new>
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->extract(new => [])->()->fullstring;
__EOC__

# TEST 35 -- new tag allowed to hang
<b>Some<NEW>Content</b>
__EOI__
<new>Content
__EOO__
my $parser = YAPE::HTML->new($input,1);
YAPE::HTML::OPEN('NEW');
$output = $parser->extract(new => [])->()->fullstring;
delete $YAPE::HTML::OPEN{NEW};
__EOC__

# TEST 36 -- new tag made empty
<b>Some<NEW>Content</b>
__EOI__
<new>
__EOO__
my $parser = YAPE::HTML->new($input,1);
YAPE::HTML::EMPTY('NEW');
$output = $parser->extract(new => [])->()->fullstring;
delete $YAPE::HTML::EMPTY{NEW};
__EOC__

# TEST 37 -- empty tag closing tag found, error thrown
<b>Some<NEW>Content</NEW></b>
__EOI__
wanted '</b>', found '</new>'
__EOO__
my $parser = YAPE::HTML->new($input,1);
YAPE::HTML::EMPTY('NEW');
$parser->parse;
$output = $parser->error;
delete $YAPE::HTML::EMPTY{NEW};
__EOC__

# TEST 38 -- un-strict comment
Here's a <!-- bad -- comment --> oops
__EOI__
<!-- bad -- comment -->
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->extract(-COMMENT => [])->()->fullstring;
__EOC__

# TEST 39 -- un-strict comment, under strict
Here's a <!-- bad -- comment --> oops
__EOI__
malformed comment
__EOO__
my $parser = YAPE::HTML->new($input,1);
$parser->parse;
$output = $parser->error;
__EOC__

# TEST 40 -- strict comment
Here's a <!-- a -- good --> comment --> yay!
__EOI__
<!-- a -- good -->
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->extract(-COMMENT => [])->()->fullstring;
__EOC__

# TEST 41 -- strict comment, under strict
Here's a <!-- a -- good --> comment --> yay!
__EOI__
<!-- a -- good --> comment -->
__EOO__
my $parser = YAPE::HTML->new($input,1);
$output = $parser->extract(-COMMENT => [])->()->fullstring;
__EOC__

# TEST 42 -- strict comment pathological case #1
valid <!---- > valid
__EOI__

__EOO__
my $parser = YAPE::HTML->new($input,1);
$output = $parser->extract(-COMMENT => [])->()->text;
__EOC__

# TEST 43 -- strict comment pathological case #2
valid <!----> valid
__EOI__

__EOO__
my $parser = YAPE::HTML->new($input,1);
$output = $parser->extract(-COMMENT => [])->()->text;
__EOC__

# TEST 44 -- strict comment pathological case #3
valid <!--------> valid
__EOI__
----
__EOO__
my $parser = YAPE::HTML->new($input,1);
$output = $parser->extract(-COMMENT => [])->()->text;
__EOC__

# TEST 45 -- strict comment pathological case #4
valid <!------>--> valid
__EOI__
---->
__EOO__
my $parser = YAPE::HTML->new($input,1);
$output = $parser->extract(-COMMENT => [])->()->text;
__EOC__

# TEST 46 -- SSI test #1
<!--#exec cmd="rm -rf /"-->
__EOI__
<!--#exec cmd="rm -rf /"-->
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->extract(-SSI => [])->()->string;
__EOC__

# TEST 47 -- SSI test #2
<!--# exec cmd="rm -rf /"-->
__EOI__
<!--#exec cmd="rm -rf /"-->
__EOO__
my $parser = YAPE::HTML->new($input);
$output = $parser->extract(-SSI => [])->()->string;
__EOC__

# TEST 48 -- SSI test #3
<!--#exec do="rm -rf /"-->
__EOI__
unknown SSI attribute 'do' for 'exec'
__EOO__
my $parser = YAPE::HTML->new($input);
$parser->parse;
$output = $parser->error;
__EOC__

# TEST 49 -- SSI test #4
<!--#unknown cmd="rm -rf /"-->
__EOI__
unknown SSI command 'unknown'
__EOO__
my $parser = YAPE::HTML->new($input);
$parser->parse;
$output = $parser->error;
__EOC__

