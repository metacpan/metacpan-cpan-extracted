use Test::More;
use warnings;
use strict;

plan tests => 5;


use_ok('WWW::BurrpTV');
my $tv = WWW::BurrpTV->new(cache => 't/files');
isa_ok($tv, 'WWW::BurrpTV');

my $list = $tv->channel_list;

is($list->{'Star Movies'}, 'http://tv.burrp.com/channel/star-movies/59/', 'Channel list retrieval');

my $shows;



SKIP: {

my $tv = WWW::BurrpTV->new(cache => 't/files');

eval { $shows = $tv->get_shows(channel => 'Discovery Channel'); };

if ($@) { 
          diag ('skipped');
          skip 'Unable to connect to website',2;
	}
	
	
else {
       is($$shows[0]->{_channel}, 'Discovery Channel', 'Listing parse (channel name)');
     }
     
eval { $shows = $tv->get_shows(channel => 'STAR WORLD', timezone => 'Asia/Taipei'); };

if ($@) { print STDERR $@;
          diag ('skipped');
          skip 'Unable to connect to website',2;
	}
	
else {
my ($am_or_pm) = $$shows[0]->{_time12} =~ /(.{2})$/;
$am_or_pm =~ s/a/P/i;

is($am_or_pm,'PM','Listing parse (Time)');

}
     
     
     
}
