# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-11-10 16:33:37 +0000 (Sat, 10 Nov 2012) $
# Id:            $Id: 00-critic.t 75 2012-11-10 16:33:37Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = 1;

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
			     -exclude => [qw(CodeLayout::RequireTidyCode
					     NamingConventions::Capitalization
					     PodSpelling
 					     ValuesAndExpressions::RequireConstantVersion
					     ControlStructures::ProhibitDeepNests)],
			    );
  all_critic_ok();
}

1;
