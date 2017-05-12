#!perl
use strict;
use warnings;
use Test::More tests =>
  108
  +2 # trim.
  +4 # existsFile
  ;
use Test::Exception;
use Tripletail qw(/dev/null);
#use Smart::Comments;

do {
    open my $fh, '>', "include$$.txt";
    print $fh qq{
<!include:include$$.txt>
};
    close $fh;
};

END {
    unlink "template$$.txt";
    unlink "include$$.txt";
}

my $TMPL3_XML = qq{
<?xml version="1.0" encoding="UTF-8" ?>
      <FORM ACTION="">
        <INPUT TYPE="text" NAME="aaa" VALUE="111" />
        <INPUT TYPE="password" NAME="bbb" VALUE="111" />
  <input type="checkbox" name="checkbox" value="checkbox" checked="checked" />
  <input type="checkbox" name="checkbox" value="checkbox2" />
  <input type="checkbox" name="checkbox" value="checkbox" />
  <input type="radio" name="radiobutton" value="radiobutton" />
  <textarea name="textfield2">aaa</textarea>
  <select name="select2">
    <option>aaa</option>
    <option value="bbb" selected="selected">bbbb</option>
  </select>
  <input type="file" name="file" />
  <input type="image" border="0" name="imageField" src="test.JPG" width="800" height="595" />
  <input type="hidden" name="hiddenField" />
  <select name="menu1" onChange="MM_jumpMenu('parent',this,0)">
    <option selected>unnamed1</option>
  </select>
  <input type="submit" name="submit" value="送信">
      </FORM>
      <FORM ACTION="" NAME="FORM">
      </FORM>
};

my $TMPL3 = qq{
      <FORM ACTION="">
        <INPUT TYPE="text" NAME="aaa" VALUE="111">
        <INPUT TYPE="password" NAME="bbb" VALUE="111">
  <input type="checkbox" name="checkbox" value="checkbox">
  <input type="checkbox" name="checkbox" value="checkbox2" checked>
  <input type="checkbox" name="checkbox" value="checkbox">
  <input type="radio" name="radiobutton" value="radiobutton">
  <textarea name="textfield2">aaa</textarea>
  <select name="select2">
    <option selected>aaa</option>
    <option value="bbb">bbbb</option>
  </select>
  <input type="file" name="file">
  <input type="image" border="0" name="imageField" src="test.JPG" width="800" height="595">
  <input type="hidden" name="hiddenField">
  <select name="menu1" onChange="MM_jumpMenu('parent',this,0)">
    <option selected>unnamed1</option>
  </select>
  <input type="submit" name="submit" value="送信">
      </FORM>
      <FORM ACTION="" NAME="FORM">
      </FORM>
};

my $TMPL4 = qq{
      <FORM ACTION="" NAME="FORM">
        <INPUT TYPE="TEXT" NAME="aaa" VALUE="111">
      </FORM>
};
my $TMPL2 = qq{
      <FORM ACTION="" NAME="FORM">
        <INPUT TYPE="text" NAME="aaa" VALUE="111">
      </FORM>
};
my $TMPL = qq{
    <!begin:FOO>::<&TAG>::<!end:FOO><!copy:FOO>

    <!begin:FORM>
      <FORM ACTION="" NAME="FORM">
        <INPUT TYPE="text" NAME="aaa" VALUE="111">
      </FORM>
    <!end:FORM>
};

my $TMPL5 = qq{
    <form name="form">
      <input type="text" name="aaa" value="AAAAA">
      <textarea name="bbb">BBBBB</textarea>
    </form>
};

do {
    open my $fh, '>', "template$$.txt";
    print $fh $TMPL;
    close $fh;
};

sub trim ($) {
    $_ = shift;
    s/^\s*|\s*$//mg;
    $_;
}

my $t;
ok($t = $TL->newTemplate, 'newTemplate');
ok($t = $TL->newTemplate("template$$.txt"), 'newTemplate');
ok($t->setTemplate('<?xml version="1.0" encoding="UTF-8" ?>'), 'setTemplate');
dies_ok {$t->setTemplate('<!mark:test>')} 'setTemplate die';
dies_ok {$t->setTemplate('<!begin:test><!end:test><!begin:test><!end:test>')} 'setTemplate die';
dies_ok {$t->setTemplate('<!begin:test>')} 'setTemplate die';

ok($t->setTemplate($TMPL), 'setTemplate');
is($t->exists('FOO'), 1 , 'exists');
is($t->exists('FOO2'), '' , 'exists');
dies_ok {$t->exists} 'exists die';
dies_ok {$t->exists(\123)} 'exists die';

