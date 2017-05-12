use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);


#======================================================================
# White space separated tokens.
#======================================================================

package XML::Pastor::Builtin::List;

use XML::Pastor::Builtin::SimpleType;

our @ISA = qw(XML::Pastor::Builtin::SimpleType);

#-----------------------------------------------------------------
sub toList {
	my $self  = shift;
	my $value = $self->__value() . "";
	my @list  = split /\s+/, $value;
	return (wantarray ? (@list) : [@list]);
}

#-----------------------------------------------------------------
sub setFromList {
	my $self  	= shift;
	return $self->__value(join (' ', @_));
}

#-----------------------------------------------------------------
# A CONSTRUCTOR
#-----------------------------------------------------------------
sub fromList {
	my $self  	= shift->new();
	return $self->setFromList(@_);
}

#--------------------------------------------------------------
sub xml_validate {
	my $self	= shift;
	my $path	= shift || '';	
	my $value	= $self->__value;
	my $type	= $self->XmlSchemaType();
	my $class	= $type->itemClass || "XML::Pastor::SimpleType";

	unless (UNIVERSAL::can($class,"xml_validate")) {
		return $self->xml_validate_further(@_);
	}
	
	my @parts	= $self->toList();
	
	foreach my $part (@parts) {
		my $object = $class->new(__value => $part);
		$object->xml_validate(@_) or die "Pastor : Validate : $path : List part '$part' does not validate against class '$class' in list '$value'!";
	}
	return $self->xml_validate_further(@_);		
}


1;

__END__

=head1 NAME

B<XML::Pastor::Builtin::List> - Ancestor of all classes that correspond to whitespace separated B<list> W3C simple types.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<XML::Pastor::Builtin::SimpleType>. 

=head1 DESCRIPTION

This class is used for grouping the B<builtin> classes that 
have whitespace separated B<list> content. Some utility methods are
defined for easing the use of such content. 

Some B<builtin> W3C types have a B<list> nature on their own, such as B<NMTOKENS> (whitespace
seperated B<NMTOKEN> values) or B<IDREFS>. 

In W3C schemas it is also possible to define a simple type to be a B<list> of another atomic simple type.

=head1 METHODS

=head2 INHERITED METHODS

This class inherits many methods from its ancestors. Please see L<XML::Pastor::Builtin::SimpleType> for 
more methods. 

=head2 CONSTRUCTORS

=head4 fromList()

  my $object = XML::Pastor::Builtin::List->fromList('hello', 'world');

Creates a new object and sets its value by joining the values passed as the
parameter list with a space seperator.

=head2 OTHER METHODS

=head4 setFromList()

  $object->setFromList('hello', 'world');

Sets the object's value by joining the values passed as the parameter list with a space seperator.

=head4 toList()

  @list = $object->toList();

Splits the object's value on whitespace and returns the resulting list. 

=head4 xml_validate()

  $object->xml_validate();

B<OBJECT METHOD> overriden from L<XML::Pastor::SimpleType>.

Normaly the B<xml_validate> method checks an atomic value. However, B<list> types
are aggregate values made up of B<items> whose type is known via B<itemType> and 
B<itemClass> properties (see L<XML::Pastor::Schema::SimpleType>). 

This method will first split the object's value into a list and then run B<xml_validate> on each 
item by instantiating an simple type object on their own and invoking the B<xml_validate> method
on each of them. If I<all> those invocations return TRUE, this method will return TRUE. Otherwise,
it would have died along the way before even returning FALSE.


=head1 BUGS & CAVEATS

There no known bugs at this time, but this doesn't mean there are aren't any. 
Note that, although some testing was done prior to releasing the module, this should still be considered alpha code. 
So use it at your own risk.

Note that there may be other bugs or limitations that the author is not aware of.

=head1 AUTHOR

Ayhan Ulusoy <dev(at)ulusoy(dot)name>


=head1 COPYRIGHT

  Copyright (C) 2006-2007 Ayhan Ulusoy. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

See also L<XML::Pastor>, L<XML::Pastor::ComplexType>, L<XML::Pastor::SimpleType>, L<XML::Pastor::Builtin>

If you are curious about the implementation, see L<XML::Pastor::Schema::Parser>,
L<XML::Pastor::Schema::Model>, L<XML::Pastor::Generator>.

 
=cut

