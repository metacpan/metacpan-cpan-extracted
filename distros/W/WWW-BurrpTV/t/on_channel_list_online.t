use Test::More;
#use warnings;
#use strict;


#plan tests => 2;

use_ok('WWW::BurrpTV');


SKIP: {

my $tv;

eval { $tv = WWW::BurrpTV->new(); };

	#skip ("Error while connecting. Online test skipped.",1) if $@;
	if ($@) { plan skip_all => 'lol'; }
	my $list = $tv->channel_list;
	is($list->{'Star Movies'}, 'http://tv.burrp.com/channel/star-movies/59/', 'Channel list retrieval');
};

done_testing();


