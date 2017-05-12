#!perl

use Test::More;
use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('MyApp');

$t->get_ok('/products')
->dive_in('#products ')
    ->element_count_is('> li', 3)
    ->dive_in('li:first-child ')
        ->element_count_is('a', 1)
        ->dived_text_is('a[href="/product/1"]' => 'Product 1')
    ->element_count_is('+ li > a', 1)
        ->dived_text_is('+ li > a[href="/products/Cat1"]' => 'Cat 1')
    ->dive_in('+ li > ul ')
        ->element_count_is('> li', 2)
        ->element_count_is('a', 2)
        ->dived_text_is('a[href="/product/2"]' => 'Product 2')
        ->dived_text_is('a[href="/product/3"]' => 'Product 3')
    ->dive_out('> ul')
    ->element_count_is('+ li a', 1);
->dive_reset
->element_count_is('#products + p', 1)
->text_is('#products + p' => 'Select a product!')

done_testing;

__END__

Tests this structure:

    <ul id="products">
        <li><a href="/product/1">Product 1</a></li>
        <li>
            <a href="/products/Cat1">Cat 1</a>
            <ul>
                <li><a href="/product/2">Product 2</a></li>
                <li><a href="/product/3">Product 3</a></li>
            </ul>
        </li>
        <li><a href="/product/2">Product 2</a></li>
    </ul>

    <p>Select a product!</p>