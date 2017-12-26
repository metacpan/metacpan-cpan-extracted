use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 92;

diag "Constructor";

my $testfile = catfile(t => testfiles =>  'prova.muse');
my $muse = Text::Amuse::Document->new(file => $testfile, debug => 1);

is($muse->filename, $testfile, "filename ok");
my @expected = (
                "#title 1 2 3 4\n",
                "#author hello\n",
                "\n",
                "This    is a test\n",
                "This    is a test\n",
               );

is_deeply [$muse->raw_body],
  ["This    is a test\n", "This    is a test\n", "\n" ],
  "body ok";

is_deeply {$muse->raw_header},
  { title => "1 2 3 4", author => "hello" },
  "header ok";

is(scalar $muse->elements, 3, "Found three elements");
# diag "Testing if I can call rawline, block, type, string, ";
# diag "removed, indentation on each element";
foreach my $el ($muse->elements) {
    ok defined($el->rawline), "el: " . $el->rawline;
    ok defined($el->block),   "el: " . $el->block;
    ok defined($el->type),    "el: " . $el->type;
    ok defined($el->string),  "el: " . $el->string;
    ok defined($el->removed), "el: " . $el->removed;
    ok defined($el->indentation), "el: " . $el->indentation;
}

my $example =
  Text::Amuse::Document->new(file => catfile(t => testfiles => 'example.muse'));

my @parsed = grep { $_->type ne 'null' } $example->elements;
is scalar(@parsed), 2, "Two blocks";

is($parsed[0]->type, "example", "Type set to example");
is($parsed[1]->type, "example", "Type set to example") or die Dumper(\@parsed);

$example = Text::Amuse::Document->new(file => catfile(t => testfiles => 'example-2.muse'));

@parsed = grep { $_->type ne 'null' } $example->elements;
is(scalar @parsed, 2, "Two element, <example> wasn't closed");

is($parsed[0]->type, "example", "Type set to example");
is($parsed[1]->type, "example", "Type set to example") or die Dumper(\@parsed);

# we have to add a "\n" at the end, because it's inserted automatically
my $expected_example = <<'EOF';

      1, 2, 3

           Test [2]

[2] Not a footnote



EOF

is($parsed[1]->string, $expected_example, "Content looks ok");

# dump_content($example);

my $poetry = Text::Amuse::Document->new(file => testfile("verse.muse"),
                              debug => 1);

@parsed = grep { $_->type ne 'null' } $poetry->elements;
is($parsed[1]->type, "verse", "verse ok");
is($parsed[1]->string,
   "A line of Emacs verse;\n  forgive its being so terse.\n",
   "content looks ok");
is($parsed[2]->type, "h2", "h2 ok");

is($parsed[3]->type, "regular");
is($parsed[4]->type, "verse", "another verse");
my $exppoetry = <<'EOF';
A line of Emacs verse; [2]
  forgive its being so terse. [3]

In terms of terse verse,
        you could do worse. [1]

 A. This poetry will stop here.
EOF

is($parsed[4]->string, $exppoetry, "content ok, list not interpreted");
is_deeply([split /(\s+)/, $parsed[4]->string],
          [split /(\s+)/, $exppoetry]);
is scalar(@parsed), 5, "End of parsed";
foreach my $fn (1..3) {
    my $footnote = $poetry->get_footnote('[' . $fn . ']');
    chomp $footnote;
    ok ($footnote, "Found footnote $fn: " . $footnote->string) or die "Missing footnote!";
}
is ($poetry->get_footnote('[1]')->string, "The author\n", "Footnote 1 ok");
is ($poetry->get_footnote('[2]')->string, "Another author\n", "Footnote 2 ok");
is ($poetry->get_footnote('[3]')->string, "This sucks\n", "Footnote 3 ok");

my $packs = Text::Amuse::Document->new(file => catfile(t => testfiles => 'packing.muse'));
@parsed = grep { $_->type ne 'null' } $packs->elements;

is($parsed[0]->string, "this title\nwill merge\n");
is($parsed[0]->type, "h1");

is($parsed[1]->string, "this title\nwill merge\n");
is($parsed[1]->type, "h2");

is($parsed[2]->string, "this title\nwill merge\n");
is($parsed[2]->type, "h3");

is($parsed[3]->string, "this title\nwill merge\n");
is($parsed[3]->type, "h4");

is($parsed[4]->string, "this title\nwill merge\n");
is($parsed[4]->type, "h5");

is($parsed[5]->type, 'startblock');
is($parsed[5]->block, 'play');

is($parsed[6]->string, "This will not merge (of course)\n");
is($parsed[6]->type, "regular");

is($parsed[7]->type, 'stopblock');
is($parsed[7]->block, 'play');


is($parsed[8]->string, "we continue without merging (ugly but valid)\n");
is($parsed[8]->type, "regular");

is($parsed[9]->string, "Verse will not merge (of course)\n");
is($parsed[9]->type, "verse");

is($parsed[10]->string, "and we continue without merging (ugly but valid) [1]\n");
is($parsed[10]->type, "regular");

is($parsed[11]->string, "nor the example\n");
is($parsed[11]->type, "example");

is($parsed[12]->string, "will not merge\n");
is($parsed[12]->type, "regular");

is($parsed[13]->string, " the | table\n will | merge\n");
is($parsed[13]->type, "table");

is($parsed[14]->block, 'center');
is($parsed[15]->string, "but not with a regular\n");

is($parsed[16]->block, "center");
is($parsed[16]->type, "stopblock");

is($parsed[17]->block, "ul");
is($parsed[18]->block, "li");
is($parsed[19]->string, "the list\nwill merge\n");

is($parsed[20]->block, "ola");
is($parsed[21]->block, "li");
is($parsed[22]->string, "the list\nwill merge\n");
is($parsed[23]->block, "li");
is($parsed[23]->type, "stopblock");
is($parsed[24]->block, "ola");
is($parsed[24]->type, "stopblock");
is($parsed[25]->block, "li");
is($parsed[25]->type, "stopblock");
is($parsed[26]->block, "ul");
is($parsed[26]->type, "stopblock");

is($parsed[27]->block, "inlinecomment");
is($parsed[28]->type, "regular");
is scalar(@parsed), 29;

sub testfile {
    return catfile(t => testfiles => shift);
}
