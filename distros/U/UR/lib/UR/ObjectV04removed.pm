=pod 

=head1 NAME

UR::ObjectV04removed - restores changes removed in UR version 0.04 

=head1 SYNOPSIS

use UR::ObjectV04removed

=head1 DESCRIPTION

Extends the UR::Object API have methods removed in the 0.04 release. 

If you upgrade UR, but depend on old APIs, use this module.

For version 0.xx of UR, APIs may change with each release.  After 1.0, APIs will
only change with major releases number increments.

=cut

# version 0.4 commits significant refactoring of the UR::BoolExpr API
# this brings back those parts which got new names

package UR::BoolExpr;
use strict;
use warnings;
our $VERSION = "0.46"; # UR $VERSION;

*get_rule_template = \&template;
*rule_template = \&template;
*get_rule_template_and_values = \&template_and_values;
*get_template_and_values = \&template_and_values;
*get_values = \&values;
*get_underlying_rules = \&underlying_rules;
*specifies_value_for_property_name = \&specifies_value_for;

*specified_operator_for = \&operator_for;
*specified_operator_for_propety_name = \&operator_for;
*specified_value_for_id = \&value_for_id;
*specified_value_for_position = \&value_for_position;
*specified_value_for_property_name = \&value_for;

*create_from_filter_string = \&resolve_for_string;
*create_from_command_line_format_filters = \&_resolve_from_filter_array;
*create_from_filters = \&_resolve_from_filter_array;
*create_from_subject_class_name_keys_and_values = \&_resolve_from_subject_class_name_keys_and_values;

*resolve_normalized_rule_for_class_and_params = \&resolve_normalized;
*resolve_for_class_and_params = \&resolve;
*get_normalized_rule_equivalent = \&normalize;

