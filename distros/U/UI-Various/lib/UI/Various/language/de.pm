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

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '1.00';

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
     _1_attribute_must_be_a_2_reference
     => "Attribut '%s' muß %s Referenz sein",
     _1_element_must_be_accompanied_by_parent
     => '%s Element benötigt Elternelement',
     _1_may_not_be_empty
     => "'%s' darf nicht leer sein",
     _1_may_not_be_modified_directly_after_initialisation
     => "'%s' darf nach der Initialisierung nicht mehr direkt geändert werden",
     _1_may_only_be_called_from_itself
     => '%s darf nur innerhalb der Klasse benutzt werden',
     _1_to_cancel
     => '%s bricht ab',
     bad_debug_level__1
     => "unzulässiges Debug Level '%s'",
     bad_usage_of__1_as__2
     => "fehlerhafte Nutzung von %s als %s",
     bad_usage_of__1_pkg_is__2
     => "fehlerhafte Nutzung von %s, \$pkg ist '%s'",
     can_t_open__1__2
     => "kann '%s' nicht öffnen: %s",
     can_t_remove__1_from_old_parent__2
     => "kann '%s' nicht von altem Elternelement trennen",
     can_t_remove__1_no_such_node_in__2
     => "kann '%s' nicht entfernen: existiert nicht in %s",
     cyclic_parent_relationship_detected__1_levels_above
     => 'zyklische Abhängigkeit %d Ebenen höher gefunden',
     element__1_in_call_to__2__3_already_exists
     => 'Element %s in Aufruf von %s::%s existiert bereits',
     enter_number_to_choose_next_step
     => 'Nummer für nächste Aktion eingeben',
     enter_selection
     => 'Auswahl eingeben',
     include_option_must_be_an_array_reference_or_a_scalar
     => "'include' Option muss ARRAY Referenz oder Skalar sein",
     invalid_call_to__1__2
     => 'ungültiger Aufruf von %s::%s',
     invalid_object__1_in_call_to__2
     => 'ungültiges Objekt (%s) in Aufruf von %s',
     invalid_object__1_in_call_to__2__3
     => 'ungültiges Objekt (%s) in Aufruf von %s::%s',
     invalid_pair_in__1_attribute
     => "ungültiges Pärchen in Attribut '%s'",
     invalid_parameter__1_in_call_to__2
     => "ungültiger Parameter '%s'in Aufruf von %s",
     invalid_parameter__1_in_call_to__2__3
     => "ungültiger Parameter '%s'in Aufruf von %s::%s",
     invalid_parent__1_not_a_ui_various_container
     => "ungültiges Elternelement '%s' (kein UI::Various::container)",
     invalid_scalar__1_in_call_to__2
     => "ungültiger Skalar '%s' in Aufruf von %s",
     invalid_scalar__1_in_call_to__2__3
     => "ungültiger Skalar '%s' in Aufruf von %s::%s",
     invalid_selection
     => "Auswahl ungültig",
     invalid_value__1_for_parameter__2_in_call_to__3__4
     => "ungültiger Wert %s für Parameter '%s' in Aufruf von %s::%s",
     leave_box
     => 'Box verlassen',
     leave_dialog
     => 'Dialog verlassen',
     leave_listbox
     => 'Listbox verlassen',
     leave_window
     => 'Fenster verlassen',
     mandatory_parameter__1_is_missing
     => "notwendiger Parameter '%s' fehlt",
     message__1_missing_in__2
     => "text '%s' fehlt in '%s'",
     new_value
     => 'neuer Wert',
     next_previous_window
     => ', <+>/<-> nächstes/vorheriges Fenster',
     no_element_found_for_index__1
     => 'Element für index %d fehlt',
     no_free_position_for__1_in_call_to__2__3
     => 'keine freie Position für %s in Aufruf von %s::%s',
     odd_number_of_parameters_in_initialisation_list_of__1
     => 'ungerade Anzahl von Parametern in Initialisierungsliste von %s',
     old_value
     => 'alter Wert',
     options_must_be_specified_as_hash
     => 'Optionen müssen als {hash} spezifiziert werden',
     parameter__1_must_be_a_positive_integer
     => "parameter '%s' muß positive ganze Zahl sein",
     parameter__1_must_be_a_positive_integer_in_call_to__2__3
     => "parameter '%s' in Aufruf von %s::%s muß positive ganze Zahl sein",
     parameter__1_must_be_a_valid_colour
     => "parameter '%s' muß eine Farbe sein (Basisfarbe oder Hex-Code)",
     parameter__1_must_be_in__2__3
     => "parameter '%s' muß im Bereich [%s..%s] liegen",
     reset_directory_invalid_symbolic_link
     => 'Verzeichnis zurückgesetzt (kaputter symbolischer Link?)',
     scrolls
     => '+/- blättert',
     specified_implementation_missing
     => 'spezifische Implementierung fehlt',
     stderr_not_0_1_2_or_3
     => 'stderr muß 0, 1, 2 oder 3 sein',
     ui_various_core_must_be_1st_used_from_ui_various
     => 'UI::Various::core muß zuerst von UI::Various importiert werden',
     undefined_input
     => 'Eingabe undefiniert',
     undefined_logging_level__1
     => "unbekanntes Protokollierungslevel '%s'",
     unknown_option__1
     => "unbekannte Option '%s'",
     unsupported_language__1
     => "'%s' ist kein unterstützte Sprache",
     unsupported_ui_element__1__2
     => "'%s' ist kein unterstütztes UI Element: %s",
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
