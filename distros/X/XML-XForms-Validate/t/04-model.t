
use Test::More tests => 14;
use IO::File;
BEGIN { use_ok('XML::XForms::Validate') };

my $parser = XML::LibXML->new();
my $dom = $parser->parse_string('<model xmlns="http://www.w3.org/2002/xforms"><submission id="s1"/></model>');
my $v = new XML::XForms::Validate(xforms => $dom);

isa_ok($v, 'XML::XForms::Validate');

is($v->{model}->nodePath, $dom->documentElement->nodePath, 'root model');

$dom = $parser->parse_string('<a xmlns:xf="http://www.w3.org/2002/xforms"><xf:model id="a"><xf:submission id="s1"/></xf:model><xf:model id="b"><xf:submission id="s2"/></xf:model></a>');

$v = new XML::XForms::Validate(xforms => $dom);
isa_ok($v, 'XML::XForms::Validate');
is($v->{model}->nodePath, $dom->documentElement->firstChild->nodePath, 'default model');

$v = new XML::XForms::Validate(xforms => $dom, model => 'b');
isa_ok($v, 'XML::XForms::Validate');
is($v->{model}->nodePath, $dom->documentElement->firstChild->nextSibling->nodePath, 'model by id');

open(my $fh, '<', 't/model.xforms');
$v = new XML::XForms::Validate(xforms => $fh, model => 'b');
isa_ok($v, 'XML::XForms::Validate');
is($v->{model}->nodePath, $dom->documentElement->firstChild->nextSibling->nodePath, 'model from file handle');
close($fh);

$v = new XML::XForms::Validate(xforms => new IO::File('t/model.xforms', '<'), model => 'b');
isa_ok($v, 'XML::XForms::Validate');
is($v->{model}->nodePath, $dom->documentElement->firstChild->nextSibling->nodePath, 'model from IO::Handle');

$v = new XML::XForms::Validate(xforms => 't/model.xforms', model => 'b');
isa_ok($v, 'XML::XForms::Validate');
is($v->{model}->nodePath, $dom->documentElement->firstChild->nextSibling->nodePath, 'model from file name');

$v = eval { new XML::XForms::Validate(xforms => $v); };
ok($@, 'invalid model exception');
