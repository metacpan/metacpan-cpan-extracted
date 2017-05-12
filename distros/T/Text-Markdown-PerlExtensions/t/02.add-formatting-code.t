#!perl

use strict;
use warnings;

use Text::Markdown::PerlExtensions qw(markdown add_formatting_code);
use Test::More;

my @TESTS =
(

    {
        title => 'Simple italic text',
        in    => 'Use I<italic> for I<emphasis>.',
        out   => '<p>Use <I>italic</I> for <I>emphasis</I>.</p>',
    },

    {
        title => 'Simple bold text',
        in    => 'Use B<bold> for B<strength>.',
        out   => '<p>Use <B>bold</B> for <B>strength</B>.</p>',
    },

    {
        title => 'Italic and bold text',
        in    => 'Use B<bold> and I<italic>.',
        out   => '<p>Use <B>bold</B> and <I>italic</I>.</p>',
    },

    {
        title => 'Nested bold and italic',
        in    => 'Use both B<I<italic> and I<bold>>.',
        out   => '<p>Use both <B><I>italic</I> and <I>bold</I></B>.</p>',
    },

);

sub italic { return "<I>$_[0]</I>"; }
sub bold   { return "<B>$_[0]</B>"; }

add_formatting_code('I', \&italic);
add_formatting_code('B', \&bold);

foreach my $test (@TESTS) {
    my $in       = $test->{in};
    my $expected = $test->{out};
    my $out      = markdown($in);

    $out =~ s/^\s+|\s+$//;
    is($out, $expected, 'Functional: '.$test->{title});
}

my $formatter = Text::Markdown::PerlExtensions->new();
$formatter->add_formatting_code('I', \&italic);
$formatter->add_formatting_code('B', \&bold);

foreach my $test (@TESTS) {
    my $in       = $test->{in};
    my $expected = $test->{out};
    my $out      = $formatter->markdown($in);

    $out =~ s/^\s+|\s+$//;
    is($out, $expected, 'OO: '.$test->{title});
}

done_testing();
