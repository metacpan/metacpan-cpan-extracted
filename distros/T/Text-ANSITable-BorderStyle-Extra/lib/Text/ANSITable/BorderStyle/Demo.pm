package Text::ANSITable::BorderStyle::Demo;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03'; # VERSION

our %border_styles = (

    demo_custom_char => {
        summary => 'Demoes coderef in chars',
        description => <<'_',

Accept arguments C<char> (defaults to C<x>).

_
        chars => sub {
            my ($self, %args) = @_;
            ($self->{border_style_args}{char} // "x") x ($args{n} // 1);
        },
    },

);

1;
# ABSTRACT: Demo border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::BorderStyle::Demo - Demo border styles

=head1 VERSION

This document describes version 0.03 of Text::ANSITable::BorderStyle::Demo (from Perl distribution Text-ANSITable-BorderStyle-Extra), released on 2014-12-13.

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

=head2 Demo::demo_custom_char

Demoes coderef in chars (utf8: no, box_chars: no).


Accept arguments C<char> (defaults to C<x>).



 xxxxxxxxxxxxxxxxxxxxx
 x column1 x column2 x
 xxxxxxxxxxxxxxxxxxxxx
 x row1.1  x row1.2  x
 x row2.1  x row3.2  x
 xxxxxxxxxxxxxxxxxxxxx
 x row3.1  x row3.2  x
 xxxxxxxxxxxxxxxxxxxxx

=cut
