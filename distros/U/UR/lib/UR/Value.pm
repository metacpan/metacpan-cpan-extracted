package UR::Value;

use strict;
use warnings;

require UR;

use List::MoreUtils;

our $VERSION = "0.46"; # UR $VERSION;

our @CARP_NOT = qw( UR::Context );

UR::Object::Type->define(
    class_name => 'UR::Value',
    is => 'UR::Object',
    has => ['id'],
    data_source => 'UR::DataSource::Default',
);

sub __display_name__ {
    return shift->id;
}

sub __load__ {
    my $class = shift;
    my $rule = shift;
    my $expected_headers = shift;

    my $class_meta = $class->__meta__;
    unless ($class_meta->{_value_loader}) {
        my @id_property_names = $class_meta->all_id_property_names;
        my %id_property_names = map { $_ => 1 } @id_property_names;

        my $loader = sub {
            my $bx = shift;
            my $id = $bx->value_for_id;
            unless (defined $id) {
                Carp::croak "Can't load an infinite set of "
                            . $bx->subject_class_name
                            . ".  Some id properties were not specified in the rule $bx";
            }
            my @rows;
            if (ref($id) and ref($id) eq 'ARRAY') {
                # Multiple IDs passed in - return rows for multiple objects
                my @non_id = grep { ! $id_property_names{$_} } $bx->template->_property_names;
                if (@non_id) {
                    Carp::croak("Cannot load class "
                                . $bx->subject_class_name
                                . " via UR::DataSource::Default when 'id' is a listref and non-id"
                                . " properties appear in the rule: "
                                . join(', ', @non_id));
                }

                # Get the 1st value from each list, then the second, then the third, etc
                my $iter = List::MoreUtils::each_arrayref
                            map {
                                my $v = $bx->value_for($_);
                                (ref($v) eq 'ARRAY')
                                    ? $v
                                    : [ $v ]
                            }
                            @$expected_headers;
                while(my @row = $iter->()) {
                    push @rows, \@row;
                }

            } else {
                # single ID - return a single row
                my @row = map { $bx->value_for($_) } @$expected_headers;
                @rows = ( \@row );
            }
            return ($expected_headers, \@rows);
        };

        $class_meta->{_value_loader} = $loader;
    }

    return $class_meta->{_value_loader}->($rule);
}

sub underlying_data_types {
    return ();
}

package UR::Value::Type;

sub get_composite_id_decomposer {
    my $class_meta = shift;

    unless ($class_meta->{get_composite_id_decomposer}) {
        my @id_property_names = $class_meta->id_property_names;
        my $instance_class = $class_meta->class_name;
        if (my $decomposer = $instance_class->can('__deserialize_id__')) {
            $class_meta->{get_composite_id_decomposer} = sub {
                my @ids = (ref($_[0]) and ref($_[0]) eq 'ARRAY')
                            ? @{$_[0]}
                            : ( $_[0] );
                my @retval;
                if (@ids == 1) {
                    my $h = $instance_class->$decomposer($ids[0]);
                    @retval = @$h{@id_property_names};

                } else {
                    # Get the 1st value from each list, then the second, then the third, etc
                    my @decomposed = map {
                            my $h = $instance_class->$decomposer($_);
                            [ @$h{@id_property_names} ]
                        }
                        @ids;
                    my $iter = List::MoreUtils::each_arrayref @decomposed;

                    while( my @row = $iter->() ) {
                        push @retval, \@row;
                    }
                }
                return @retval;
            };

        } else {
            $decomposer = $class_meta->SUPER::get_composite_id_decomposer();
            $class_meta->{get_composite_id_decomposer} = $decomposer;
        }
    }
    return $class_meta->{get_composite_id_decomposer};
}

sub get_composite_id_resolver {
    my $class_meta = shift;
    unless ($class_meta->{get_composite_id_resolver}) {
        my @id_property_names = $class_meta->id_property_names;
        my $instance_class = $class_meta->class_name;
        if (my $resolver = $instance_class->can('__serialize_id__')) {
            $class_meta->{get_composite_id_resolver} = sub {
                my %h = map { $_ => shift } @id_property_names;
                return $instance_class->__serialize_id__(\%h);
            };

        } else {
            $resolver = $class_meta->SUPER::get_composite_id_resolver();
            $class_meta->{get_composite_id_resolver} = $resolver;
        }
    }
    return $class_meta->{get_composite_id_resolver};
}



1;
