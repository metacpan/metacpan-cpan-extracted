package UR::Object::Property::View::ReferenceDescription::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object::View::Default::Text',
    doc => "View used by 'ur show properties' for each object-accessor property",
);

sub _update_view_from_subject {
    my $self = shift;

    my $property_meta = $self->subject;
    return unless ($property_meta);

    my $r_class_name = $property_meta->data_type;

    my @relation_detail;
    my @pairs = eval { $property_meta->get_property_name_pairs_for_join() };

    my $text;
    if (@pairs) {
        foreach my $pair ( @pairs ) {
            my($property_name, $r_property_name) = @$pair;
            push @relation_detail, "$r_property_name => \$self->$property_name";
        }
        my $padding = length($r_class_name) + 34;
        my $relation_detail = join(",\n" . " "x$padding, @relation_detail);

        $text = sprintf("  %22s => %s->get(%s)\n",
                        $property_meta->property_name,
                        $r_class_name,
                        $relation_detail);
    } else {
        $text = sprintf(" %22s => %s->get(id => \$self->%s)\n",
                        $property_meta->property_name,
                        $r_class_name,
                        $property_meta->property_name);
    }
            
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
