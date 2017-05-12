
package XML::SRS::Keyring;
BEGIN {
  $XML::SRS::Keyring::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use Moose::Util::TypeConstraints;

subtype 'XML::SRS::PGP::PubKey'
	=> as "Str"
	=> where {
	m{\A-----BEGIN PGP PUBLIC KEY} &&
		m{-----END PGP PUBLIC KEY.*\Z};
	};

has_element 'keys' =>
	is => "rw",
	isa => "ArrayRef[Str]",
	xml_nodeName => "EncryptKey",
	;

with 'XML::SRS::Node';

1;
