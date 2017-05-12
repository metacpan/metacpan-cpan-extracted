use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'autobox';

use autobox DEFAULT => 'MyDefault';
use Test::Should::Engine;
use Test::More;

{
    package MyDefault;
    our $AUTOLOAD;
    sub AUTOLOAD {
        $AUTOLOAD =~ s/.*:://;
        my $test = Test::Should::Engine->run($AUTOLOAD, @_);
        Test::More->builder->ok($test, "$_[0] $AUTOLOAD" . ($_[1] ? " $_[1]" : ''));
    }
}

{
    package UNIVERSAL;
    sub DESTROY { }
    our $AUTOLOAD;
    sub AUTOLOAD {
        $AUTOLOAD =~ s/.*:://;
        my $test = Test::Should::Engine->run($AUTOLOAD, @_);
        Test::More->builder->ok($test, "$_[0] $AUTOLOAD" . ($_[1] ? " $_[1]" : ''));
    }
}

# and test code
1->should_be_ok();
0->should_not_be_ok();

(bless [], 'Foo')->should_be_ok();
(bless [], 'Foo')->should_be_a('Foo');
(bless [], 'Foo')->should_not_be_a('Bar');

done_testing;

