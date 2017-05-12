##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/t/02_fatal.lib/WithCriticismFatal.pm $
#    $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 2622 $
##################################################################

use criticism (-profile => '', '-criticism-fatal' => 1);

# Note that strictures have't been enabled, so this should generate
# a violation as soon as it is loaded.  Setting the -profile to null
# should prevent it from picking up the user's perlcriticrc, if they
# happen to have one.  And since -criticism-fatal is TRUE, then this
# file should fail to load.

1;
