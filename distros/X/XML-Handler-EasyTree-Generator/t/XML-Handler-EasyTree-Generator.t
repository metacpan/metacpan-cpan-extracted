# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Handler-EasyTree-Generator.t'

#########################

use Test::More tests => 42;
BEGIN {
	diag('try loading module');
	use_ok('XML::Handler::EasyTree::Generator');
	require_ok('XML::Handler::EasyTree::Generator');
};
require XML::Handler::EasyTree::Generator;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

### basic checks, 8 tests
diag('try basic OO constructor');
can_ok('XML::Handler::EasyTree::Generator', qw(new));
my $e = XML::Handler::EasyTree::Generator->new();
isa_ok( $e, 'XML::Handler::EasyTree::Generator');
is( $e->{'t'},	'_t',								'default text node' );
is( $e->{'c'},	'_c',								'default comment node' );
is( $e->{'pi'},	'_pi',								'default PI node' );
$e = XML::Handler::EasyTree::Generator->new('t'=>'text','c'=>'comm','pi'=>'3.14');
is( $e->{'t'},	'text',								'specified text node' );
is( $e->{'c'},	'comm',								'specified comment node' );
is( $e->{'pi'},	'3.14',								'specified PI node' );
# re-initialize for simplicity
$e = XML::Handler::EasyTree::Generator->new();

diag('try everything with OO approach');

### text node tests, 3 tests
is_deeply( $e->_t('foo'),
	{'type'=>'t', 'content'=>'foo'},				'generate text node');
is_deeply( $e->_t('foo', 'bar'),
	{'type'=>'t', 'content'=>'foobar'},				'generate text node, joining content');
is_deeply( $e->_t({'target'=>'die'}, 'foo'),
	{'type'=>'t', 'content'=>'foo'},				'generate text node, ignoring hashref');

### comment node tests, 3 tests
is_deeply( $e->_c('foo'),
	{'type'=>'c', 'content'=>'foo'},				'generate comment node');
is_deeply( $e->_c('foo', 'bar'),
	{'type'=>'c', 'content'=>'foobar'},				'generate comment node, joining content');
is_deeply( $e->_c({'target'=>'die'}, 'foo'),
	{'type'=>'c', 'content'=>'foo'},				'generate comment node, ignoring hashref');
	
### PI node tests, 6 tests
is_deeply( $e->_pi({'target' => 'perl'}, 'foo'),
	{'type'=>'p', 'target' => 'perl', 'content'=>'foo'},	'generate PI node with hashref');
is_deeply( $e->_pi({'target' => 'perl', 'die'=>'foo'}, 'foo', 'bar'),
	{'type'=>'p', 'target' => 'perl', 'content'=>'foobar'},	'generate PI node with hashref, joining content');
is_deeply( $e->_pi({'target' => 'perl'}, 'foo'),
	{'type'=>'p', 'target'=>'perl', 'content'=>'foo'},		'generate PI node with hashref, ignoring hashref');
is_deeply( $e->_pi('perl', 'foo'),
	{'type'=>'p', 'target' => 'perl',  'content'=>'foo'},	'generate PI node with scalar');
is_deeply( $e->_pi('perl', 'foo', 'bar'),
	{'type'=>'p', 'target' => 'perl',  'content'=>'foobar'},'generate PI node with scalar, joining content');
is_deeply( $e->_pi({'die'=>'foo'}, 'perl', 'foo'),
	{'type'=>'p', 'target' => 'perl',  'content'=>'foo'},	'generate PI node with scalar, ignoring hashref');

### element node tests, 4 tests
is_deeply( $e->bar('foo'),
	{'type'=>'e', 'name' => 'bar', 'attrib' => {}, 'content'=>[
		{'type'=>'t','content'=>'foo'}
	]},
															'generate element node (with scalar)');
is_deeply( $e->bar({'baz'=>'bif'}, 'foo'),
	{'type'=>'e', 'name' => 'bar', 'attrib' => {'baz'=>'bif'}, 'content'=>[
		{'type'=>'t','content'=>'foo'}
	]},
															'generate element node with attributes');
is_deeply( $e->bar('foo', 'baz'),
	{'type'=>'e', 'name' => 'bar', 'attrib' => {}, 'content'=>[
		{'type'=>'t','content'=>'foo'},
		{'type'=>'t','content'=>'baz'}
	]},
															'generate element node with two scalars');
