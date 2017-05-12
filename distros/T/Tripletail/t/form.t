#!perl
use strict;
use warnings;
use File::Spec ();
use Test::Exception;
use Test::More tests =>
  +122
  +10 # getFileName returns basename.
  ;
use Tripletail '/dev/null';

my $f;
dies_ok {$TL->newForm(undef)} 'newForm undef';
dies_ok {$TL->newForm(\123)} 'newForm ref';
ok($f = $TL->newForm, 'newForm');

dies_ok {$f->get(\123)} 'get ref';
dies_ok {$f->get('',\123)} 'get ref';

dies_ok {$f->getValues(\123)} 'getValues ref';
dies_ok {$f->lookup(\123)} 'lookup ref';
dies_ok {$f->lookup('c',\123)} 'lookup ref';
is($f->lookup('c'), undef, 'lookup');
is($f->getValues('c'), undef, 'getValues');
is($f->getSlice('c'), 0, 'getSlice');
is($f->getSliceValues('c'), 1, 'getSliceValues');

is($f->get('c') , undef , 'get');

dies_ok {$f->getSlice(\123)} 'getSlice ref';
dies_ok {$f->getSliceValues(\123)} 'getSliceValues ref';

dies_ok {$f->set(\123)} 'set ref';
dies_ok {$f->add(\123)} 'add ref';
dies_ok {$f->add(sss => \123)} 'add ref';
dies_ok {$f->add('sss',\123)} 'add ref';
dies_ok {$f->exists(\123)} 'exists ref';
dies_ok {$f->remove} 'remove undef';
dies_ok {$f->remove(\123)} 'remove ref';
dies_ok {$f->remove(sss => undef)} 'remove undef';
dies_ok {$f->remove(sss => \123)} 'remove ref';
dies_ok {$f->remove(sss => 123)} 'remove not key';
dies_ok {$f->delete(\123)} 'delete ref';
dies_ok {$f->getFile(\123)} 'getFile ref';
dies_ok {$f->setFile(\123)} 'setFile ref';
dies_ok {$f->setFile('filename','file')} 'setFile not ref';
dies_ok {$f->getFileName(\123)} 'getFileName ref';
dies_ok {$f->setFileName(\123)} 'setFileName ref';
dies_ok {$f->setFileName('filename',\123)} 'setFileName ref';
dies_ok {$f->setLink} 'setLink undef';
dies_ok {$f->setLink(\123)} 'setLink ref';
dies_ok {$f->addLink} 'addLink undef';
dies_ok {$f->addLink(\123)} 'addLink ref';
dies_ok {$f->setFragment(\123)} 'setFragment ref';
dies_ok {$f->toLink(\123)} 'toLink ref';
dies_ok {$f->toExtLink(\123)} 'toExtLink ref';
dies_ok {$f->haveSessionCheck} 'haveSessionCheck undef';
dies_ok {$f->haveSessionCheck('aa')} 'haveSessionCheck undef';

ok($f->set(aaa => 111), 'set');
ok($f->set({bbb => 111}), 'set');

ok($f->setFragment('ID'), 'setFragment');
is($f->toLink('http://example.org/'), 'http://example.org/?aaa=111&bbb=111&INT=1#ID', 'toLink');
is($f->toExtLink('http://example.org/'), 'http://example.org/?aaa=111&bbb=111#ID', 'toExtLink');
is(($f->getValues('aaa'))[0], 111, 'getValues');
is(($f->getSlice('aaa'))[0], 'aaa', 'getSlice');
is(($f->getSlice('aaa'))[1], 111, 'getSlice');
is(($f->getSliceValues('aaa'))[0], 111, 'getSliceValues');
ok($f->add(bbb => 222), 'add');
is(($f->getValues('bbb'))[0], 111, 'getValues');
is(($f->getSlice('bbb'))[0], 'bbb', 'getSlice');
is(($f->getSlice('bbb'))[1]->[0], 111, 'getSlice');
is(($f->getSliceValues('bbb'))[0]->[0], 111, 'getSliceValues');
is(($f->getSliceValues('bbb'))[0]->[1], 222, 'getSliceValues');
ok($f->delete('aaa'), 'delete');
ok($f->delete('bbb'), 'delete');
ok($f->setFragment('あ'), 'setFragment');
ok($f->set('い' => 'う'), 'set');
is($f->toLink('http://example.org/'), 'http://example.org/?%e3%81%84=%e3%81%86&INT=1#%e3%81%82', 'toLink');
is($f->toExtLink('http://example.org/'), 'http://example.org/?%e3%81%84=%e3%81%86#%e3%81%82', 'toExtLink');
is($f->toExtLink('http://example.org/', 'Shift_JIS'), 'http://example.org/?%82%a2=%82%a4#%82%a0', 'toExtLink');

my $c;
ok($c = $f->clone, 'clone');
is($c->get('い'), 'う', '$clone->get');
is($c->getFragment, 'あ', '$clone->getFragment');
is($c->toLink('http://example.org/'), 'http://example.org/?%e3%81%84=%e3%81%86&INT=1#%e3%81%82', 'toLink');
is($c->toExtLink('http://example.org/'), 'http://example.org/?%e3%81%84=%e3%81%86#%e3%81%82', 'toExtLink');
is($c->toExtLink('http://example.org/', 'Shift_JIS'), 'http://example.org/?%82%a2=%82%a4#%82%a0', 'toExtLink');

