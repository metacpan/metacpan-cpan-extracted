use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);


#======================================================================
package XML::Pastor::Builtin::hexBinary;

use XML::Pastor::Builtin::Scalar;

our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::hexBinary->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::hexBinary',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'hexBinary|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr/^([0-9a-fA-F][0-9a-fA-F])+$/,  # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );



1;

__END__

=head1 NAME

B<XML::Pastor::Builtin::hexBinary> - Class for the B<W3C builtin> type B<hexBinary>.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<XML::Pastor::Builtin::Scalar>. 

=head1 DESCRIPTION

B<XML::Pastor::Builtin::hexBinary> represents the B<builtin> W3C type 
B<hexBinary>. 

=head1 METHODS

=head2 INHERITED METHODS

This class inherits many methods from its ancestors. Please see L<XML::Pastor::Builtin::Scalar> for 
more methods. 


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

