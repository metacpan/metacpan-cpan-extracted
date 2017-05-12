#########
# Author:        rmp
# Last Modified: $Date: 2007/07/16 21:31:47 $ $Author: zerojinx $
# Id:            $Id: 00-critic.t,v 1.1 2007/07/16 21:31:47 zerojinx Exp $
# Source:        $Source: /cvsroot/xml-feedlite/xml-feedlite/t/00-critic.t,v $
# $HeadURL$
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

if ( not $ENV{TEST_AUTHOR} ) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval {
  require Test::Perl::Critic;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Perl::Critic not installed';

} else {
  Test::Perl::Critic->import(
			     -severity => 1,
			     -exclude => ['tidy'],
			    );
  all_critic_ok();
}

1;
