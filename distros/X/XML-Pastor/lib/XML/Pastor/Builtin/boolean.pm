use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

#======================================================================
package XML::Pastor::Builtin::boolean;
use XML::Pastor::Builtin::Scalar;

our @ISA = qw(XML::Pastor::Builtin::Scalar);

use overload 
	'bool'	=> \&boolify;
	
	
XML::Pastor::Builtin::boolean->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::boolean',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'enumeration' => {
                 					'0' => '1',
                 					'1' => '1',
                 					'false' => '1',
                 					'true' => '1',                 					
                 				  },
                 'name' => 'boolean|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#----------------------------------------------
# Boolean value.
#----------------------------------------------
sub boolify {
	my $self = shift;
	my $val = $self->__value();	
	
	return 0 if ($val =~ /false/io);
	return $val;	
}

1;

__END__

=head1 NAME

B<XML::Pastor::Builtin::boolean> - Class for the B<W3C builtin> type B<boolean>.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<XML::Pastor::Builtin::Scalar>. 

=head1 DESCRIPTION

B<XML::Pastor::Builtin::boolean> represents the B<builtin> W3C type 
B<boolean>. Mainly it serves to override the L</boolify> method 
for overloading (see L</boolify>). 

=head1 METHODS

=head2 INHERITED METHODS

This class inherits many methods from its ancestors. Please see L<XML::Pastor::Builtin::Scalar> for 
more methods. 

=head2 OTHER METHODS

=head4 boolify()

	$object->boolify();
	
The B<boolify()> method is used for overloading the 'bool' operation in L<XML::Pastor::SimpleType>.
Normally the string 'I<false>' will have a TRUE(1) value in Perl (since it is a non-null string). This
method will make sure that the 'I<false>' literal value will pass as a FALSE(0) value while the overload 
is in use. Other values behave normally, that is :

=over

=item * 0 => FALSE

=item * 1 => TRUE

=item * 'true' => TRUE

=item * 'false' => B<FALSE>

=item * any other numeric or non-null string => TRUE

=back

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

