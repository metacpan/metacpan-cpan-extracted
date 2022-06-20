# MooX::Pression was renamed Zydeco.
# This file is provided for backwards compatibility.
#
# See <http://zydeco.toby.ink/>.
#

use 5.014;
use strict;
use warnings;
package MooX::Pression;
use Zydeco ();
our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.614';
our @ISA       = 'Zydeco';
*PACKAGE_SPEC  = \&Zydeco::PACKAGE_SPEC;
1;
