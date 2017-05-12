#!perl -T

use strict;
use warnings;
use Test::More;
use WWW::Myspace;

#eval "use Test::Exception";
#plan skip_all => "Test::Exception not installed" if $@;

my $myspace = WWW::Myspace->new( auto_login => 0);

plan tests => 6;

my $friend_id = $myspace->friend_id('greatbigseaofficial');
ok ($friend_id, "got friend id: $friend_id");

my $views = $myspace->profile_views( friend_id => $friend_id );
ok ($views, "got $views profile views");

my $page = $myspace->get_profile($friend_id);
ok ( $page, "got a page from friend_id");

my $views_from_page = $myspace->profile_views( page => $page );
ok ($views_from_page, "got $views_from_page views based on page" );

my $comments = $myspace->comment_count( page => $page );
ok ( $comments, "got $comments comments from page");

$comments = $myspace->comment_count( 76772500 );
is ( $comments, 0, "detected that profile has zero comments");

#SKIP: {
#    skip "Test::Exception not installed", 1 if $@;
#    require Test::Exception;    
#   dies_ok { $myspace->profile_views } 'expecting to die';
#}
