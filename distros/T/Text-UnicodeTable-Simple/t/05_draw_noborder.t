use strict;
use warnings;

use Test::More;
use Text::UnicodeTable::Simple;

{
    my $t = Text::UnicodeTable::Simple->new( border => 0 );
    $t->set_header(qw/a/);

    my $expected = " a \n";

    is($t->draw, $expected, 'only header');
    is("$t", $expected, 'overload stringify');
}

{
    my $t = Text::UnicodeTable::Simple->new( border => 0 );
    $t->set_header(qw/a b/);
    $t->add_row(qw/aaa bbbb/);

    my $expected = join "\n"
                   , " a    b    "
                   , " aaa  bbbb " . "\n";

    is($t->draw, $expected, 'header and row');
}

{
    my $t = Text::UnicodeTable::Simple->new( border => 0 );
    $t->set_header(qw/1 2/);
    $t->add_row(qw/aaa bbbb/);
    $t->add_row(qw/4 12345/);

    my $expected = join "\n"
                   , "   1      2 "
                   , " aaa  bbbb  "
                   , "   4  12345 ". "\n";

    is($t->draw, $expected, 'alignment');
}

{
    my $t = Text::UnicodeTable::Simple->new( border => 0 );
    $t->set_header(qw/1 2/);
    $t->add_row(qw/a b/);
    $t->add_row_line();
    $t->add_row(qw/c d/);

    my $expected = join "\n"
                   , " 1  2 "
                   , " a  b "
                   , ""
                   , " c  d " . "\n";

    is($t->draw, $expected, 'add_row_line');
}

{
    use utf8;

    my $t = Text::UnicodeTable::Simple->new( border => 0 );
    $t->set_header(qw/a b/);
    $t->add_row(qw/あいうえお やゆよ/);

    my $expected = join "\n"
                   , " a           b      "
                   , " あいうえお  やゆよ " . "\n";

    is($t->draw, $expected, 'full width font');
}

{
    my $t = Text::UnicodeTable::Simple->new( border => 0 );
    $t->set_header("a\n123\ncdefg", "12\nabcd\n5");
    $t->add_row("1234\nabc", "abcde\n56");

    my $expected = join "\n"
                   , " a         12 "
                   , " 123     abcd "
                   , " cdefg      5 "
                   , "  1234  abcde "
                   , "   abc  56    " . "\n";

    is($t->draw, $expected, 'multiline');
}

done_testing;
