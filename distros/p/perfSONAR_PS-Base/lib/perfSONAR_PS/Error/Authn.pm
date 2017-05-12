use perfSONAR_PS::Error;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Error::Authn - A module that provides the exceptions for the
authenicationframework for perfSONAR PS

=head1 DESCRIPTION

This module provides the authenication exception objects.

head1 API

=cut


package perfSONAR_PS::Error::Authn;
use base "perfSONAR_PS::Error";


package perfSONAR_PS::Error::Authn::WrongParams;
use base "perfSONAR_PS::Error::Authn";

package perfSONAR_PS::Error::Authn::AssertionNotIncluded;
use base "perfSONAR_PS::Error::Authn";

package perfSONAR_PS::Error::Authn::AssertionNotValid;
use base "perfSONAR_PS::Error::Authn";

package perfSONAR_PS::Error::Authn::x509NotIncluded;
use base "perfSONAR_PS::Error::Authn";

package perfSONAR_PS::Error::Authn::x509NotValid;
use base "perfSONAR_PS::Error::Authn";

package perfSONAR_PS::Error::Authn::NotSecToken;
use base "perfSONAR_PS::Error::Authn";


1;
