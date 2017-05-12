use Test::More;
use File::Basename qw(dirname);
use strict;
use warnings;

use lib dirname($0);

use_ok('My::Package');

#ok(exists $My::Package::Foo, "Can find variable");
{
    no warnings 'once';
    is($My::Package::Foo, 'Done.', "Can read variable");
}

done_testing();
