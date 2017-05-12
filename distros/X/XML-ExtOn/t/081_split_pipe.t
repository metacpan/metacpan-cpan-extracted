#===============================================================================
#
#  DESCRIPTION:  test split pipe to filters array
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id: 081_split_pipe.t 845 2010-10-13 08:11:10Z zag $
#use Test::More qw( no_plan);
use Test::More tests => 3;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::ExtOn', 'split_pipe', 'create_pipe';
    use_ok 'XML::ExtOn::Writer';
}

my $filter = create_pipe( 'MyHandler1', 'MyHandler2','MyHandler3');
my $ref = @{ split_pipe( $filter) } [-1];
isa_ok $ref,  'MyHandler3', 'check last element';

package MyHandler1;
use base 'XML::ExtOn';
use strict;
use warnings;
1;
package MyHandler2;
use base 'XML::ExtOn';
use strict;
use warnings;
1;
package MyHandler3;
use base 'XML::ExtOn';
use strict;
use warnings;
1;
