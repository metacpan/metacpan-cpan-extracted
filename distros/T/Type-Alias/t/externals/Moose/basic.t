use strict;
use warnings;
use Test::More;
use Test::Requires qw( Moose Exporter );

use lib qw( ./t/externals/Moose/lib );

use Sample qw( UserName );

my $sample = Sample->new(name => 'hello');
isa_ok $sample, 'Sample';

eval { $sample->name('') };
ok $@, 'invalid name';

ok UserName->check('hello');
ok !UserName->check('');

done_testing;