dies_ok {$f->addForm(\123)} 'addForm ref';
$c->_trace;
ok($c->set({xxx => 111,zzz => 222}), 'set');
$c->addForm($TL->newForm(bbb => 222));
ok($c->add(bbb => 111), 'add');
ok($c->remove(bbb => 111), 'remove');
ok($c->delete('ccc'), 'delete');
open my $fh, '<', File::Spec->devnull();
ok($c->setFile('filename',$fh), 'setFile');
ok($c->setFile('filename',undef), 'setFile');
close $fh;
ok($c->setFileName('filename',undef), 'setFileName');
is($c->get('bbb'), 222, 'addForm');
ok($c->setFragment(1), 'setFragment');

is($f->get('bbb'), undef, 'unmodified original');

$TL->setInputFilter('Tripletail::InputFilter::HTML');
$c->setLink('http://example.net/?bbb=333');
is($c->get('bbb'), 333, 'setLink');
$c->addLink('http://example.net/?bbb=333');

ok($f->addForm($TL->newForm(bbb => 222)->setFragment(1)), 'addForm');

ok($f->const, 'const');
dies_ok {$f->addForm} 'add const';
dies_ok {$f->set} 'set const';
dies_ok {$f->add} 'add const';
dies_ok {$f->remove} 'remove const';
dies_ok {$f->delete} 'delete const';
dies_ok {$f->setFile} 'setFile const';
dies_ok {$f->setFileName} 'setFileName const';
dies_ok {$f->setLink} 'setLink const';
dies_ok {$f->addLink} 'addLink const';
dies_ok {$f->setFragment} 'setFragment const';

my $f1;
$f1 = $TL->newForm;
{
local($ENV{'REQUEST_URI'}) = q{/test.cgi};
is($f1->toLink, 'test.cgi?INT=1', 'toLink');
is($f1->toExtLink, 'test.cgi', 'toLink');
}

$f1->set(aaa => 111);
$f1->add(aaa => 111);

my $c1;
$c1 = $f1->clone;

ok($c1->remove(aaa => 111), 'remove');
is($c1->get('aaa'), 111 , 'remove check');
ok($c1->remove(aaa => 111), 'remove');
is($c1->get('aaa'), undef , 'remove check');
ok($f1->remove(aaa => 111), 'remove');
is($f1->get('aaa'), 111 , 'remove check');
ok($f1->remove(aaa => 111), 'remove');
is($f1->get('aaa'), undef , 'remove check');

# setting undef or [] is equivalent with delete.
{
	# 5 tests.
	my $form = $TL->newForm();
	$form->set(a=>1);
	ok($form->exists("a"),               "set-undef: 1 of 7");
	is($form->get("a"), "1",             "set-undef: 2 of 7");
	is_deeply([$form->getKeys()], ['a'], "set-undef: 3 of 7");
	ok($form->set(a=>undef),             "set-undef: 4 of 7");
	ok(!$form->exists("a"),              "set-undef: 5 of 7");
	is($form->get("a"), undef,           "set-undef: 6 of 7");
	is_deeply([$form->getKeys()], [],    "set-undef: 7 of 7");
}
{
	# 5 tests.
	my $form = $TL->newForm();
	$form->set(b=>[2,3]);
	ok($form->exists("b"),               "set-empty-list: 1 of 7");
	is($form->get("b"), "2,3",           "set-empty-list: 2 of 7");
	is_deeply([$form->getKeys()], ['b'], "set-empty-list: 3 of 7");
	ok($form->set(b=>[]),                "set-empty-list: 4 of 7");
	ok(!$form->exists("b"),              "set-empty-list: 5 of 7");
	is($form->get("b"), undef,           "set-empty-list: 6 of 7");
	is_deeply([$form->getKeys()], [],    "set-empty-list: 7 of 7");
}

# setting references raise an error.
{
	# 5 tests.
	my $form = $TL->newForm();
	dies_ok {$form->set(a=>\1)} 'set-error: scalar-ref';
	dies_ok {$form->set(a=>{})} 'set-error: hash-ref';
	dies_ok {$form->set(a=>[\1])} 'set-error: array-ref of scalar-ref';
	dies_ok {$form->set(a=>[{}])} 'set-error: array-ref of hash-ref';
	dies_ok {$form->set(a=>[[]])} 'set-error: array-ref of array-ref';
}

{
  my $form = $TL->newForm();

  is($form->getFileName('file'), undef, "getFileName for noent");

  local(*FH);
  my $fh = \*FH;
  $form->setFile('file', $fh);
  pass("setFile");

  $form->setFileName('file', "a/b/c.dat");
  pass("setFileName (unix)");
  is($form->getFileName('file'), "c.dat", "getFileName returns basename (unix)");
  is($form->getFullFileName('file'), "a/b/c.dat", "getFullFileName returns fullpath (unix)");
  {
  local($TL->{INI}{ini}{TL}{compat_form_getfilename_returns_fullpath}) = 1;
  local($TL->{INI}{order}{group}[0]) = 'TL';
  local($TL->{INI}{order}{key}{TL}[0]) = 'compat_form_getfilename_returns_fullpath';
  is($form->getFileName('file'), "a/b/c.dat", "getFileName+compat returns fullpath (unix)");
  }

  $form->setFileName('file', "a:\\b\\c.dat");
  pass("setFileName (win)");
  is($form->getFileName('file'), "c.dat", "getFileName returns basename (win)");
  is($form->getFullFileName('file'), "a:\\b\\c.dat", "getFullFileName returns fullpath (win)");
  {
  local($TL->{INI}{ini}{TL}{compat_form_getfilename_returns_fullpath}) = 1;
  local($TL->{INI}{order}{group}[0]) = 'TL';
  local($TL->{INI}{order}{key}{TL}[0]) = 'compat_form_getfilename_returns_fullpath';
  is($form->getFileName('file'), "a:\\b\\c.dat", "getFileName+compat returns fullpath (win)");
  }
}
