# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::SandboxValues::TransactionAmount;

use 5.010_001;
use strictures 1;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(AUTHORIZE DECLINE FAILED);
our @EXPORT_OK = qw();

use constant AUTHORIZE => 1000;
use constant DECLINE   => 2000;
use constant FAILED    => 3000;

1;
__END__
