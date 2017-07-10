package WebService::Braintree::DigestSHA256;
$WebService::Braintree::DigestSHA256::VERSION = '0.91';

use strict;
use Digest;
use Digest::SHA;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(new);
our @EXPORT_OK = qw();

sub new {
    return Digest->new("SHA-256");
}

1;