my $form;
$t->setTemplate($TMPL2);
ok($form = $t->getForm('FORM'), 'getForm (1)');
is($form->toLink('./'), './?aaa=111&INT=1', 'getForm (2)');

ok($t->setForm($form->set(aaa => 333), 'FORM'), 'setForm (1)');
is(trim $t->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM">
      <INPUT TYPE="text" NAME="aaa" VALUE="333">
    </FORM>
}, 'setForm (2)');

ok($t->addHiddenForm(
    $TL->newForm(bbb => 666), 'FORM'), 'addHiddenForm (1)');
is(trim $t->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM"><input type="hidden" name="bbb" value="666">
      <INPUT TYPE="text" NAME="aaa" VALUE="333">
    </FORM>
}, 'addHiddenForm (2)');

ok($t->addHiddenForm({ccc => 777}, 'FORM'), 'addHiddenForm (3)');
is(trim $t->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM"><input type="hidden" name="ccc" value="777"><input type="hidden" name="bbb" value="666">
      <INPUT TYPE="text" NAME="aaa" VALUE="333">
    </FORM>
}, 'addHiddenForm (4)');

ok($t->extForm('FORM'), 'extForm (1)');

ok($t->addHiddenForm(
    $TL->newForm(ddd => 666), 'FORM'), 'addHiddenForm (1)');
is(trim $t->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM" EXT="1"><input type="hidden" name="ddd" value="666"><input type="hidden" name="ccc" value="777"><input type="hidden" name="bbb" value="666">
      <INPUT TYPE="text" NAME="aaa" VALUE="333">
    </FORM>
}, 'addHiddenForm (2)');

$t->setTemplate($TMPL4);
ok($form = $t->getForm('FORM'), 'getForm (3)');
is($form->toLink('./'), './?aaa=111&INT=1', 'getForm (3)');

ok($t->setForm($form->set(aaa => 333), 'FORM'), 'setForm (3)');
is(trim $t->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM">
      <INPUT TYPE="TEXT" NAME="aaa" VALUE="333">
    </FORM>
}, 'setForm (4)');

dies_ok {$t->setHtml} 'setHtml die';
dies_ok {$t->setHtml(\123)} 'setHtml die';
ok($t->setHtml('test') , 'setHtml');
is($t->getHtml, 'test' , 'getHtml');
is($t->isXHTML, undef , 'isXHTML');


ok($t->loadTemplate("template$$.txt"), 'loadTemplate');

is($t->isRoot, 1 , 'isRoot');

dies_ok {$t->setTemplate} 'setTemplate die';
dies_ok {$t->setTemplate(\123)} 'setTemplate die';
dies_ok {$t->loadTemplate} 'loadTemplate die';
dies_ok {$t->loadTemplate(\123)} 'loadTemplate die';
dies_ok {$t->loadTemplate('./../../../../../../../../dummy.txt')} 'loadTemplate die';

$t = $TL->newTemplate;
ok($t->loadTemplate("template$$.txt"), 'loadTemplate');

dies_ok {$t->existsFile} 'existsFile die';
dies_ok {$t->existsFile(\123)} 'existsFile die';
is($t->existsFile('./../../../../../../../../dummy.txt'), undef, 'existsFile');
is($t->existsFile("template$$.txt"), 1, 'existsFile');

my $node;
dies_ok {$t->node} 'node die';
dies_ok {$t->node(\123)} 'node die';
dies_ok {$t->node('test')} 'node die';

ok($node = $t->node('foo'), 'node');
ok($node->add(tag => 1), 'add');
dies_ok {$node->add} 'add die';
dies_ok {$node->add(tag2 => undef)} 'add die';
dies_ok {$node->add(tag2 => \123)} 'add die';

is(trim $t->toStr, '::1::::1::', 'toStr');

### form: $t->node('FORM')

dies_ok {$form = $t->node('FORM')->getForm(\123)} 'getForm die';

ok($form = $t->node('FORM')->getForm('FORM'), 'getForm (1)');
is($form->toLink('./'), './?aaa=111&INT=1', 'getForm (2)');

### form: $t->node('FORM')

dies_ok {$t->node('FORM')->setForm} 'setForm die (no arg)';
dies_ok {$t->node('FORM')->setForm(\123)} 'setForm die (scalar-ref)';
dies_ok {$t->node('FORM')->setForm($form->set(aaa => 333), \123)} 'setForm die (scalar-ref on form name)';
dies_ok {$t->node('FORM')->extForm(\123)} 'extForm die';
dies_ok {$t->addHiddenForm} 'addHiddenForm die';
dies_ok {$t->addHiddenForm(\123)} 'addHiddenForm die';

