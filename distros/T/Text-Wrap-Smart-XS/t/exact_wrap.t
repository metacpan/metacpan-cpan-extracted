#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2 * 2;
use Text::Wrap::Smart::XS qw(exact_wrap);

my $join = sub { local $_ = shift; chomp; s/\n/ /g; $_ };

my $text = $join->(<<'EOT');
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Curabitur vel diam nec nisi pellentesque gravida a sit amet
metus. Fusce non volutpat arcu. Lorem ipsum dolor sit amet,
consectetur adipiscing elit. Donec euismod, dolor eget placerat
euismod, massa risus ultricies metus, id commodo cras amet.
EOT

my @expected = (
    [ $join->(<<'EOT'),
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Curabitur vel diam nec nisi pellentesque gravida a sit amet
metus. Fusce non volutpat arcu. L
EOT
    , $join->(<<'EOT'),
orem ipsum dolor sit amet, consectetur adipiscing elit. Donec
euismod, dolor eget placerat euismod, massa risus ultricies
metus, id commodo cras amet.
EOT
    ],
    [ 'Lorem ipsum dolor sit amet, co',
      'nsectetur adipiscing elit. Cur',
      'abitur vel diam nec nisi pelle',
      'ntesque gravida a sit amet met',
      'us. Fusce non volutpat arcu. L',
      'orem ipsum dolor sit amet, con',
      'sectetur adipiscing elit. Done',
      'c euismod, dolor eget placerat',
      ' euismod, massa risus ultricie',
      's metus, id commodo cras amet.', ],
);

my @entries = (
    [ $text, $expected[0],  2,  0 ],
    [ $text, $expected[1], 10, 30 ],
);

foreach my $entry (@entries) {
    test_wrap(@$entry);
}

sub test_wrap
{
    my ($text, $expected, $count, $wrap_at) = @_;

    my @strings = exact_wrap($text, $wrap_at);

    my $length = $wrap_at ? $wrap_at : 'default';
    my $message = "(wrapping length: $length) [ordinary]";

    is(@strings, $count, "$message amount of substrings");
    is_deeply(\@strings, $expected, "$message splitted at offset");
}
