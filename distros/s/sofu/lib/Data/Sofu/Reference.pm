###############################################################################
#Reference.pm
#Last Change: 2006-11-01
#Copyright (c) 2006 Marc-Seabstian "Maluku" Lucksch
#Version 0.28
####################
#This file is part of the sofu.pm project, a parser library for an all-purpose
#ASCII file format. More information can be found on the project web site
#at http://sofu.sourceforge.net/ .
#
#sofu.pm is published under the terms of the MIT license, which basically means
#"Do with it whatever you want". For more information, see the license.txt
#file that should be enclosed with libsofu distributions. A copy of the license
#is (at the time of this writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################

=head1 NAME

Data::Sofu::Reference - A Sofu Reference

=head1 DESCRIPTION

Provides a interface similar to the original SofuD (sofu.sf.net).

References present a transparent interface to the object referenced. Normally they shouldn't even bother you one bit.


=head1 Synopsis 

	require Data::Sofu::Map;
	require Data::Sofu::Reference;
	my $map = Data::Sofu::Map->new();
	$map->setAttribute("myself",Data::Sofu::Reference->new($map)); #Reference to itself.
	$map->map("myself"); #Will return $map not the Reference.
	$map->object("myself")->asReference(); #Will return the Reference.
	$map->object("myself")->asMap(); #will return the Map.
	$map->object("myself")->isMap(); #True
	$map->map("myself")->isMap(); #Also true
	$map->object("myself")->isReference(); #True
	$map->map("myself")->isReference(); #false (you skipped the reference when using map());
	#You can also:
	my $map = Data::Sofu::Map->new();
	$map->setAttribute("myself",$map); #Will be converted to Reference as soon as it is written to a file or string.

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut


package Data::Sofu::Reference;

use strict;
use warnings;
require Data::Sofu::Object;
our @ISA = qw/Data::Sofu::Object/;
our $VERSION="0.29";
use vars qw/$AUTOLOAD/;

=head1 METHODS

Also look at C<Data::Sofu::Object> for methods, cause Reference inherits from it

=head2 new([DATA])
Creates a new C<Data::Sofu::Reference> and returns it

	$ref = Data::Sofu::Reference->new("->myself"); #Tree form, not valid (just for saving data)
	my $map = Data::Sofu::Map->new();
	$ref = Data::Sofu::Reference->new($map); #Valid

=cut 

sub new {
	my $self={};
	bless $self,shift;
	if (@_) {
		$self->{Reference}=shift;
	}
	return $self;
}

=head2 dangle([Data])

Changes the target of the Reference to Data

=cut

sub dangle {
	my $self=shift;
	$self->{Reference}=shift;
}

=head2 valid() 

Return 1 if the Reference is there and points to something that is a Data::Sofu::Object

=cut

sub valid {
	my $self=shift;
	my $r = ref $self->{Reference};
	return 1 if $r and $r=~m/Data::Sofu/ and $self->{Reference}->isa("Data::Sofu::Object");
	return 0;
}

=head2 isValid()

Return 1 if the Reference is there and points to something that is a Data::Sofu::Object

=cut

sub isValid {
	my $self=shift;
	my $r = ref $self->{Reference};
	return 1 if $r and $r=~m/Data::Sofu/ and $self->{Reference}->isa("Data::Sofu::Object");
	return 0;
}

=head2 isReference()

Returns 1

=cut

sub isReference {
	return 1;
}

=head2 follow()

Returns the referenced object, valid or not.

=cut

sub follow {
	my $self=shift;
	return $self->{Reference};
}

=head2 asValue()

Returns the referenced objects asValue() call.

Which Returns either the referenced object or throws an exception

=cut

sub asValue {
	my $self=shift;
	die "Invalid Reference" unless $self->isValid();
	return $self->{Reference}->asValue();
}

=head2 asMap()

Returns the referenced objects asMap() call.

Which Returns either the referenced object or throws an exception

=cut

sub asMap {
	my $self=shift;
	die "Invalid Reference" unless $self->isValid();
	return $self->{Reference}->asMap();
}

=head2 asList()

Returns the referenced objects asList() call.

Which Returns either the referenced object or throws an exception

=cut

sub asList {
	my $self=shift;
	die "Invalid Reference" unless $self->isValid();
	return $self->{Reference}->asList();
}

=head2 isList()

Returns 1 if the Reference is valid and the referenced Object is a List.

=cut

sub isList {
	my $self=shift;
	return $self->isValid() && $self->{Reference}->isList();
}

=head2 isValue()

Returns 1 if the Reference is valid and the referenced Object is a Value.

=cut

sub isValue {
	my $self=shift;
	return $self->isValid() && $self->{Reference}->isValue();
}

=head2 isMap()

Returns 1 if the Reference is valid and the referenced Object is a Map.

=cut

sub isMap {
	my $self=shift;
	return $self->isValid() && $self->{Reference}->isMap();
}

=head2 isDefined()

Returns 1 if the Reference is valid and the referenced Object is defined (i.e. not a C<Data::Sofu::Undefined>).

=cut

sub isDefined {
	my $self=shift;
	return $self->isValid() && $self->{Reference}->isDefined();

}

=head2 asReference()

Returns itself

=cut

sub asReference {
	return shift;
}

#Experimental (Work with References as if they were transparent)

#sub AUTOLOAD {
#	my $self=shift;
#	my $x=$AUTOLOAD;
#	$x=~s/^.+:://g;
#	#die $x;
#	return $self->{Reference}->$x(@_);
#}

#sub DESTROY {
#	my $self=shift;
#	$self->{Reference}=undef;
#}
#


=head1 BUGS

Referencing something else than a C<Data::Sofu::Object> or derieved will not convert the referenced thing and it will confuse the write() to produce invalid sofu files. 

=head1 SEE ALSO

L<Data::Sofu>, L<Data::Sofu::Value>, L<Data::Sofu::Object>, L<Data::Sofu::Map>, L<Data::Sofu::Value>, L<Data::Sofu::Undefined>, L<http://sofu.sf.net>

=cut 

1;
