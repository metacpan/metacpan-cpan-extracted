#!perl
use 5.14.1;
use warnings;

use Test::More;

package Foo {
    use Moo;
    with 'Twitter::API::Trait::NormalizeBooleans';

    # required
    sub preprocess_args {}
}

my $args = {
    foo           => 'bar',
    include_email => 1,
    skip_user     => 't',
    skip_status   => '',
    text          => 'test',
};

my $foo = Foo->new;
$foo->normalize_bools($args);

is_deeply $args, {
    foo           => 'bar',
    include_email => 'true',
    skip_user     => 'true',
    text          => 'test',
}, 'normalized';

done_testing;
