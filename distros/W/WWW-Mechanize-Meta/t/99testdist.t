#
#===============================================================================
#
#         FILE:  99testdist.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Andrey Kostenko (), <andrey@kostenko.name>
#      COMPANY:  Rambler Internet Holding
#      VERSION:  1.0
#      CREATED:  24.11.2009 20:18:36 MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More;
eval "use Test::Dist;1" or plan skip_all => 'No Test::Dist';
dist_ok()


