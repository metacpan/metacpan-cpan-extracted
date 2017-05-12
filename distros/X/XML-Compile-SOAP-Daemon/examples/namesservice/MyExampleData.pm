# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package MyExampleData;
use vars '$VERSION';
$VERSION = '3.12';

use base 'Exporter';

our @EXPORT = qw/$namedb/;

our $namedb =
 { Netherlands =>
    {   male  => [ qw/Mark Tycho Thomas/ ]
    , female  => [ qw/Cleo Marjolein Suzanne/ ]
    }
 , Austria     =>
    {   male => [ qw/Thomas Samuel Josh/ ]
    , female => [ qw/Barbara Susi/ ]
    }
 ,German       =>
    {   male => [ qw/Leon Maximilian Lukas Felix Jonas/ ]
    , female => [ qw/Leonie Lea Laura Alina Emily/ ]
    }
 };

1;
