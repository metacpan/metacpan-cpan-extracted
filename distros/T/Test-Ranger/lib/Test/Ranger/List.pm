package Test::Ranger::List;
use parent Test::Ranger;

use strict;
use warnings;
use Carp;

use version 0.77; our $VERSION = qv('0.0.4');

## use

#============================================================================#

#=========# CLASS METHOD
#
#   my $list    = $class->new( \@list );
#   my $list    = $class->new([
#                       { -a  => 'x' },
#                       { -b  => 'y' },
#                   ]);
#       
# Purpose   : Object constructor
# Parms     : $class    : Any subclass of this class
#           : \@list    : Arrayref only; required
# Returns   : $self
# Invokes   : init()
# 
# An object of this $class is a hashref, *not* an arrayref!
# But it is constructed by passing in an arrayref. 
# An empty hashref is blessed into $class. 
# Each element of @list is blessed into Test::Ranger in init(). 
# Housekeeping info for the whole object is stored in other keys. 
# 
sub new {
    my $class   = shift;
    my @list    = @{ shift() };
    my $self    = {};
    
    bless ($self => $class);
    $self->init(@list);
    
    return $self;
}; ## new

#=========# OBJECT METHOD
#
#   $self->init( @list );
# 
# Purpose   : Object initializer
# Parms     : $class
#           : @list     : Array; required
# Returns   : $self
# Invokes   : Test::Ranger::new()
# 
# Blesses each element of @list into Test::Ranger and 
#   assigns \@list to $self->{-list}.
# Adds housekeeping info for the whole object to other keys. 
# 
sub init {
    my $self        = shift;
    my @list_in     = @_;
    my @list_out    ;
    
    foreach my $single (@list_in) {
        push @list_out, Test::Ranger->new($single);
    };
    
    $self->{-list}              = \@list_out;
    $self->SUPER::init();
    
    return $self;
}; ## init



## END MODULE
1;
#============================================================================#
__END__

=head1 NAME

Test::Ranger::List - Helper module for Test::Ranger. 

=head1 VERSION

This document describes Test::Ranger::List version 0.0.1

TODO: THIS IS A DUMMY, NONFUNCTIONAL RELEASE.

=head1 SYNOPSIS

    use Test::Ranger;

=head1 DESCRIPTION

This class represents a list of Test::Ranger objects. Please see the main 
L<Test::Ranger> documentation for details. 

=head1 AUTHOR

Xiong Changnian  C<< <xiong@cpan.org> >>

=head1 LICENSE

Copyright (C) 2010 Xiong Changnian C<< <xiong@cpan.org> >>

This library and its contents are released under Artistic License 2.0:

L<http://www.opensource.org/licenses/artistic-license-2.0.php>

=cut
