# -*- perl -*-
use strict;
use warnings;
use Test::Exception;
use Test::More tests =>
  60
  +13 # get_reloc.
;
use t::make_ini {
    ini => {
        TL => {
            trap    => 'none',
            Samhain => 1,
            Imbolc  => 2,
            Beltain => 3,
        },
        'TL:special' => {
            Beltain => 300,
            Lugnasa => 400,
        },
        'TL:special@remote:Testuser@server:Debughost' => {
            Beltain => 500,
            Lugnasa => 600,
        },
        HOST => {
            Debughost => '192.168.0.0/24',
            Testuser  => '192.168.1.1',
        },
        RelocTest => {
            a => '...',
            b => '.../',
            c => '....',
        },
    },
};
use Tripletail $t::make_ini::INI_FILE, 'special';

my $ini;
ok($ini = $TL->newIni, 'newIni');
dies_ok {$ini->read("file$$.dummy")} 'read cant open file die';
ok($ini->read($t::make_ini::INI_FILE), 'read');

dies_ok {$ini->existsGroup} 'existsGroup undef';
dies_ok {$ini->existsGroup(\123)} 'existsGroup ref';
ok($ini->existsGroup('TL'), 'existsGroup');
ok(!$ini->existsGroup('tl'), '!existsGroup');

dies_ok {$ini->existsKey} 'existsKey undef';
dies_ok {$ini->existsKey(TL => undef)} 'existsKey undef';
dies_ok {$ini->existsKey(\123)} 'existsKey ref';
dies_ok {$ini->existsKey(TL => \123)} 'existsKey ref';
is($ini->existsKey(TEST => 'test'), undef , 'existsKey');
is($ini->existsKey(TL => 'trap'), 1 , 'existsKey');
is($ini->existsKey(TL => 'test'), undef , 'existsKey');
is($ini->existsKey(TL => 'trap',1), 1 , 'existsKey');
dies_ok {$ini->getKeys} 'getKeys undef';
dies_ok {$ini->getKeys(\123)} 'getKeys ref';

dies_ok {$ini->get} 'get undef';
dies_ok {$ini->get(TL => undef)} 'get undef';
dies_ok {$ini->get(\123)} 'get ref';
dies_ok {$ini->get(TL => \123)} 'get ref';
is($ini->get(TL => 'trap'), 'none', 'get');
is($ini->get(TL => 'trap',1), 'none', 'get');
is($ini->get(TL => 'TRAP' => undef), undef, 'get');
dies_ok {$ini->get(TL => 'TRAP')} 'get';


sub toHash {
	$_ = {map {$_ => 1} @_};
	$_;
}

is_deeply(
	toHash($ini->getGroups), toHash(qw[TL HOST RelocTest]), 'getGroups');
is_deeply(
	toHash($ini->getKeys('TL')),
	toHash(qw[trap Samhain Imbolc Beltain Lugnasa]), 'getKeys');
is_deeply(
	toHash($ini->getKeys('TL',1)),
	toHash(qw[trap Samhain Imbolc Beltain]), 'getKeys');


dies_ok {$ini->set} 'set undef';
dies_ok {$ini->set(\123)} 'set ref';
dies_ok {$ini->set(Foo => undef)} 'set undef';
dies_ok {$ini->set(Foo => \123)} 'set ref';
dies_ok {$ini->set(Foo => aaa => undef)} 'set undef';
dies_ok {$ini->set(Foo => aaa => \123)} 'set ref';
dies_ok {$ini->set("\x00" => aaa => 222)} 'set control code';
dies_ok {$ini->set(Foo => "\x00" => 222)} 'set control code';
dies_ok {$ini->set(Foo => aaa => "\x00")} 'set control code';
dies_ok {$ini->set('  ' => aaa => 222)} 'set space';
dies_ok {$ini->set(Foo => '  ' => 222)} 'set space';
dies_ok {$ini->set(Foo => aaa => '  ')} 'set space';
ok($ini->set(Foo => aaa => 111), 'set');
dies_ok {$ini->write("/$$/$$/$$/file$$.dummy")} 'write cant open file die';
ok($ini->write($t::make_ini::INI_FILE), 'write');

is($ini->_filename, $t::make_ini::INI_FILE , '_filename');

do {
    open my $fh, '>', "tmp2$$.ini";
    print {$fh} <<'EOF';
[TL]
trapnone
EOF
    close $fh;
};
dies_ok {$ini->read("tmp2$$.ini")} 'read data format error die';
END {
    unlink "tmp2$$.ini";
}

dies_ok {$ini->delete} 'delete undef';
dies_ok {$ini->delete(\123)} 'delete ref';
dies_ok {$ini->delete(Foo => undef)} 'delete undef';
dies_ok {$ini->delete(Foo => \123)} 'delete ref';
ok($ini->delete(Foo => 'aaa'), 'delete');
$ini->set(Foo => aaa => 111);
ok($ini->delete(Foo => 'aaa',1), 'delete');

dies_ok {$ini->deleteGroup} 'deleteGroup undef';
dies_ok {$ini->deleteGroup(\123)} 'deleteGroup ref';
$ini->set(Foo => aaa => 111);
ok($ini->deleteGroup('Foo'), 'deleteGroup');
$ini->set(Foo => aaa => 111);
ok($ini->deleteGroup('Foo',1), 'deleteGroup');

ok($ini = $TL->newIni, 'newIni');
ok($ini->const, 'const');
dies_ok {$ini->set} 'const object undef';
dies_ok {$ini->delete} 'const object undef';
dies_ok {$ini->deleteGroup} 'const object undef';

{
  my $ini = $TL->INI;
  is($ini->get      (RelocTest => 'a'), '...', 'RelocTest.a is "..."');
  is($ini->get_reloc(RelocTest => 'a'), 't',   '- relocated');
  is($ini->get      (RelocTest => 'b'), '.../', 'RelocTest.b is ".../"');
  is($ini->get_reloc(RelocTest => 'b'), 't/', '  - relocated');
  is($ini->get      (RelocTest => 'c'), '....', 'RelocTest.c is "...."');
  is($ini->get_reloc(RelocTest => 'c'), '....', '  - not relocated');
  is($ini->get      (RelocTest => 'd' => undef), undef, 'RelocTest.c is undef');
  is($ini->get_reloc(RelocTest => 'd' => undef), undef, '  - not relocated');
  dies_ok {$ini->get      (RelocTest => 'd')} 'RelocTest.c is undef';
  dies_ok {$ini->get_reloc(RelocTest => 'd')} '  - not relocated';

  my $ini2 = $TL->newIni();
  $ini2->set(RelocTest2 => 'a' => '...');
  is($ini2->get      (RelocTest2 => 'a'), '...', 'RelocTest2.a is "..."');
  is($ini2->get_reloc(RelocTest2 => 'a'), '...', '  - not relocated (no filename)');

  $ini2->{filename} = "../nofile.ini";
  is($ini2->get_reloc(RelocTest2 => 'a'), '..', '  - relocated to updir');
}
