use Test::More;

use XML::XSS;

my $xss = XML::XSS->new;

$xss->set( 'foo' => {
        pre => 'one',
        showtag => 'two',
    } );

$xss->set( '#comment' => {
        rename => 'comment',
    } );

is_deeply [ $xss->get('#comment')->style_attributes ], [ sort qw/ process pre
showtag rename post filter replace / ];
is_deeply { $xss->get('#comment')->style_attribute_hash }, {
    rename => 'comment',
};
is_deeply { $xss->get('#comment')->style_attribute_hash(all=>1) }, {
    rename => 'comment',
    map { $_ => undef } qw/  process pre showtag post filter replace
    /,
};

done_testing;
