use strict;
use warnings;

use lib './lib';

use Test::More tests => 18;

use YAX::Parser;
use YAX::Constants qw/:all/;

my $xmlstr = <<XHTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta content="895" name="ku-session-keeper" id="ku-session-keeper" />
    <script src="/kudu/jslib/ku/core.js" type="text/javascript" />
    <link rel="stylesheet" href="/kudu/css/default.css" />
</head>
<body>
    <?pi data="foobar" ?>
    <div ku:replace="header" />
    <div ku:include="content" />
    <form ku:action="doit">...</form>
    <script type="text/javascript" id="my-script"><![CDATA[
    if ( foo > 42 ) {
        alert("cheese");
    }
    ]]>
    </script>
    <div foo="bar" baz="quux">This is My Div</div>
</body>
</html>
XHTML

my $parser = YAX::Parser->new();
my $document = $parser->parse( $xmlstr );
ok( $document );
ok( $document->root );
my $root = $document->root;
is( $root->name, 'html' );
my $script = $document->get('my-script');
ok( $script );
is( $document->{'my-script'}, $script );
ok( $document->{'my-script'}->[0]->data );
ok( $root->attributes );
is( $root->attributes->{xmlns}, "http://www.w3.org/1999/xhtml" );
is( $root->{xmlns}, $root->attributes->{xmlns} );

is( $root->type, 1 );
ok( $root->children );
is( scalar( @{$root->children} ), 5 );
is( scalar( @$root ), 5 );
is( $root->[3]->name, 'body' );
is( $root->[3][0]->data, "\n    " );

my $body = $root->[3];
ok( $body->document );
is( $body->document, $document );
is( $body->document->type, DOCUMENT_NODE );
