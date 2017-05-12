use strict;
use warnings;

use Test::More;

eval {
    require Test::Pod;
    Test::Pod->import();
};
plan skip_all => "Test::Pod required for testing POD" if $@;

all_pod_files_ok();

1;

__END__

Copyright 2013 APNIC Pty Ltd.

This library is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The full text of the license can be found in the LICENSE file included
with this module.

