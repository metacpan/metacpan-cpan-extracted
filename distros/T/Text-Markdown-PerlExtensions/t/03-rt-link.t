#!perl

use strict;
use warnings;

use Text::Markdown::PerlExtensions qw(markdown);
use Test::More;

my @TESTS =
(

    {
        title => 'Link to RT issue',
        in    => 'Fix RT#1234.',
        out   => '<p>Fix <a href="https://rt.cpan.org/Public/Bug/Display.html?id=1234">RT#1234</a>.</p>',
    },

);

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
