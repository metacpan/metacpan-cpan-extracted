# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2011-05-29 22:56:18 +0100 (Sun, 29 May 2011) $
# Id:            $Id: 00-critic.t 11 2011-05-29 21:56:18Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/www-scraper-lite/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my ($r) = q$Revision: 11 $ =~ /(\d+)/smx; $r; };

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
					     ValuesAndExpressions::ProhibitImplicitNewlines
					     NamingConventions::Capitalization
					     PodSpelling
 					     ValuesAndExpressions::RequireConstantVersion)],
			    );
  all_critic_ok(qw(lib bin));
}

1;
