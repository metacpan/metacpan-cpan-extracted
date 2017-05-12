use lib 't';
use t   '6';

$content = '{"value":[{}]}';

$drv->find('foo');

reqs_are [
    [ POST => '/elements', { using => 'css selector', value => 'foo' } ],
], '->find("foo")';

$drv->find( 'bar', method => 'css' );

reqs_are [
    [ POST => '/elements', { using => 'css selector', value => 'bar' } ],
], '->find( "bar", method => "css" )';

$drv->find( 'baz', method => 'ecmascript' );

reqs_are [
    [ POST => '/elements', { using => 'ecmascript', value => 'baz' } ],
], '->find( "baz", method => "ecmascript" )';

$drv->find( 'qux', method => 'link_text' );

reqs_are [
    [ POST => '/elements', { using => 'link text', value => 'qux' } ],
], '->find( "qux", method => "link_text" )';

$drv->find( 'quux', method => 'partial_link_text' );

reqs_are [
    [ POST => '/elements', { using => 'partial link text', value => 'quux' } ],
], '->find( "quux", method => "partial_link_text" )';

$drv->find( 'corge', method => 'xpath' );

reqs_are [
    [ POST => '/elements', { using => 'xpath', value => 'corge' } ],
], '->find( "corge", method => "xpath" )';
