use Test::More tests => 7;
BEGIN { use_ok('Text::InHTML') };

my $text = <<"END_TEXT";
\ttab\ttab
 one one
  two  two
   three   three
    four    four
     five     five
      six      six
END_TEXT

my $html = <<"END_HTML";
&nbsp; &nbsp; tab&nbsp; &nbsp; tab<br />
 one one<br />
&nbsp; two&nbsp; two<br />
&nbsp; &nbsp;three&nbsp; &nbsp;three<br />
&nbsp; &nbsp; four&nbsp; &nbsp; four<br />
&nbsp; &nbsp; &nbsp;five&nbsp; &nbsp; &nbsp;five<br />
&nbsp; &nbsp; &nbsp; six&nbsp; &nbsp; &nbsp; six<br />
END_HTML

ok(Text::InHTML::encode_whitespace($text) eq $html, 'whitespace handling');

eval {  Text::InHTML::encode_plain($text);  };
ok(!$@, 'Can do defined');

eval {  Text::InHTML::encode_perl($text);  };
ok(!$@, 'autoload Exporter funtion');

eval {  Text::InHTML::encode_c($text);  };
ok(!$@, 'autoload non-Exporter function name');

eval {  Text::InHTML::encode_xhtml_strict($text);  };
ok(!$@, 'autoload dash format name');

eval {  Text::InHTML::bad_autoload($text);  };
ok($@, 'not autoload invalid function name');

