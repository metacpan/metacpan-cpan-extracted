#===============================================================================
#
#  DESCRIPTION:  Test published attr
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================

package main;
use strict;
use warnings;
use Test::More tests => 14;                      # last test to print
#use Test::More 'no_plan';                      # last test to print

use Data::Dumper;
use WriteAt;
use utf8;
use_ok('WriteAt');
my $t = <<T;
=begin pod
=for CHAPTER :published<'2012-11-27T09:39:19Z'> :tag<intro>
Test chapter
=head1 Test name
test
=head2 test

yes

=for head2 :published<'2013-11-27T09:35:00Z'>

Test

=end pod
T



#test Writeat::UtilCTX
my $c = new WriteAt::UtilCTX:: (filter_time=>&WriteAt::get_time_stamp_from_string('2012-11-27T09:40:19Z'));
 $c->switch_head_level( 0, 4);
 is $c->get_current_level_time(), 4, 'level time for =h1';
 is $c->switch_head_level( 1, 5),0, '0->1 level';
 is $c->get_current_level_time(), 5, 'level time for =h2';
 is $c->switch_head_level( 0),1, '1->0 level';
 is $c->get_current_level_time(), 4, 'level time for =h1';
 is $c->switch_head_level( 1, 7),0, '0->1 level';
 is $c->switch_head_level( 2, 6 ),1, '1->2 level';

 is $c->switch_head_level( 1, 8 ),2, '2->1 level';
 is $c->get_current_level_time(), 8, 'level time for =h1';

 my $tree = Perl6::Pod::Utl::parse_pod( $t, default_pod =>0 )
  || die "Can't parse ";
 $tree = &WriteAt::filter_published($tree,'2013-10-27T09:40:19Z' );
 is scalar(@{ $tree->[0]->{content} }), 4, 'filter =head2';
my $t2 = <<TXT;
=CHAPTER Test chapter
=for head1 :published<'2013-04-27T09:35:00Z'>
Test name

test
=head2 test

yes

=for head1 :published<'2013-04-28T09:35:00Z'>

Test

TXT
 my $tree2 = Perl6::Pod::Utl::parse_pod( $t2, default_pod =>1 )
  || die "Can't parse ";

 my $t21 = &WriteAt::filter_published($tree2,'2010-04-28T09:30:00Z' );
 is scalar(@{$t21}), 0, "empty"; 

 my $t22 = &WriteAt::filter_published($tree2,'2013-04-27T09:35:01Z' );
 is scalar(@$t22),4, 'head1+para';

 my $t23 = &WriteAt::filter_published($tree2,'2015-04-26T09:35:01Z' );
 is scalar(@$t23),6, 'head1+head1+para';