is_deeply( $e->bar({}, $e->foo()),
	{'type'=>'e', 'name' => 'bar', 'attrib' => {}, 'content'=>[
		{'type'=>'e', 'name' => 'foo', 'attrib' => {}, 'content'=>[]},
	]},
															'generate element node with hashref');

diag('now try everything with function approach');

### text node tests, 3 tests
is_deeply( XML::Handler::EasyTree::Generator::_t('foo'),
	{'type'=>'t', 'content'=>'foo'},				'generate text node');
is_deeply( XML::Handler::EasyTree::Generator::_t('foo', 'bar'),
	{'type'=>'t', 'content'=>'foobar'},				'generate text node, joining content');
is_deeply( XML::Handler::EasyTree::Generator::_t({'target'=>'die'}, 'foo'),
	{'type'=>'t', 'content'=>'foo'},				'generate text node, ignoring hashref');

### comment node tests, 3 tests
is_deeply( XML::Handler::EasyTree::Generator::_c('foo'),
	{'type'=>'c', 'content'=>'foo'},				'generate comment node');
is_deeply( XML::Handler::EasyTree::Generator::_c('foo', 'bar'),
	{'type'=>'c', 'content'=>'foobar'},				'generate comment node, joining content');
is_deeply( XML::Handler::EasyTree::Generator::_c({'target'=>'die'}, 'foo'),
	{'type'=>'c', 'content'=>'foo'},				'generate comment node, ignoring hashref');
	
### PI node tests, 6 tests
is_deeply( XML::Handler::EasyTree::Generator::_pi({'target' => 'perl'}, 'foo'),
	{'type'=>'p', 'target' => 'perl', 'content'=>'foo'},	'generate PI node with hashref');
is_deeply( XML::Handler::EasyTree::Generator::_pi({'target' => 'perl', 'die'=>'foo'}, 'foo', 'bar'),
	{'type'=>'p', 'target' => 'perl', 'content'=>'foobar'},	'generate PI node with hashref, joining content');
is_deeply( XML::Handler::EasyTree::Generator::_pi({'target' => 'perl'}, 'foo'),
	{'type'=>'p', 'target'=>'perl', 'content'=>'foo'},		'generate PI node with hashref, ignoring hashref');
is_deeply( XML::Handler::EasyTree::Generator::_pi('perl', 'foo'),
	{'type'=>'p', 'target' => 'perl',  'content'=>'foo'},	'generate PI node with scalar');
is_deeply( XML::Handler::EasyTree::Generator::_pi('perl', 'foo', 'bar'),
	{'type'=>'p', 'target' => 'perl',  'content'=>'foobar'},'generate PI node with scalar, joining content');
is_deeply( XML::Handler::EasyTree::Generator::_pi({'die'=>'foo'}, 'perl', 'foo'),
	{'type'=>'p', 'target' => 'perl',  'content'=>'foo'},	'generate PI node with scalar, ignoring hashref');

### element node tests, 4 tests
is_deeply( XML::Handler::EasyTree::Generator::bar('foo'),
	{'type'=>'e', 'name' => 'bar', 'attrib' => {}, 'content'=>[
		{'type'=>'t','content'=>'foo'}
	]},
															'generate element node (with scalar)');
is_deeply( XML::Handler::EasyTree::Generator::bar({'baz'=>'bif'}, 'foo'),
	{'type'=>'e', 'name' => 'bar', 'attrib' => {'baz'=>'bif'}, 'content'=>[
		{'type'=>'t','content'=>'foo'}
	]},
															'generate element node with attributes');
is_deeply( XML::Handler::EasyTree::Generator::bar('foo', 'baz'),
	{'type'=>'e', 'name' => 'bar', 'attrib' => {}, 'content'=>[
		{'type'=>'t','content'=>'foo'},
		{'type'=>'t','content'=>'baz'}
	]},
															'generate element node with two scalars');
is_deeply( XML::Handler::EasyTree::Generator::bar({}, XML::Handler::EasyTree::Generator::foo()),
	{'type'=>'e', 'name' => 'bar', 'attrib' => {}, 'content'=>[
		{'type'=>'e', 'name' => 'foo', 'attrib' => {}, 'content'=>[]},
	]},
															'generate element node with hashref');
### END ###