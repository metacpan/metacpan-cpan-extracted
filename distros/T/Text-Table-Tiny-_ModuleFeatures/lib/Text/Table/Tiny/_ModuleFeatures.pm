package Text::Table::Tiny::_ModuleFeatures;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-28'; # DATE
our $DIST = 'Text-Table-Tiny-_ModuleFeatures'; # DIST
our $VERSION = '0.001'; # VERSION

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

This document describes version 0.001 of Text::Table::Tiny::_ModuleFeatures (from Perl distribution Text-Table-Tiny-_ModuleFeatures), released on 2021-02-28.

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
