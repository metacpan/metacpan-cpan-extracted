use lib 't';
use t   '6';

$content = '{"value":[{"foo":"bar"}]}';

$drv->('foo');

reqs_are [
    [ POST => '/elements', { using => 'css selector', value => 'foo' } ],
], '->("foo")';

$drv->( 'bar', method => 'css' );

reqs_are [
    [ POST => '/elements', { using => 'css selector', value => 'bar' } ],
], '->( "bar", method => "css" )';

$drv->( 'baz', method => 'ecmascript' );

reqs_are [
    [ POST => '/elements', { using => 'ecmascript', value => 'baz' } ],
], '->( "baz", method => "ecmascript" )';

$drv->( 'qux', method => 'link_text' );

reqs_are [
    [ POST => '/elements', { using => 'link text', value => 'qux' } ],
], '->( "qux", method => "link_text" )';

$drv->( 'quux', method => 'partial_link_text' );

reqs_are [
    [ POST => '/elements', { using => 'partial link text', value => 'quux' } ],
], '->( "quux", method => "partial_link_text" )';

$drv->( 'corge', method => 'xpath' );

reqs_are [
    [ POST => '/elements', { using => 'xpath', value => 'corge' } ],
], '->( "corge", method => "xpath" )';
