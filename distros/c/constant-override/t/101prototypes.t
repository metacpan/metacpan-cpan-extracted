use warnings;
use strict;

# Regression test for prototypes on constant functions.

use constant::override;

use Test::More tests => 1;
ok(1);

package FirstPackage;

use constant ONE => 'TWO';

package SecondPackage;

sub test
{
    return FirstPackage::ONE 
         ? FirstPackage::ONE 
         : FirstPackage::ONE;
}

1;

__END__

Copyright 2013 APNIC Pty Ltd.

This library is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The full text of the license can be found in the LICENSE file included
with this module.