ok($t->node('FORM')->setForm($form->set(aaa => 111), 'FORM'), 'setForm (1)');
is(trim $t->node('FORM')->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM">
      <INPUT TYPE="text" NAME="aaa" VALUE="111">
    </FORM>
}, 'setForm (2)');

ok($t->node('FORM')->setForm({aaa => 333}, 'FORM'), 'setForm (1)');
is(trim $t->node('FORM')->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM">
      <INPUT TYPE="text" NAME="aaa" VALUE="333">
    </FORM>
}, 'setForm (3)');

ok($t->node('FORM')->addHiddenForm(
    $TL->newForm(bbb => 666), 'FORM'), 'addHiddenForm (1)');
is(trim $t->node('FORM')->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM"><input type="hidden" name="bbb" value="666">
      <INPUT TYPE="text" NAME="aaa" VALUE="333">
    </FORM>
}, 'addHiddenForm (2)');

dies_ok {$t->setTemplate(q{<&DATA><&DATA2>})->expand(DATA => qq{<!>"'})} 'expand die';
dies_ok {$t->setTemplate(q{<&DATA>})->setAttr(\123)} 'attr die';
dies_ok {$t->setTemplate(q{<&DATA>})->setAttr({DATA => 'test'})} 'attr die';
dies_ok {$t->setTemplate(q{<&DATA>})->expand(\123)} 'expand die';
dies_ok {$t->setTemplate(q{<&DATA>})->expandAny(\123)} 'expandAny die';
dies_ok {$t->setTemplate(q{<&DATA><&DATA2>})->expandAny(DATA => qq{<!>"'})->toStr} 'toStr die';

ok($t->setTemplate(q{<&DATA><&DATA2>})->expandAny(DATA => qq{<!>"'}), 'expandAny');
ok($t->setTemplate(q{<&DATA><&DATA2>})->expandAny({DATA => qq{<!>"'}}), 'expandAny');
is($t->setTemplate(q{<&DATA>})->expand(DATA => qq{<!>"'})->toStr,
   q{&lt;!&gt;&quot;&#39;}, q{attr (DEFAULT)});
is($t->setTemplate(q{<&DATA>})->setAttr({DATA => 'plain'})->expand({DATA => qq{<!>"'}})->toStr,
   q{&lt;!&gt;&quot;&#39;}, q{attr (plain = DEFAULT)});
is($t->setTemplate(q{<&DATA>})->setAttr(DATA => 'raw')->expand(DATA => qq{<!>"'})->toStr,
   q{<!>"'}, q{attr (raw)});
is($t->setTemplate(q{<&DATA>})->setAttr(DATA => 'js')->expand(DATA => qq{<!>\n\r"'})->toStr,
   q{\x3c!\x3e\n\r\"\'}, q{attr (js)});
is($t->setTemplate(q{<&DATA>})->setAttr(DATA => 'br')->expand(DATA => qq{<!>\n<>"'})->toStr,
   qq{&lt;!&gt;<br>\n&lt;&gt;&quot;&#39;}, q{attr (br)});
is($t->setTemplate(q{<?xml version="1.0" encoding="UTF-8" ?><&DATA>})->setAttr(DATA => 'br')->expand(DATA => qq{<!>\n<>"'})->toStr,
   qq{<?xml version="1.0" encoding="UTF-8" ?>&lt;!&gt;<br />\n&lt;&gt;&quot;&#39;}, q{attr (br)});

is($t->setTemplate(q{<&DATA><&DATA2>})->getHtml, q{<&data><&data2>},'getHtml');

ok($t->setTemplate($TMPL), 'setTemplate');
is(trim $t->getHtml, trim qq{<!mark:foo><!copy:foo><!mark:form>}, 'getHtml');

is(trim $t->node('FORM')->extForm('FORM')->getHtml, trim qq{
    <FORM ACTION="" NAME="FORM" EXT="1">
      <INPUT TYPE="text" NAME="aaa" VALUE="111">
    </FORM>
}, 'extForm');


dies_ok {$t->setTemplate(qq{<!include:include$$.txt>})->toStr} 'include die';
ok($t->setTemplate(qq{<!include:template$$.txt>})->toStr, 'include test');

dies_ok {$t->setTemplate(q{<FORM ACTION="" NAME="FORM"></FORM>})->getForm('test')} 'getForm die';
dies_ok {$t->setTemplate(q{<FORM ACTION="" NAME="FORM"></FORM>})->setForm($form->set(aaa => '333'), 'test')} 'setForm die (no form for name)';
dies_ok {$t->setTemplate(q{<FORM ACTION="" NAME="FORM"></FORM>})->extForm('test')} 'extForm die';
dies_ok {$t->setTemplate(q{<FORM ACTION="" NAME="FORM"></FORM>})->addHiddenForm($TL->newForm(bbb => 666), \123)} 'addHiddenForm die';
dies_ok {$t->setTemplate(q{<FORM ACTION="" NAME="FORM"></FORM>})->addHiddenForm($TL->newForm(bbb => 666), 'test')} 'addHiddenForm die';

$t->setTemplate($TMPL3);
ok($form = $t->getForm, 'getForm (1)');
ok($t->setForm($form->set(aaa => 333,bbb => 222,checkbox => 'checkbox',radiobutton => 'radiobutton',textfield2 => 'bbb',select2 => 'bbb',hiddenField => 0,submit => 1)), 'setForm (1)');
is(trim $t->extForm->getHtml, trim qq{
<FORM ACTION="" EXT="1">
<INPUT TYPE="text" NAME="aaa" VALUE="333">
<INPUT TYPE="password" NAME="bbb" VALUE="222">
<input type="checkbox" name="checkbox" value="checkbox" checked>
<input type="checkbox" name="checkbox" value="checkbox2">
<input type="checkbox" name="checkbox" value="checkbox" checked>
<input type="radio" name="radiobutton" value="radiobutton" checked>
<textarea name="textfield2">bbb</textarea>
<select name="select2">
<option>aaa</option>
<option value="bbb" selected>bbbb</option>
</select>
<input type="file" name="file">
<input type="image" border="0" name="imageField" src="test.JPG" width="800" height="595">
<input type="hidden" name="hiddenField" value="0">
<select name="menu1" onChange="MM_jumpMenu('parent',this,0)">
<option selected>unnamed1</option>
</select>
<input type="submit" name="submit" value="1">
</FORM>
<FORM ACTION="" NAME="FORM">
</FORM>
}, 'extForm');

$t->setTemplate($TMPL3_XML);
ok($form = $t->getForm, 'getForm (1)');
ok($t->setForm($form->set(aaa => 333,bbb => 222,checkbox => 'checkbox',radiobutton => 'radiobutton',textfield2 => '',select2 => 'bbb',hiddenField => 0,submit => 1)), 'setForm (1)');
ok($t->addHiddenForm($TL->newForm(bbb => 666)));

#$TL->{filter}{$priority} = $classname->_new(%option);
#$TL->_updateFilterList('filter');

#ok($t->flush, 'flush');


$t->setTemplate($TMPL5);
$t->setForm({}, 'form');
is(trim $t->toStr, trim $TMPL5, 'the form is unchanged');


my $TMPL10 = q{
<HTML>
  <BODY>
        <FORM method="post" action="test2.cgi"><input type="hidden" name="CCC" value="愛">
        <select name="aa">
        <option value="">空欄</option>
        <option value="0">ゼロ</option>
        <option value="1">位置</option>
        </select>
        <input type="submit" value="ボタン">
        aaa
        </FORM>
  </BODY>
</HTML>
};
my $TMPL10_undef = q{<HTML>
<BODY>
<FORM method="post" action="test2.cgi"><input type="hidden" name="CCC" value="愛">
<select name="aa">
<option value="" selected>空欄</option>
<option value="0">ゼロ</option>
<option value="1">位置</option>
</select>
<input type="submit" value="ボタン">
aaa
</FORM>
</BODY>
</HTML>};

my $TMPL10_0 = q{<HTML>
<BODY>
<FORM method="post" action="test2.cgi"><input type="hidden" name="CCC" value="愛">
<select name="aa">
<option value="">空欄</option>
<option value="0" selected>ゼロ</option>
<option value="1">位置</option>
</select>
<input type="submit" value="ボタン">
aaa
</FORM>
</BODY>
</HTML>};

my $TMPL10_1 = q{<HTML>
<BODY>
<FORM method="post" action="test2.cgi"><input type="hidden" name="CCC" value="愛">
<select name="aa">
<option value="">空欄</option>
<option value="0">ゼロ</option>
<option value="1" selected>位置</option>
</select>
<input type="submit" value="ボタン">
aaa
</FORM>
</BODY>
</HTML>};

is(trim $t->setTemplate($TMPL10)->setForm({ aa => '' })->toStr, $TMPL10_undef, 'setForm empty value');
is(trim $t->setTemplate($TMPL10)->setForm({ aa => '0' })->toStr, $TMPL10_0, 'setForm 0 value');
is(trim $t->setTemplate($TMPL10)->setForm({ aa => '1' })->toStr, $TMPL10_1, 'setForm 1 value');


my $TMPL11 = <<EOF;
<form <&tag>>
  <input type="text" name="foo" value="">
</form>
EOF

dies_ok {
    $t->setTemplate($TMPL11)->setForm({foo => 100});
} 'setForm() with leaving unexpanded tags';

dies_ok {
    $t->setTemplate($TMPL11)->addHiddenForm({foo => 100});
} 'addHiddenForm() with leaving unexpanded tags';

lives_ok {
    $t->setTemplate($TMPL11)->expand({tag => 'aaa'})->setForm({foo => 100});
} 'setForm() without unexpanded tags';


my $TMPL12 = <<EOF;
<form>
  <input type="text" name="foo" value="">
  <!begin:foo>
    Hello, world!
  <!end:foo>
</form>
EOF

lives_ok {
    $t->setTemplate($TMPL12)->setForm({foo => 100});
} 'setForm() with <!mark> inside';


my $TMPL13 = <<EOF;
<&tag>
<form>
  <input type="text" name="foo" value="">
</form>
EOF

lives_ok {
    $t->setTemplate($TMPL13)->setForm({foo => 100});
} 'setForm() with leaving an unexpanded template tag outside any HTML tags';


my $TMPL14 = <<EOF;
<a href="JavaScript:taglistOpen('<&url>');"></a>
EOF
is (trim $t->setTemplate($TMPL14)
           ->setAttr(url => 'js')
           ->expand(url => 'http://.../hoge.cgi')
           ->toStr,
    q{<a href="JavaScript:taglistOpen('http://.../hoge.cgi');"></a>},
    'expanding tags in html tag');


my $TMPL15 = '<&foo>';
is (trim $t->setTemplate($TMPL15)
           ->setAttr(foo => 'raw')
           ->expand(foo => q{<a href="JavaScript:taglistOpen('http://.../hoge.cgi');"></a>})
           ->toStr,
    q{<a href="JavaScript:taglistOpen('http://.../hoge.cgi');"></a>},
    'expanding tags in html tag');


my $TMPL16 = <<EOF;
<form>
  <input type="radio" name="area" value="a" disabled>
  <input type="radio" name="area" value="b">
</form>
EOF
is (trim $t->setTemplate($TMPL16)->setForm({area => 'a'})->toStr,
    trim q{
      <form>
        <input type="radio" name="area" value="a" disabled="disabled" checked>
        <input type="radio" name="area" value="b">
      </form>
    });
is (trim $t->setTemplate($TMPL16)->setForm({area => 'b'})->toStr,
    trim q{
      <form>
        <input type="radio" name="area" value="a" disabled>
        <input type="radio" name="area" value="b" checked>
      </form>
    });


my $TMPL17 = <<EOF;
<form>
  <textarea name="foo"></textarea>
</form>
EOF
is ($t->setTemplate($TMPL17)->setForm({foo => "\n".'abcde'."\n"})->toStr,
    <<EOF);
<form>
  <textarea name="foo">

abcde
</textarea>
</form>
EOF

# -----------------------------------------------------------------------------
# trim.
#
test_trim();
sub test_trim
{
  my $tmpl;
  my $src = <<EOF;
  <table>
  <!begin:row>
  <tr>
    <!begin:item>
    <td><&LABEL></td>
    <!end:item>
  </tr>
  <!end:row>
  </table>
EOF

  $tmpl = $TL->newTemplate();
  $tmpl->setTemplate($src);
  $tmpl->node('row')->node('item')->trim();
  $tmpl->node('row')->node('item')->add({LABEL=>1});
  $tmpl->node('row')->node('item')->add({LABEL=>2});
  $tmpl->node('row')->trim->add;

  is($tmpl->toStr, <<EOF, "trim");
  <table>
  <tr>
    <td>1</td>
    <td>2</td>
  </tr>
  </table>
EOF

  $tmpl = $TL->newTemplate();
  $tmpl->setTemplate($src);
  $tmpl->node('row')->node('item')->trim('-join');
  $tmpl->node('row')->node('item')->add({LABEL=>1});
  $tmpl->node('row')->node('item')->add({LABEL=>2});
  $tmpl->node('row')->trim->add;

  is($tmpl->toStr, <<EOF, "trim(join)");
  <table>
  <tr><td>1</td><td>2</td></tr>
  </table>
EOF
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
