# $Id: test.pl,v 1.17 2004/01/03 19:09:42 cvspub Exp $
use Test::More qw(no_plan);
ok(1);
use Data::Dumper;
use ExtUtils::testlib;

BEGIN {
    print "The test needs internet connection. Be sure to get connected, or you will get several error messages.\n";

    use_ok 'WWW::Google::Groups';
    $group = 'comp.lang.perl.misc';
    $target = $group;
    open F, ".proxy";
    chomp ($proxy=<F>);
    close F;
    unlink ".proxy";
}

END{
    unlink $target;
}


use subs qw(search step_by_step all_in_one);


search();
all_in_one();
step_by_step();




sub search {
    $agent = new WWW::Google::Groups(
				     server => 'http://groups.google.com',
				     proxy => $proxy,
				     );
    $result = $agent->search(
			 query => 'groups',
			     );
    
    
    if( $thread = $result->next_thread ){
	ok(ref($thread));
	
	$article = $thread->next_article();
	ok(ref($article));
	
	$article = $thread->next_article('raw');
	ok(!ref($article));
    }
}


sub step_by_step {
    $agent = new WWW::Google::Groups(
				     server => 'http://groups.google.com',
				     proxy => $proxy,
				     );
    ok(ref($agent));
    
    $group = $agent->select_group($group);
    ok(ref($group));
    
    if( $thread = $group->next_thread() ){
	ok(ref($thread));
	
	$article = $thread->next_article();
	ok(ref($article));
	
	ok($thread->title);
	ok($article->header('From'));
	ok($article->body);
    }
}

sub all_in_one {
    $agent = new WWW::Google::Groups(
				     server => 'http://groups.google.com',
				     proxy => $proxy,
				     );

    ok($agent->save2mbox(
			 group => $group,
			 starting_thread => 0,
#		     max_article_count => 2,
			 max_thread_count => 2,
			 target_mbox => $target,
			 ));
    ok(-f $target);

}
