##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/t/02_fatal.lib/WithoutCriticismFatal.pm $
#    $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 2622 $
##################################################################

use criticism (-profile => '');

# Note that strictures have't been enabled, so this should generate a
# violation as soon as it is loaded.  Setting the -profile to null
# should prevent it from picking up the user's perlcriticrc, if they
# happen to have one.  Since -criticism-fatal is FALSE by default,
# then this file should load ok.

1;
