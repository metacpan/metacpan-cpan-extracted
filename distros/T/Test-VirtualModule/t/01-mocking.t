use strict;
use Test::VirtualModule qw/BlahBlahBlah/;
use BlahBlahBlah;

use Test::More tests => 3;

use_ok('BlahBlahBlah', 'Mocked module BlahBlahBlah loaded');

Test::VirtualModule->mock_sub('BlahBlahBlah',
    new => sub {
    	my $self = {};
	bless $self, 'BlahBlahBlah';
	return $self;
    },
);

ok(BlahBlahBlah->can('new'), 'Sub mocked ok');
my $blah = BlahBlahBlah->new();
is(ref $blah, 'BlahBlahBlah', 'Object is proper reference');

