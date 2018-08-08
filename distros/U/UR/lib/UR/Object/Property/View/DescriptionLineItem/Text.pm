package UR::Object::Property::View::DescriptionLineItem::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object::View::Default::Text',
    doc => "View used by 'ur show properties' for each property line item",
);

sub _update_view_from_subject {
    my $self = shift;

    my $property_meta = $self->subject;
    return unless ($property_meta);

    my $nullable = $property_meta->is_optional ? "NULLABLE" : "";

    my $column_name = $property_meta->column_name;
    unless ($column_name) {
        if ($property_meta->via) {
            $column_name = $property_meta->via . '->' . $property_meta->to;
        } elsif ($property_meta->is_classwide) {
            $column_name = '(classwide)';
            
        } elsif ($property_meta->is_delegated) {
            # delegated, but not via.  Must be an object accessor
            $column_name = ''
        } elsif ($property_meta->is_calculated) {
            my $calc_from = $property_meta->calculate_from;
            if ($calc_from and @$calc_from) {
                $column_name = '(calculated from ' . join(',',@$calc_from). ')';
            } else {
                $column_name = '(calculated)';
            }
        } else {
            $column_name = '(no column)';
        }
    }

    my $data_type_string;
    if (defined $property_meta->data_type) {
        my $len = $property_meta->data_length;
        $data_type_string = $property_meta->data_type . ( $len ? "(".$len.")" : "");
    } else {
        $data_type_string = '(no type)';
    }

    my $text = sprintf(" %2s %30s %-40s  %25s  $nullable",
               $property_meta->is_id ? "ID" : "  ",
               $property_meta->property_name,
               $column_name,
               $data_type_string,
              );

    my $widget = $self->widget();
    my $buffer_ref = $widget->[0];
    $$buffer_ref = $text;
    return 1;
}



1;

=pod

=head1 NAME 

UR::Object::Property::View::DescriptionLineItem::Text - View class for UR::Object::Property

=head1 DESCRIPTION

Used by UR::Namespace::Command::Show::Properties when displaying information about a property

=cut
