##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/t/00_compile.t $
#    $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 174 $
##################################################################

use strict;
use warnings;
use Test::More tests => 8;

use_ok('criticism');
can_ok('criticism', 'import');

#-----------------------------------------------------------------------------

my @moods = qw( gentle stern harsh cruel brutal );
for my $mood ( @moods ) {
    use_ok('criticism', $mood);
}

#-----------------------------------------------------------------------------

eval { criticism->import( 'foo' ) };
like($@, qr/"foo" criticism/m, 'invalid mood');

#-----------------------------------------------------------------------------
