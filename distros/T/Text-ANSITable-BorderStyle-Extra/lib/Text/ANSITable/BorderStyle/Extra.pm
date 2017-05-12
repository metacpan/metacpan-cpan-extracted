package Text::ANSITable::BorderStyle::Extra;

use 5.010001;
use strict;
use utf8;
use warnings;

our $VERSION = '0.03'; # VERSION

our %border_styles = (

    hdoubleh_dsingle => {
        summary => 'Horizontally-double for header, single for data',
        chars => [
            ['┌','─','┬','┐'], # 0
            ['│','│','│'],     # 1
            ['╞','═','╪','╡'], # 2
            ['│','│','│'],     # 3
            ['├','─','┼','┤'], # 4
            ['└','─','┴','┘'], # 5
        ],
        utf8 => 1,
    },

    hboldh_dsingle => {
        summary => 'Horizontally-bold for header, single for data',
        chars => [
            ['┌','─','┬','┐'], # 0
            ['│','│','│'],     # 1
            ['┝','━','┿','┥'], # 2
            ['│','│','│'],     # 3
            ['├','─','┼','┤'], # 4
            ['└','─','┴','┘'], # 5
        ],
        utf8 => 1,
    },

    # single dash

    dash2 => {
        summary => 'Dash 2',
        chars => [
            ['┌','╌','┬','┐'], # 0
            ['┆','╎','╎'],     # 1
            ['├','╌','┼','┤'], # 2
            ['╎','╎','╎'],     # 3
            ['├','╌','┼','┤'], # 4
            ['└','╌','┴','┘'], # 5
        ],
        utf8 => 1,
    },

    dash3 => {
        summary => 'Dash 3',
        chars => [
            ['┌','┄','┬','┐'], # 0
            ['┆','┆','┆'],     # 1
            ['├','┄','┼','┤'], # 2
            ['┆','┆','┆'],     # 3
            ['├','┄','┼','┤'], # 4
            ['└','┄','┴','┘'], # 5
        ],
        utf8 => 1,
    },

    # double dash

    # heavy dash

    # block, semiblock

    # shade (2591, 2592)

    # dot

);

# ABSTRACT: More border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::BorderStyle::Extra - More border styles

=head1 VERSION

This document describes version 0.03 of Text::ANSITable::BorderStyle::Extra (from Perl distribution Text-ANSITable-BorderStyle-Extra), released on 2014-12-13.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-ANSITable-BorderStyle-Extra>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Text-ANSITable-BorderStyle-Extra>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSITable-BorderStyle-Extra>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 INCLUDED BORDER STYLES

=head2 Extra::dash2

Dash 2 (utf8: yes, box_chars: no).

 ┌╌╌╌╌╌╌╌╌╌┬╌╌╌╌╌╌╌╌╌┐
 ┆ column1 ╎ column2 ╎
 ├╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
 ╎ row1.1  ╎ row1.2  ╎
 ╎ row2.1  ╎ row3.2  ╎
 ├╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
 ╎ row3.1  ╎ row3.2  ╎
 └╌╌╌╌╌╌╌╌╌┴╌╌╌╌╌╌╌╌╌┘


=head2 Extra::dash3

Dash 3 (utf8: yes, box_chars: no).

 ┌┄┄┄┄┄┄┄┄┄┬┄┄┄┄┄┄┄┄┄┐
 ┆ column1 ┆ column2 ┆
 ├┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┤
 ┆ row1.1  ┆ row1.2  ┆
 ┆ row2.1  ┆ row3.2  ┆
 ├┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┄┄┄┄┤
 ┆ row3.1  ┆ row3.2  ┆
 └┄┄┄┄┄┄┄┄┄┴┄┄┄┄┄┄┄┄┄┘


=head2 Extra::hboldh_dsingle

Horizontally-bold for header, single for data (utf8: yes, box_chars: no).

 ┌─────────┬─────────┐
 │ column1 │ column2 │
 ┝━━━━━━━━━┿━━━━━━━━━┥
 │ row1.1  │ row1.2  │
 │ row2.1  │ row3.2  │
 ├─────────┼─────────┤
 │ row3.1  │ row3.2  │
 └─────────┴─────────┘


=head2 Extra::hdoubleh_dsingle

Horizontally-double for header, single for data (utf8: yes, box_chars: no).

 ┌─────────┬─────────┐
 │ column1 │ column2 │
 ╞═════════╪═════════╡
 │ row1.1  │ row1.2  │
 │ row2.1  │ row3.2  │
 ├─────────┼─────────┤
 │ row3.1  │ row3.2  │
 └─────────┴─────────┘

=cut
