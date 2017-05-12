#!perl
use strict;
use warnings;
use Test::More tests => 99;
use Test::Exception;
use Tripletail '/dev/null';

ok($TL->INI, 'INI');
is($TL->CGI, undef, 'CGI');

dies_ok {$TL->escapeTag} 'escapeTag die';
is($TL->escapeTag(q{ &<>"' }),
   ' &amp;&lt;&gt;&quot;&#39; ',
   'escapeTag');

dies_ok {$TL->unescapeTag} 'unescapeTag die';
is($TL->unescapeTag(' &amp;&lt;&gt;&quot;&#39;&#34;&#62;&#x22;&#x3E; '),
   q{ &<>"'">"> },
   'unescapeTag');

dies_ok {$TL->escapeJs} 'escapeJs die';
is($TL->escapeJs(q{ \\r\\n'"\\ }),
   q{ \\\\r\\\\n\\'\\"\\\\ },
   'escapeJs');
dies_ok {$TL->unescapeJs} 'unescapeJs die';
is($TL->unescapeJs(q{ \\\\r\\\\n\\'\\"\\\\ }),
   q{ \\r\\n'"\\ },
   'unescapeJs');

dies_ok {$TL->encodeURL} 'encodeURL die';
is($TL->encodeURL('a b'), 'a%20b', 'encodeURL');
dies_ok {$TL->encodeURL} 'encodeURL die';
is($TL->decodeURL('a%20b'), 'a b', 'decodeURL');

dies_ok {$TL->escapeSqlLike} 'escapeSqlLike die';
is($TL->escapeSqlLike('%_\\'), '\\%\\_\\\\', 'escapeSqlLike');
dies_ok {$TL->unescapeSqlLike} 'unescapeSqlLike die';
is($TL->unescapeSqlLike('\\%\\_\\\\'), '%_\\', 'unescapeSqlLike');

ok($TL->trapError(-main => sub {}), 'trapError');

{
	my $test;
	sub DoTest { $test = 1; }
	sub Dotest { $test = 2; } # could not dispatch.
	
	ok($TL->dispatch('Test'), 'dispatch: Test');
	is($test, 1,  'dispatch: Test, executed');
	
	eval{$TL->dispatch('test');};
	like($@, qr/must start with upper case character/, 'dispatch: test, refused');
	
	is($TL->dispatch('NotExists'), undef, 'dispatch: NotExists');
	$TL->dispatch('NotExists',onerror=>sub{$test=3;});
	pass('dispatch: NotExists');
	is($test, 3,  'dispatch: NotExists, onerror');
	eval{ $TL->dispatch('NotExists',onerror=>sub{$test=5;die "yyy";})};
	ok($@, 'die: NotExists, die in onerror');
}

dies_ok {$TL->log} 'log die (1)';
lives_ok {$TL->log(__PACKAGE__)} 'log (2)';
lives_ok {$TL->log(__PACKAGE__, 'foo')} 'log (3)';
dies_ok {$TL->_log} '_log die (1)';
dies_ok {$TL->_log(__PACKAGE__)} '_log die (2)';

dies_ok {$TL->setHook('init')} 'setHook die';
dies_ok {$TL->setHook(\123)} 'setHook die';
dies_ok {$TL->setHook('init')} 'setHook die';
dies_ok {$TL->setHook('init', \123)} 'setHook die';
dies_ok {$TL->setHook('init', 'aaaa')} 'setHook die';
dies_ok {$TL->setHook('init', 1000, \123)} 'setHook die';
ok($TL->setHook('init', 1000, sub {}), 'setHook');

dies_ok {$TL->removeHook('init')} 'removeHook die';
dies_ok {$TL->removeHook(\123)} 'removeHook die';
dies_ok {$TL->removeHook('init')} 'removeHook die';
dies_ok {$TL->removeHook('init', \123)} 'removeHook die';
ok($TL->removeHook('init', 1000), 'removeHook');

dies_ok {$TL->setContentFilter} 'setContentFilter die';
dies_ok {$TL->setContentFilter(\123)} 'setContentFilter die';
dies_ok {$TL->setContentFilter([undef,100])} 'setContentFilter die';
dies_ok {$TL->setContentFilter([\123,100])} 'setContentFilter die';
dies_ok {$TL->setContentFilter(['Tripletail::Filter::HTML',undef])} 'setContentFilter die';
dies_ok {$TL->setContentFilter(['Tripletail::Filter::HTML',\123])} 'setContentFilter die';
dies_ok {$TL->setContentFilter(['Tripletail::Filter::HTML','aaa'])} 'setContentFilter die';
dies_ok {$TL->setContentFilter('Tripletail::Filter::HTML', a => {})} 'setContentFilter die';
dies_ok {$TL->setContentFilter('Tripletail::Filter::TLTLRTEST')} 'setContentFilter die';
ok($TL->setContentFilter('Tripletail::Filter::HTML', charset => 'ISO-8859-1'), 'setContentFilter');
ok($TL->getContentFilter(1000), 'getContentFilter');
ok($TL->removeContentFilter(1000), 'removeContentFilter');

dies_ok {$TL->setInputFilter} 'setInputFilter die';
dies_ok {$TL->setInputFilter(\123)} 'setInputFilter die';
dies_ok {$TL->setInputFilter([undef,100])} 'setInputFilter die';
dies_ok {$TL->setInputFilter([\123,100])} 'setInputFilter die';
dies_ok {$TL->setInputFilter(['Tripletail::Filter::HTML',undef])} 'setInputFilter die';
dies_ok {$TL->setInputFilter(['Tripletail::Filter::HTML',\123])} 'setInputFilter die';
dies_ok {$TL->setInputFilter(['Tripletail::Filter::HTML','aaa'])} 'setInputFilter die';
dies_ok {$TL->setInputFilter('Tripletail::Filter::HTML', a => {})} 'setInputFilter die';
dies_ok {$TL->setInputFilter('Tripletail::Filter::TLTLRTEST')} 'setContentFilter die';
ok($TL->removeInputFilter(1000), 'removeInputFilter');

is($TL->getInputFilter, undef ,'getInputFilter');

dies_ok {$TL->parsePeriod} 'parsePeriod die';
dies_ok {$TL->parsePeriod('min')} 'parsePeriod die';
dies_ok {$TL->parsePeriod('aaa')} 'parsePeriod die';
is($TL->parsePeriod('10'), 10, 'parsePeriod');
is($TL->parsePeriod('10sec'), 10, 'parsePeriod');
is($TL->parsePeriod('1days'), 60 * 60 * 24, 'parsePeriod');
is($TL->parsePeriod('1mon'), 60 * 60 * 24 * 30.436875, 'parsePeriod');
is($TL->parsePeriod('1year'), 60 * 60 * 24 * 365.2425, 'parsePeriod');
is($TL->parsePeriod('10hour 30min'), 10 * 60 * 60 + 30 * 60, 'parsePeriod');
is($TL->parsePeriod('10hour 30min'), 10 * 60 * 60 + 30 * 60, 'parsePeriod');

dies_ok {$TL->parseQuantity} 'parseQuantity die';
dies_ok {$TL->parseQuantity('ki')} 'parseQuantity die';
dies_ok {$TL->parseQuantity('aaa')} 'parseQuantity die';

is($TL->parseQuantity('1mi'), 1024 * 1024, 'parseQuantity');
is($TL->parseQuantity('1gi'), 1024 * 1024 * 1024, 'parseQuantity');
is($TL->parseQuantity('1ti'), 1024 * 1024 * 1024 * 1024, 'parseQuantity');
is($TL->parseQuantity('1pi'), 1024 * 1024 * 1024 * 1024 * 1024, 'parseQuantity');
is($TL->parseQuantity('1ei'), 1024 * 1024 * 1024 * 1024 * 1024 * 1024, 'parseQuantity');
is($TL->parseQuantity('1m'), 1000 * 1000, 'parseQuantity');
is($TL->parseQuantity('1g'), 1000 * 1000 * 1000, 'parseQuantity');
is($TL->parseQuantity('1t'), 1000 * 1000 * 1000 * 1000, 'parseQuantity');
is($TL->parseQuantity('1p'), 1000 * 1000 * 1000 * 1000 * 1000, 'parseQuantity');
is($TL->parseQuantity('1e'), 1000 * 1000 * 1000 * 1000 * 1000 * 1000, 'parseQuantity');
is($TL->parseQuantity('100ki 10k'), 100 * 1024 + 10 * 1000, 'parseQuantity');

dies_ok {$TL->writeFile} 'writeFile die';
dies_ok {$TL->writeFile(\123)} 'writeFile die';
ok($TL->writeFile("tmp.$$",'test'), 'writeFile');
dies_ok {$TL->writeTextFile("tmp.$$",'aa',1,\123)} 'writeTextFile die';
ok($TL->writeTextFile("tmp.$$",'aa'), 'writeTextFile');

dies_ok {$TL->readFile} 'readFile die';
dies_ok {$TL->readFile(\123)} 'readFile die';
ok($TL->readFile("tmp.$$"), 'readFile');
ok($TL->readTextFile("tmp.$$"), 'readTextFile');

END {
    unlink "tmp.$$";
}
