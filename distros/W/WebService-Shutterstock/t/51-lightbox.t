use strict;
use warnings;
use Test::More;
use WebService::Shutterstock::Lightbox;

my $lightbox = WebService::Shutterstock::Lightbox->new( lightbox_id => 1, lightbox_name => 'test', images => [], auth_info => {auth_token => '123', username => 'abc'}, client => 1 );
isa_ok($lightbox, 'WebService::Shutterstock::Lightbox');
is $lightbox->name, 'test', 'deferred data field - name';
is_deeply $lightbox->images, [], 'deferred data field - images';

done_testing;
