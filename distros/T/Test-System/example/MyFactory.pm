#
# MyFactory
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/23/2009 14:08:47 CST 14:08:47
package MyFactory;

use strict;
use warnings;
use Test::System::Output::Factory;
use base qw(Test::System::Output::Factory);

Test::System::Output::Factory->register_factory_type(foo => 'TAP::FooBar');


1;

