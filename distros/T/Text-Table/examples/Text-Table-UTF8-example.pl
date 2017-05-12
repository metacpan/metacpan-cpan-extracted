#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use Text::Table;

binmode STDOUT, ':utf8';

my @cols = qw/First Last Country/;
my $sep = \'│';

my $major_sep = \'║';
my $tb = Text::Table->new($sep,  " Number ", $major_sep,
    (map { +(" $_ ", $sep) } @cols)
);

my $num_cols = @cols;

$tb->load([1, "Mark", "Twain", "USA",]);
$tb->load([2, "Charles", "Dickens", "Britain",]);
$tb->load([3, "Jules", "Verne", "France",]);

my $make_rule = sub {
    my ($args) = @_;

    my $left = $args->{left};
    my $right = $args->{right};
    my $main_left = $args->{main_left};
    my $middle = $args->{middle};

    return $tb->rule(
        sub {
            my ($index, $len) = @_;

            return ('─' x $len);
        },
        sub {
            my ($index, $len) = @_;

            my $char =
            (     ($index == 0) ? $left
                : ($index == 1) ? $main_left
                : ($index == $num_cols+1) ? $right
                : $middle
            );

            return $char x $len;
        },
    );
};

my $start_rule = $make_rule->(
    {
        left => '┌',
        main_left => '╥',
        right => '┐',
        middle => '┬',
    }
);

my $mid_rule = $make_rule->(
    {
        left => '├',
        main_left => '╫',
        right => '┤',
        middle => '┼',
    }
);

my $end_rule = $make_rule->(
    {
        left => '└',
        main_left => '╨',
        right => '┘',
        middle => '┴',
    }
);


print $start_rule, $tb->title,
    (map { $mid_rule, $_, } $tb->body()), $end_rule;

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2012 by Shlomi Fish

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
