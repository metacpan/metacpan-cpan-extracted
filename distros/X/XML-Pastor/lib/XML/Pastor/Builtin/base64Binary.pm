use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);


#======================================================================
package XML::Pastor::Builtin::base64Binary;
use XML::Pastor::Builtin::Scalar;
use MIME::Base64 ();

our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::base64Binary->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::base64Binary',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'base64Binary|http://www.w3.org/2001/XMLSchema',
                 
                 'regex' => qr /^([0-9a-zA-Z\+\\\=][0-9a-zA-Z\+\\\=])+$/,   # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );


#-----------------------------------------------------------------
sub toBinary {
	my $self  = shift;
	my $value = $self->__value() . "";	
	return MIME::Base64::decode($value)
}

#-----------------------------------------------------------------
sub setFromBinary($$) {
	my $self  = shift;
	return $self->__value(MIME::Base64::encode($_[0], ''));
}

#-----------------------------------------------------------------
# A CONSTRUCTOR
#-----------------------------------------------------------------
sub fromBinary($$) {
	my $self  	= shift->new();
	return $self->setFromBinary(@_);
}


1;

__END__

=head1 NAME

B<XML::Pastor::Builtin::base64Binary> - Class for the B<W3C builtin> type B<base64Binary>.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<XML::Pastor::Builtin::Scalar>. 

=head1 DESCRIPTION

B<XML::Pastor::Builtin::base64Binary> represents the B<builtin> W3C type 
B<base64Binary>. 

=head1 METHODS

=head2 INHERITED METHODS

This class inherits many methods from its ancestors. Please see L<XML::Pastor::Builtin::Scalar> for 
more methods. 

=head2 CONSTRUCTORS
 
=head4 fromBinary() 

  my $object = XML::Pastor::Builtin::base64Binary->fromBinary($binary_data)

B<CONSTRUCTOR>. 

The B<fromBinary()> constructor method instantiates a new object from a binary
data chunk. It is inheritable. The necessary conversion is done within the method.	


=head2 OTHER METHODS

=head4 setFromBinary()

	$object->setFromBinary($binary_data);
	
This method sets the value of the object from a chunk of binary data. 
The necessary conversion is done within the method.	

=head4 toBinary()

	my $binary_data = $object->toBinary();
	
This method returns the value of the object as a chunk of binary data. 
The necessary conversion is done within the method.	

.

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

