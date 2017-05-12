=head1 NAME

News::NNTPAuth - a standard NNTP authentication method (deprecated)

=head1 SYNOPSIS

Use Net::NNTP::Auth instead.

=cut

$VERSION = "1.0";
package News::NNTPAuth;
use Net::NNTP::Auth;
our $VERSION = "1.0";
our @ISA = qw( Net::NNTP::Auth );

1;
