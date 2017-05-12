package XML::DOM2::DOM::Attribute;

use base "XML::DOM2::DOM::NameSpace";

use strict;
use warnings;

=head2 $attribute->ownerElement()

  Return the owner of the attribute (element)

=cut
sub ownerElement
{
	return $_[0]->{'owner'};
}

return 1;
