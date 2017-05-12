package VUser::Meta;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@gmail.com>
# $Id: Meta.pm,v 1.5 2006-01-04 21:57:48 perlstalker Exp $

our $VERSION = "0.3.0";

sub new
{
    my $obj = shift;
    my $class = ref $obj ? ref $obj : $obj;

    my %args = @_;

    my $self = { default => [],      # Default values for this option
		 type => 'string',   # data type: integer (int), string,
		                     #   counter, boolean, float
		 description => '',  # Help description
		 widget => '',       # Which widget type to use
		 values => [],       # Possible values for option type widgets
		 labels => [],       # Labels for the values above
		 searchable => 0,    # This option is a search key
		 readonly => 0,      # This option is read only
		 name => ''          # The internal option name
		};

    # Create a copy of the creating object (if it is an object)
    if (ref $obj) {
	$self = {$obj->as_hash};
    }

    bless $self, $class;

    foreach my $key (%$self) {
	$self->$key($args{$key}) if exists $args{$key};
    }

    return $self;
}

sub unset
{
    my $self = shift;
    my $key = shift;
    $self->{$key} = undef if exists $self->{$key};
}

sub as_hash
{
    my $self = shift;
    return %{$self};
}

sub AUTOLOAD
{
    use vars '$AUTOLOAD';
    my $self = shift;
    my $value = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*:://;

    if (exists $self->{$name}) {
	$self->{$name} = $value if defined $value;
	return $self->{$name};
    } else {
	warn "Unknown method: $name\n";
	return undef;
    }
}

sub DESTROY { };

sub version { return $VERSION; }

1;

__END__

=head1 NAME

VUser::Meta - Meta data for options.

=head1 SYNOPSIS

 my $meta = VUser::Meta->new('name' => 'foo',
                             'type' => 'string',
                             'description' => 'The value of foo');

=head1 DESCRIPTION

VUser::Meta objects are used in to describe options and return data
from Extensions.

=head2 Allowed types

=over 4

=item integer (int)

=item string

=item counter

Used for options rather than result sets.

=item boolean

=item float

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

