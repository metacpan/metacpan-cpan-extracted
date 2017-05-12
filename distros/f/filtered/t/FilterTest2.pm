package FilterTest2::internal;

sub call
{
	return 'FOOFOOFOOFOO';
}

package FilterTest2;

use strict;

require Exporter;
our (@ISA) = qw(Exporter);
our (@EXPORT_OK) = qw(call);

sub call
{
    return FilterTest2::internal::call();
}

1;
