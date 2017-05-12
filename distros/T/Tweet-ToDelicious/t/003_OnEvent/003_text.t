use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'text' => sub {
    my $entity = onevent( { target_object => { text => 'hehehe' } } );
    is $entity->text, 'hehehe';
};

done_testing;
