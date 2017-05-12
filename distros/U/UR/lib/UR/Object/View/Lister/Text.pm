package UR::Object::View::Lister::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;
use IO::File;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object::View::Default::Text',
);


sub _update_view_from_subject {
    my $self = shift;
    my @changes = @_;  # this is not currently resolved and passed-in
    
    my $subject = $self->subject();
    my $subject_class_meta = $subject->__meta__;
    my @aspects = $self->aspects;
    
    my %data_for_this_object;
    my(%aspects_requiring_joins_by_name,%aspects_requiring_joins_by_via);
    my %column_for_label;
    for (my $i = 0; $i < @aspects; $i++) {
        my $aspect = $aspects[$i];
        my $label = $aspect->label;
        my $aspect_name = $aspect->name;
        $column_for_label{$label} = $i;

        my $property_meta = $subject_class_meta->property_meta_for_name($aspect_name);
        if (my $via = $property_meta->via and $property_meta->is_many) {
            $aspects_requiring_joins_by_name{$aspect_name} = $via;
            $aspects_requiring_joins_by_via{$via} ||= [];
            push @{$aspects_requiring_joins_by_via{$via}}, $aspect_name;
        }

        if ($subject) {
            my @value = $subject->$aspect_name;
            if (@value == 1 and ref($value[0]) eq 'ARRAY') {
                @value = @{$value[0]};
            }
                
            # Delegate to a subordinate view if need be
            if ($aspect->delegate_view_id) {
                my $delegate_view = $aspect->delegate_view;
                foreach my $value ( @value ) {
                    $delegate_view->subject($value);
                    $delegate_view->_update_view_from_subject();
                    $value = $delegate_view->content();
                }
            }

            if (@value == 1) {
                $data_for_this_object{$label} = $value[0];
            } else {
                $data_for_this_object{$label} = \@value;
            }
        }
    }

    if (keys(%aspects_requiring_joins_by_via) > 1) {
        $self->error_message("Viewing delegated properties via more than one property is not supported");
        return;
    }

    # fill in the first row of data
    my @retval = ();
    foreach my $aspect ( @aspects ) {
        my $label = $aspect->label;
        my $col = $column_for_label{$label};
        if (ref($data_for_this_object{$label})) {
            # it's a multi-value
            $retval[0]->[$col] = shift @{$data_for_this_object{$label}};
        } else {
            $retval[0]->[$col] = $data_for_this_object{$label};
        }
    }

    foreach my $via ( keys %aspects_requiring_joins_by_via ) {
         
        while(1) {
            my @this_row;
            foreach my $prop ( @{$aspects_requiring_joins_by_via{$via}} ) {
                my $data;
                if (ref($data_for_this_object{$prop}) eq 'ARRAY') {
                    $data = shift @{$data_for_this_object{$prop}};
                    next unless $data;
                } else {
                    $data = $data_for_this_object{$prop};
                    $data_for_this_object{$prop} = [];
                }
                $this_row[$column_for_label{$prop}] = $data;
            }
            last unless @this_row;
            push @retval, \@this_row;
        }

    }

    foreach my $row ( @retval ) {
        no warnings 'uninitialized';
        $row = join("\t",@$row);
    }

    my $text = join("\n", @retval);

    # The text widget won't print anything until show(),
    # so store the data in the buffer for now
    my $widget = $self->widget;
    ${$widget->[0]} = $text;   # Update the contents
    return 1;
}

sub _update_subject_from_view {
    1;
}

sub _add_aspect {
    1;
}

sub _remove_aspect {
    1;
}


1;

