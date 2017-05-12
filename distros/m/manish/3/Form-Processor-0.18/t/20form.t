use strict;
use warnings;
use Test::More;
my $tests = 7;
plan tests => $tests;

use_ok( 'Form::Processor' );

my $form = my_form->new;


ok( !$form->validate, 'Empty data' );

$form->clear;

my $good = {
    reqname => 'hello',
    optname => 'not req',
    fruit   => 2,
};

ok( $form->validate( $good ), 'Good data' );



my $bad_1 = {
    optname => 'not req',
    fruit   => 4,
};

$form->clear;
ok( !$form->validate( $bad_1 ), 'bad 1' );


ok( $form->field('fruit')->has_error, 'fruit has error' );
ok( $form->field('reqname')->has_error, 'reqname has error' );
ok( !$form->field('optname')->has_error, 'optname has no error' );

$form->clear;



package my_form;
use strict;
use warnings;
use base 'Form::Processor';

sub profile {
    return {
        required    => {
            reqname     => 'Text',
            fruit       => 'Select',
        },
        optional    => {
            optname     => 'Text',
        },
    };
}

sub options_fruit {
    return (
        1   => 'apples',
        2   => 'oranges',
        3   => 'kiwi',
    );
}







