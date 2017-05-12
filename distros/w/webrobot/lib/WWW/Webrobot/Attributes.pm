package WWW::Webrobot::Attributes;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

sub import {
    my $self = shift;
    my $package = caller(0);
    foreach my $attr (@_) {
        my $attr_fun = "$package\::$attr";
        my $attr_name = "_$attr";
        if (!defined *{$attr_fun}) {
            #print "DEFINE $attr_fun as $attr_name\n";
            no strict;
            *{$attr_fun}  = sub {
                my $self = shift;
                my $old = $self->{$attr_name};
                $self->{$attr_name} = shift if @_;
                return $old;
            };
        }
    }
}

1;

=head1 NAME

WWW::Webrobot::Attributes - define setter/getter for attributes of a class

=head1 SYNOPSIS

 use WWW::Webrobot::Attributes qw(attr1 attr2 attr3);

=head1 DESCRIPTION

This module is used to define setter/getter for attributes.
Access:

 $self->attr1
     return attribute named 'attr1'

 $self->attr1($value);
     set attribute named 'attr1' to value '$value'

=cut

__END__
