package Text::Table::Tiny::_ModuleFeatures;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-06'; # DATE
our $DIST = 'Text-Table-Tiny-_ModuleFeatures'; # DIST
our $VERSION = '0.002'; # VERSION

#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

our %FEATURES = (
    module_v => "1.02",
    features => {
        TextTable => {
            can_align_cell_containing_wide_character => 0,
            can_align_cell_containing_color_code     => 1,
            can_align_cell_containing_newline        => 0,
            can_use_box_character                    => 0,
            can_customize_border                     => 1,
            can_halign                               => 1,
            can_halign_individual_row                => 0,
            can_halign_individual_column             => 1,
            can_halign_individual_cell               => 0,
            can_valign                               => 0,
            can_valign_individual_row                => 0,
            can_valign_individual_column             => 0,
            can_valign_individual_cell               => 0,
            can_rowspan                              => 0,
            can_colspan                              => 0,
            can_color                                => 0,
            can_color_theme                          => 0,
            can_set_cell_height                      => 0,
            can_set_cell_height_of_individual_row    => 0,
            can_set_cell_width                       => 0,
            can_set_cell_width_of_individual_column  => 0,
            speed                                    => 'medium',
            can_hpad                                 => 0,
            can_hpad_individual_row                  => 0,
            can_hpad_individual_column               => 0,
            can_hpad_individual_cell                 => 0,
            can_vpad                                 => 0,
            can_vpad_individual_row                  => 0,
            can_vpad_individual_column               => 0,
            can_vpad_individual_cell                 => 0,
        },
    },
);

1;
# ABSTRACT: Features declaration for Text::Table::Tiny

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::Tiny::_ModuleFeatures - Features declaration for Text::Table::Tiny

=head1 VERSION

This document describes version 0.002 of Text::Table::Tiny::_ModuleFeatures (from Perl distribution Text-Table-Tiny-_ModuleFeatures), released on 2021-04-06.

=head1 DECLARED FEATURES

Features declared by this module (actually declared for L<Text::Table::Tiny>):

=head2 From feature set TextTable

Features from feature set L<TextTable|Module::Features::TextTable> declared by this module:

=over

=item * can_align_cell_containing_color_code

Value: yes.

=item * can_align_cell_containing_newline

Value: no.

=item * can_align_cell_containing_wide_character

Value: no.

=item * can_color

Can produce colored table.

Value: no.

=item * can_color_theme

Allow choosing colors from a named set of palettes.

Value: no.

=item * can_colspan

Value: no.

=item * can_customize_border

Let user customize border character in some way, e.g. selecting from several available borders, disable border.

Value: yes.

=item * can_halign

Provide a way for user to specify horizontal alignment (leftE<sol>middleE<sol>right) of cells.

Value: yes.

=item * can_halign_individual_cell

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual cells.

Value: no.

=item * can_halign_individual_column

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual columns.

Value: yes.

=item * can_halign_individual_row

Provide a way for user to specify different horizontal alignment (leftE<sol>middleE<sol>right) for individual rows.

Value: no.

=item * can_hpad

Provide a way for user to specify horizontal padding of cells.

Value: no.

=item * can_hpad_individual_cell

Provide a way for user to specify different horizontal padding of individual cells.

Value: no.

=item * can_hpad_individual_column

Provide a way for user to specify different horizontal padding of individual columns.

Value: no.

=item * can_hpad_individual_row

Provide a way for user to specify different horizontal padding of individual rows.

Value: no.

=item * can_rowspan

Value: no.

=item * can_set_cell_height

Allow setting height of rows.

Value: no.

=item * can_set_cell_height_of_individual_row

Allow setting height of individual rows.

Value: no.

=item * can_set_cell_width

Allow setting height of rows.

Value: no.

=item * can_set_cell_width_of_individual_column

Allow setting height of individual rows.

Value: no.

=item * can_use_box_character

Can use terminal box-drawing character when drawing border.

Value: no.

=item * can_valign

Provide a way for user to specify vertical alignment (topE<sol>middleE<sol>bottom) of cells.

Value: no.

=item * can_valign_individual_cell

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual cells.

Value: no.

=item * can_valign_individual_column

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual columns.

Value: no.

=item * can_valign_individual_row

Provide a way for user to specify different vertical alignment (topE<sol>middleE<sol>bottom) for individual rows.

Value: no.

=item * can_vpad

Provide a way for user to specify vertical padding of cells.

Value: no.

=item * can_vpad_individual_cell

Provide a way for user to specify different vertical padding of individual cells.

Value: no.

=item * can_vpad_individual_column

Provide a way for user to specify different vertical padding of individual columns.

Value: no.

=item * can_vpad_individual_row

Provide a way for user to specify different vertical padding of individual rows.

Value: no.

=item * speed

Subjective speed rating, relative to other text table modules.

Value: "medium".

=back

For more details on module features, see L<Module::Features>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-Tiny-_ModuleFeatures>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-Tiny-_ModuleFeatures>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Text-Table-Tiny-_ModuleFeatures/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Table::Tiny>

L<Module::Features>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
