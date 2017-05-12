###############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/xt/author/96_perlcritic.t $
#     $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 2622 $
###############################################################################

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

#-----------------------------------------------------------------------------

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

#-----------------------------------------------------------------------------

my $rcfile = File::Spec->catfile( qw<xt author perlcriticrc> );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
