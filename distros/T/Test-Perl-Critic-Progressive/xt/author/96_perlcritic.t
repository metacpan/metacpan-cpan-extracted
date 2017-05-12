###############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Test-Perl-Critic-Progressive-0.03/xt/author/96_perlcritic.t $
#     $Date: 2008-07-27 16:01:56 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 2620 $
###############################################################################

use strict;
use warnings;

use English qw< -no_match_vars >;

use File::Spec;

my $rcfile;
BEGIN {
    $rcfile = File::Spec->catfile( qw< xt author perlcriticrc > );
}

use Test::Perl::Critic -profile => $rcfile;
all_critic_ok();
