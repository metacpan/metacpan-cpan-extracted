###############################################################################
#Undefined.pm
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

Data::Sofu::Undefined - A Sofu non type

=head1 DESCRIPTION

Provides a interface similar to the original SofuD (sofu.sf.net)

This Object is similar to Perl's undef .

It is nothing (not even a C<Data::Sofu::Value>) but it is still there (in Lists or Maps for example)


=head1 Synopsis 

	require Data::Sofu::Undefined;
	require Data::Sofu::Map;
	my $u = Data::Sofu::Undefined->new();
	my $map = Data::Sofu::Map->new();
	$map->setAttribute("Nx",$u);
	$map->hasMap("Nx"); # Returns 0
	$map->hasValue("Nx"); # Returns 0
	$map->hasAttribute("Nx"); # Returns 1
	# It is also there in $map->each() and $map->next();	

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut


package Data::Sofu::Undefined;

use strict;
use warnings;
require Data::Sofu::Object;
require Data::Sofu::List;
our @ISA = qw/Data::Sofu::Object/;
our $VERSION="0.29";

=head1 METHODS

Also look at C<Data::Sofu::Object> for methods, cause Undefined inherits from it

=head2 new()

Creates a new C<Data::Sofu::Undefined> and returns it

	$val = Data::Sofu::Undefined->new();

=cut 


sub new {
	my $self={};
	bless $self,shift;
	return Data::Sofu::Value(@_) if @_;
	return $self;
}

=head2 isDefined()

Returns false

=cut

sub isDefined {
	return 0;
}

=head2 C<stringify(LEVEL, TREE)>

Returns the string representation of this Object.

Which is the string "UNDEF"

LEVEL and TREE are ignored.

=cut

sub stringify {
	my $self=shift;
	my $level=shift;
	my $tree=shift;
	return "Value = UNDEF".$self->stringComment()."\n" unless $level;
	return "UNDEF".$self->stringComment()."\n";
}

=head2 C<binarify(TREE, BDRIVER)>

Returns a binary representation of this Object. Don't call this (will be called from packBinary() and writeBinary())

=cut

sub binarify {
	my $self=shift;
	my $tree=shift;
	my $bin=shift;
	my $str=$bin->packType(0);
	$str.=$self->packComment($bin);
	return $str;
}


=head1 BUGS

This still tests true when using:

	my $u=Data::Sofu::Undefined->new();
	if ($u) { 
		#This will happen.
	}
	if ($u->isDefined()) { 
		#This will not happen.
	}

=head1 SEE ALSO

L<Data::Sofu>, L<Data::Sofu::Value>, L<Data::Sofu::Object>, L<Data::Sofu::Map>, L<Data::Sofu::Value>, L<Data::Sofu::Reference>, L<http://sofu.sf.net>

=cut 

1;
