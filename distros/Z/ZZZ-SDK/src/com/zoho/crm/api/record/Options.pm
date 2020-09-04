require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';
package record::Options;
use Moose;
sub new
{
	my ($class) = shift;
	my $self = 
	{
	};
	bless $self,$class;
	return $self;
}

1;