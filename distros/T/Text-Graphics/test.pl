##
## Text::Graphics test procedure derived from test.pl in Text::Wrapper
## package, which is Copyright 1998 Christopher J. Madsen
##
# xId: test.pl 0.2 1998/05/14 22:24:03 Madsen Exp x

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::Graphics;
$loaded = 1;
$generate = (@ARGV and $ARGV[0] eq 'print');
print "ok 1\n" unless $generate;

######################### End of black magic.
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $text = "A text graphics rendering toolkit.\n";
my $page = Text::Graphics::Page->new( 20, 10);
my $panel0 = Text::Graphics::BorderedPanel->new( 20, 10);
my $panel1 = Text::Graphics::FilledBorderedTextPanel->new($text x 3, 25, 12);
$panel0->setBackground("#");
$panel1->setBackground(" ");
$page->add($panel0);
$page->add($panel1, 5, 2);
my $buffer;
$page->render(\ $buffer);



my $we_want = qq^+-------------------+
|###################|
|####+--------------+
|####|A text graphic|
|####|rendering tool|
|####|text graphics |
|####|toolkit. A tex|
|####|graphics rende|
|####|toolkit.      |
|####|              |
+----+--------------+
^;

($we_want ne $buffer) and print "not";
print "ok 2\n";

