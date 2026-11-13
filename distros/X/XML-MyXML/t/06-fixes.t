use strict;
use warnings;
use utf8;

use Test::More;

use XML::MyXML qw(:all);

my $obj = xml_to_object('<a>0</a>');
is $obj->text, '0', '0 in text';

my $foo = simple_to_xml {
    foo => {
        '!as_is' => '<g>123</g>',
    },
};
is $foo, '<foo><g>123</g></foo>', '!as_is';

$obj = xml_to_object(<<EOB);
<foo x="
    alex
    john
" y="mary"/>
EOB
is $obj->attr('x'), <<EOB, 'attributes with newline characters';

    alex
    john
EOB

$obj = xml_to_object('<a v="x=" h="y"/>');
is $obj->attr('v'), 'x=', 'v attribute';
is $obj->attr('h'), 'y', 'h attribute';

$obj = xml_to_object('<a v  =  "x=" h    =     "y"          />');
is $obj->attr('v'), 'x=', 'v attribute, spaces between';
is $obj->attr('h'), 'y', 'h attribute, spaces between';

done_testing;
