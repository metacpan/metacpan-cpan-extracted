package UI::Various::language::en;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::language::en - English language support of L<UI::Various>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly using the following:
    use UI::Various;

=head1 ABSTRACT

This module contains all English texts of L<UI::Various>.

=head1 DESCRIPTION

The module just provides a hash of texts to be used in L<UI::Various::core>.

The keys are the original English strings (to make mapping easy), with the
following rules applied:

=over

=item 1

All characters are converted to lowercase.

=item 2

Each C<L<sprintf|perlfunc/sprintf>> conversion sequence is replaced by an
underscore (C<_>) followed by the index of the sequence in the English
string.

=item 3

All non-word characters are replaced with underscores (C<_>).

=item 4

Multiple underscores (C<_>) are replaced by a single one, except for those
of a C<sprintf> conversion sequence.  E.g. a conversion sequence after one
or more non-word characters appears as two underscores (C<_>) followed by
the index number.

=item 5

All leading and trailing underscores (C<_>) are removed.

=item 6

Keys and messages are on two separate lines, with the second line beginning
with the C<=E<gt>> and ending with C<,>.  This eases the transfer of
messages added later to other language files.

=back

See C<bad_debug_level__1> (C<"bad debug-level '%s'">) in the code as an
example.

The easiest way to get the right key / text entry is calling the helper
script C<L<update-language.pl>> with the string as sole parameter.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.11';

#########################################################################

=head1 EXPORT

=head2 %T - hash of english texts, 3 sections (errors, warnings/information
and special), each section alphabetically sorted by key

Note that C<%T> is not exported into the callers name-space, it must always
be fully qualified.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our %T =
    (
     ####################################################################
     # fatal and non-fatal error message, always without trailing "\n" for
     # automatically added location:
     _1_attribute_must_be_a_code_reference
     => "'%s' attribute must be a CODE reference",
     _1_element_must_be_accompanied_by_parent
     => '%s element must be accompanied by parent',
     _1_may_only_be_called_from__2
     => '%s may only be called from %s',
     bad_debug_level__1
     => "bad debug-level '%s'",
     bad_usage_of__1_as__2
     => "bad usage of %s as %s",
     bad_usage_of__1_pkg_is__2
     => "bad usage of %s, \$pkg is '%s'",
     can_t_remove__1_from_old_parent__2
     => "can't remove '%s' from old parent '%s'",
     can_t_remove__1_no_such_node_in__2
     => "can't remove %s: no such node in %s",
     cyclic_parent_relationship_detected__1_levels_above
     => 'cyclic parent relationship detected %d levels above',
     enter_number_to_choose_next_step
     => 'enter number to choose next step',
     enter_selection
     => 'enter selection',
     include_option_must_be_an_array_reference_or_a_scalar
     => "'include' option must be an ARRAY reference or a scalar",
     invalid_object__1_in_call_to__2
     => 'invalid object (%s) in call to %s',
     invalid_object__1_in_call_to__2__3
     => 'invalid object (%s) in call to %s::%s',
     invalid_parameter__1_in_call_to__2
     => "invalid parameter '%s' in call to %s",
     invalid_parameter__1_in_call_to__2__3
     => "invalid parameter '%s' in call to %s::%s",
     invalid_parent__1_not_a_ui_various_container
     => "invalid parent '%s' (not a UI::Various::container)",
     invalid_scalar__1_in_call_to__2
     => "invalid scalar '%s' in call to %s",
     invalid_selection
     => "invalid selection\n",
     leave_window
     => 'leave window',
     message__1_missing_in__2
     => "message '%s' missing in '%s'",
     next_previous_window
     => ', <+>/<-> next/previous window',
     no_element_found_for_index__1
     => 'no element found for index %d',
     odd_number_of_parameters_in_initialisation_list_of__1
     => 'odd number of parameters in initialisation list of %s',
     options_must_be_specified_as_hash
     => 'options must be specified as {hash}',
     specified_implementation_missing
     => 'specified implementation missing',
     stderr_not_0_1_2_or_3
     => 'stderr not 0, 1, 2 or 3',
     ui_various_core_must_be_1st_used_from_ui_various
     => 'UI::Various::core must be 1st used from UI::Various',
     undefined_input
     => 'undefined input',
     undefined_logging_level__1
     => "undefined logging level '%s'",
     unknown_option__1
     => "unknown option '%s'",
     unsupported_language__1
     => "unsupported language '%s'",
     unsupported_ui_element__1
     => "unsupported UI element '%s'",
     unsupported_ui_package__1
     => "unsupported UI package '%s'",
     use_option_must_be_an_array_reference
     => "'use' option must be an ARRAY reference",

     ####################################################################
     # Warnings and information usually don't need location information, so
     # it's good practice to finish all with a "\n";
     using__1_as_ui
     => "using '%s' as UI\n",

     ####################################################################
     # don't translate these into other languages, they are only needed for
     # specific tests (including fallback test):
     zz_unit_test
     => 'unit test string',
     zz_unit_test_empty
     => '',
     zz_unit_test_text
     => 'dummy text',
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
