package UI::Various::language::de;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::language::de - German language support of L<UI::Various>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly using the following:
    use UI::Various;

=head1 ABSTRACT

This module contains all German texts of L<UI::Various>.

=head1 DESCRIPTION

The module just provides a hash of texts to be used in L<UI::Various::core>.

See L<UI::Various::language::en> for more details.

=cut

#########################################################################

use v5.12.1;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.01';

#########################################################################

=head1 EXPORT

=head2 %T - hash of German texts

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Don't reformat this assignment or delete the comment-blocks dividing
# errors, warnings and others.  update-language.pl depends on it:
our %T =
    (
     ####################################################################
     # fatal and non-fatal error message, always without trailing "\n" for
     # automatically added location:
     bad_debug_level__1
     => "unzulässiges debug Level '%s'",
     bad_usage_of__1_as__2
     => "fehlerhafte Nutzung von %s als %s",
     bad_usage_of__1_pkg_is__2
     => "fehlerhafte Nutzung von %s, \$pkg ist '%s'",
     message__1_missing_in__2
     => "text '%s' fehlt in '%s'",
     options_must_be_specified_as_hash
     => 'Optionen müssen als {hash} spezifiziert werden',
     stderr_not_0_1_2_or_3
     => 'stderr muß 0, 1, 2 oder 3 sein',
     ui_various_core_must_be_1st_used_from_ui_various
     => 'UI::Various::core muß zuerst von UI::Various importiert werden',
     undefined_logging_level__1
     => "unbekanntes Protokollierungslevel '%s'",
     unknown_option__1
     => "unbekannte Option '%s'",
     unsupported_language__1
     => "'%s' ist kein unterstützte Sprache",
     unsupported_ui_package__1
     => "'%s' ist kein unterstütztes UI Paket",
     use_option_must_be_an_array_reference
     => "'use' Option muß eine Reference auf ein ARRAY sein",

     ####################################################################
     # Warnings and information usually don't need location information, so
     # it's good practice to finish all with a "\n";
     using__1_as_ui
     => "'%s' wird als UI benutzt\n",
    );

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (AT) cpan.orgE<gt>

=cut
