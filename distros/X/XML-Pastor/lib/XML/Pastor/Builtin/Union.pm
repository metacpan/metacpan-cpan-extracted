use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);


#======================================================================
package XML::Pastor::Builtin::Union;

use XML::Pastor::Builtin::SimpleType;

our @ISA = qw(XML::Pastor::Builtin::SimpleType);

#--------------------------------------------------------------
sub xml_validate {
	my $self	= shift;
	my $path	= shift || '';	
	my $type	= $self->XmlSchemaType();
	my $value	= $self->__value;
	my $members	= $type->memberClasses || [];
	
	unless (@$members) {
		return 1;
	}
	
	foreach my $class (@$members) {
		if (UNIVERSAL::can($class,"xml_validate")) {		
			my $object = $class->new(__value => $value);
			if ($object->xml_validate(@_)) {
				return 1;
			}
		}
	}
	
	die "Pastor : Validate : $path : None of the union members validate value '$value'";
}

1;

__END__

=head1 NAME

B<XML::Pastor::Builtin::Union> - Ancestor of all classes that correspond to whitespace separated B<union> W3C simple types.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<XML::Pastor::Builtin::SimpleType>. 

=head1 DESCRIPTION

This class is used for grouping the B<builtin> classes that 
have whitespace separated B<union> content. 

In W3C schemas it is possible to define a simple type to be a B<union> of other simple types.

=head1 METHODS

=head2 INHERITED METHODS

This class inherits many methods from its ancestors. Please see L<XML::Pastor::Builtin::SimpleType> for 
more methods. 

=head2 OTHER METHODS

=head4 xml_validate()

  $object->xml_validate();

B<OBJECT METHOD> overriden from L<XML::Pastor::SimpleType>.

Normaly the B<xml_validate> method checks an atomic value. However, B<union> types
are aggregate types whose values may correspond to a value from any of the 
member types. The member types are known via the B<memberTypes> and 
B<memberClasses> properties (see L<XML::Pastor::Schema::SimpleType>). 

For each B<memberClass>, this method will instatiate an object and run B<xml_validate> on it.
If any of these invocations return TRUE, this method will also return TRUE. If all I<die>, this 
method will then I<die> with an error message. 

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
