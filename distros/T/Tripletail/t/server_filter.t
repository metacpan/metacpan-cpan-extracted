# -*- perl -*-
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Config;
use Data::Dumper;
use lib '.';
use t::test_server;

&setup;
plan tests => 4 + 4 + 2 + 1 + 8 + 1 + 2 + 10 + 1;
&test_01_html;              #4.
&test_02_mobile_html;       #4.
&test_03_csv;               #2.
&test_04_binary;            #1.
&test_05_input_filter;      #8.
&test_06_seo_filter;        #1.
&test_07_seo_input_filter;  #2.
&test_08_xhtml;             #10.
&test_09_input_filter_mobile; # 1.
exit;

# -----------------------------------------------------------------------------
# shortcut.
# 
sub check_requires() { &t::test_server::check_requires; }
sub start_server()   { &t::test_server::start_server; }
sub raw_request(@)   { &t::test_server::raw_request; }

# -----------------------------------------------------------------------------
# setup.
# 
sub setup
{
	my $failmsg = check_requires();
	if( $failmsg )
	{
		plan skip_all => $failmsg;
	}
	
	&start_server;
}

# -----------------------------------------------------------------------------
# Tripletail::Filter::HTML.
# 
sub test_01_html
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					$TL->print(q{<form></form>});
				}
			},
		);
		is($res->content, qq{<form action="/"><input type="hidden" name="CCC" value="\x88\xa4"></form>}, '[html] CCC');
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					$TL->print(q{<A HREF="} . $TL->newForm->set('あ' => 'い')->toLink . qq{"></a>\n});
					$TL->print($TL->newTemplate->setTemplate(qq{<a href="<&URL>">link</a>\n})
						->expand(URL => $TL->newForm->set('あ' => 'い')->toLink) ->toStr);
					my $t = $TL->newTemplate->setTemplate(qq{<!begin:node><a href="<&URL>">link</a><!end:node>\n});
					$t->node('node')->add(URL => $TL->newForm->set('あ' => 'い')->toLink);
					$TL->print($t->toStr);
					$TL->print(q{<a href="} . $TL->newForm->set('あ' => 'い')->toExtLink . qq{"></a>\n});
					$TL->print(q{<A HREF="} . $TL->newForm->set('あ' => 'い')->toExtLink(undef, 'Shift_JIS') . qq{"></a>\n});
				}
			},
		);
		is($res->content, qq{<A HREF="./?%82%a0=%82%a2&amp;CCC=%88%a4"></a>\n<a href="./?%82%a0=%82%a2&amp;CCC=%88%a4">link</a>\n<a href="./?%82%a0=%82%a2&amp;CCC=%88%a4">link</a>\n<a href="./?%e3%81%82=%e3%81%84"></a>\n<A HREF="./?%82%a0=%82%a2"></a>\n}, '[html] (toLink/toExtLink)');
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					$TL->print(q{<form action=""></form>});
				}
			},
		);
		is($res->content, qq{<form action="/"><input type="hidden" name="CCC" value="\x88\xa4"></form>}, '[html] Form output');
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $t = $TL->newTemplate->setTemplate(q{<form action=""></form>})->extForm;
					$TL->print($t->toStr);
				}
			},
		);
		is($res->content, qq{<form action="/"></form>}, '[html] extForm');
	}
}
	
# -----------------------------------------------------------------------------
# Tripletail::Filter::MobileHTML
# 
sub test_02_mobile_html
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setContentFilter('Tripletail::Filter::MobileHTML');
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					$TL->print(q{<a href="http://www.example.org/">link</a>});
				}
			},
		);
		is $res->content, qq{<a href="http://www.example.org/">link</a>}, '[mobile] normal';
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setContentFilter('Tripletail::Filter::MobileHTML');
				$TL->getContentFilter->addHeader('X-TEST',123);
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					$TL->print(q{<a href="} . $TL->newForm->set('あ' => 'い')->toLink . qq{"></a>\n});
					$TL->print(q{<a href="} . $TL->newForm->set('あ' => 'い')->toExtLink . qq{"></a>\n});
					$TL->print(q{<a href="} . $TL->newForm->set('あ' => 'い')->toExtLink(undef, 'Shift_JIS') . qq{"></a>\n});
				}
			},
		);
		is $res->content, qq{<a href="./?%82%a0=%82%a2&amp;CCC=%88%a4"></a>\n<a href="./?%e3%81%82=%e3%81%84"></a>\n<a href="./?%82%a0=%82%a2"></a>\n}, '[mobile] toLink/toExtLink';
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setContentFilter('Tripletail::Filter::MobileHTML');
				$TL->getContentFilter->addHeader('X-TEST',123);
				$TL->getContentFilter->addHeader('X-TEST',1234);
				$TL->startCgi(
					-main => \&main,
				 );
				sub main {
					$TL->print(q{<form action=""></form>});
				}
			},
		);
		is $res->content, qq{<form action="/"><input type="hidden" name="CCC" value="\x88\xa4"></form>}, '[mobile] Form output';
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setContentFilter('Tripletail::Filter::MobileHTML');
				$TL->getContentFilter->setHeader('X-TEST',123);
				$TL->getContentFilter->addHeader('X-TEST',1234);
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					my $t = $TL->newTemplate->setTemplate(q{<form action=""></form>})->extForm;
					$TL->print($t->toStr);
				}
			},
		);
		is($res->content, qq{<form action="/"></form>}, '[mobile] extForm');
	}
}

# -----------------------------------------------------------------------------
# Tripletail::Filter::CSV
# 
sub test_03_csv
{
	SKIP:
	{
		eval{ require Text::CSV_XS; };
		if ($@) {
			skip 'Text::CSV_XS is unavailable', 1;
		}
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setContentFilter(
					'Tripletail::Filter::CSV',
					charset  => 'UTF-8',
					filename => 'foo.csv',
				);
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					$TL->print(['aaa', 'bb', 'cc,c']);
					$TL->print('AAA,BB,"CC,C"'."\r\n");
				}
			},
		);
		is $res->content, qq{aaa,bb,"cc,c"\r\nAAA,BB,"CC,C"\r\n}, '[csv]';
		
		$res = raw_request(
			method => 'GET',
			script => q{
				$TL->setContentFilter(
					'Tripletail::Filter::CSV',
					charset  => 'UTF-8',
					filename => 'foo.csv',
					linebreak => "\n",
				);
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					$TL->print(['aaa', 'bb', 'cc,c']);
					$TL->print('AAA,BB,"CC,C"'."\n");
				}
			},
		);
		is $res->content, qq{aaa,bb,"cc,c"\nAAA,BB,"CC,C"\n}, '[csv]';
	}
}

# -----------------------------------------------------------------------------
# Tripletail::Filter::Binary
# 
sub test_04_binary
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setContentFilter('Tripletail::Filter::Binary');
				$TL->startCgi(
					-main => \&main,
				 );
				sub main {
					$TL->print("\x{de}\x{ad}\x{be}\x{ef}"); #"
				}
			},
		);
		is $res->content, "\x{de}\x{ad}\x{be}\x{ef}", '[binary]';
	}
}

# -----------------------------------------------------------------------------
# Tripletail::InputFilter::HTML (default input filter)
# 
sub test_05_input_filter
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				 );
				sub main {
					$TL->print(
						sprintf('%s-%s', $TL->CGI->getSliceValues(qw[foo bar])),
				 );
				}
			},
			env => {
				QUERY_STRING => 'foo=A%20B&bar=C%20D&CCC=%88%A4',
			},
		);
		is $res->content, 'A B-C D', '[input] get';
	}
	
	{
		my $res = raw_request(
			method => 'POST',
    	stdin  => 'foo=a%20b&bar=c%20d',
		);
		is $res->content, 'a b-c d', '[input] post';
	}
	
	{
		my $res = raw_request(
			method => 'POST',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
				$TL->print(join ',', $CGI->getKeys);
				$TL->print('---');
				$TL->print(join ',', $CGI->getFileKeys);
				}
			},
			env => {},
			ini => {
				TL => {
					trap => 'diewithprint',
					stacktrace => 'none',
				},
			},
			stdin =>
				qq{This is a preamble.\r\n}.
				qq{\r\n}.
				qq{--BOUNDARY\r\n}.
				qq{Content-Disposition: form-data; name="Command"\r\n}.
				qq{\r\n}.
				qq{DoUpload\r\n}.
				qq{--BOUNDARY\r\n}.
				qq{Content-Disposition: form-data;\r\n}.
				qq{    name="File";\r\n}.
				qq{    filename="data.txt"\r\n}.
				qq{\r\n}.
				qq{Ged a sheo'l mi fada bhuaip\r\n}.
				qq{Air long nan crannaibh caola\r\n}.
				qq{--BOUNDARY--\r\n}.
				qq{\r\n}.
				qq{This is a epilogue.},
			params => [
				'Content-Type' => 'multipart/form-data; boundary="BOUNDARY"',
			],
		);
		is $res->content, 'Command---File', '[input] multipart/form-data [0]';
	}
	
	{
		my $res = raw_request(
			method => 'POST',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					$TL->print($CGI->getFileName('File'));
				}
			},
			params => [
				'Content-Type' => 'multipart/form-data; boundary="BOUNDARY"',
			],
		);
		is $res->content, 'data.txt', '[input] multipart/form-data [1]';
	}
	
	{
		my $res = raw_request(
			method => 'POST',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					local $/ = undef;
					my $fh = $CGI->getFile('File');
					$TL->print(<$fh>);
				}
			},
			params => [
				'Content-Type' => 'multipart/form-data; boundary="BOUNDARY"',
			],
		);
		is $res->content,
			 qq{Ged a sheo'l mi fada bhuaip\r\n}.
			 qq{Air long nan crannaibh caola}, '[input] multipart/form-data [2]';
	}

    {
		my $res = raw_request(
			method => 'POST',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					local $/ = undef;
					my $fh = $CGI->getFile('File', 'UTF-8', 'UTF-16');
					$TL->print(<$fh>);
				}
			},
			params => [
				'Content-Type' => 'multipart/form-data; boundary="BOUNDARY"',
			],
		);
		is $res->content,
			 qq{\0G\0e\0d\0 \0a\0 \0s\0h\0e\0o\0'\0l\0 \0m\0i\0 \0f\0a\0d\0a\0 \0b\0h\0u\0a\0i\0p\0\r\0\n}.
			 qq{\0A\0i\0r\0 \0l\0o\0n\0g\0 \0n\0a\0n\0 \0c\0r\0a\0n\0n\0a\0i\0b\0h\0 \0c\0a\0o\0l\0a}, '[input] multipart/form-data [2.5]';
	}
	
	{
		my $res = raw_request(
			method => 'POST',
			ini => {
				TL => {
					'trap' => 'diewithprint',
					'stacktrace' => 'none',
					'tempdir' => '.',
				},
			},
            script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					local $/ = undef;
					my $fh = $CGI->getFile('File');
					$TL->print(<$fh>);
				}
			},
			params => [
				'Content-Type' => 'multipart/form-data; boundary="BOUNDARY"',
			],
		);
		is $res->content,
			 qq{Ged a sheo'l mi fada bhuaip\r\n}.
			 qq{Air long nan crannaibh caola}, '[input] multipart/form-data [3]';
	}

	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				 );
				sub main {
					$TL->setContentFilter('Tripletail::Filter::HTML', charset => 'UTF-8');
					$TL->print(
						sprintf('%s-%s', $TL->CGI->getSliceValues(qw[foo bar])),
				 );
				}
			},
			env => {
				QUERY_STRING => 'foo=%e3%81%84%e3%81%ac&bar=C%20D',
			},
			ini => {
				'InputFilter' => {
					charset => 'UTF-8',
				},
			},
		);
		# テスト文字は自動判定で文字化けする文字なら何でもよい
		is $res->content, 'いぬ-C D', '[input] get UTF-8(no CCC)';
	}
	
}

# -----------------------------------------------------------------------------
# SEO出力
# 
sub test_06_seo_filter
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setContentFilter(['Tripletail::Filter::SEO', 1001]);
				$TL->startCgi(
					-main => \&main,
				 );
				sub main {
					$TL->getContentFilter(1001)->setOrder(qw(ID Name));
					$TL->getContentFilter(1001)->toLink($TL->newForm(KEY => 'VALUE'));
					$TL->print(q{<head><base href="http://www.example.org/"></head><body><a href="foo.cgi?SEO=1&aaa=111">link</a></body>});
				}
			},
		);
		is $res->content,
			 q{<head><base href="http://localhost/"></head><body><a href="foo/aaa/111">link</a></body>}, '[seo]';
	}
}

# -----------------------------------------------------------------------------
# SEO入力
# 
sub test_07_seo_input_filter
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setInputFilter(['Tripletail::InputFilter::SEO', 999]);
				$TL->startCgi(
					-main => \&main,
				 );
				sub main {
					$TL->print("--" . $TL->CGI->get('aaa') . "--");
				}
			},
			env => {
				PATH_INFO => '/aaa/SEO',
			},
		);
		is $res->content, '--SEO--', '[seo-in]';
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setInputFilter(['Tripletail::InputFilter::SEO', 999]);
				$TL->startCgi(
					-main => \&main,
				 );
				sub main {
					$TL->print("--" . $TL->CGI->get('aaa') . "--");
				}
			},
			env => {
				PATH_INFO => '/aaa/',
			},
		);
		is $res->content, '----', '[seo-in]';
	}
}

# -----------------------------------------------------------------------------
# Tripletail::Filter::HTML + xhtml.
# 
sub test_08_xhtml
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'html';
					my $tmpl = q{<form action="">};
					$tmpl   .= q{<input type="text" name="text">};
					$tmpl   .= q{</form>};
					my $form = { text => 'val' };
					my $t = $TL->newTemplate->setTemplate($tmpl)->setForm($form)->extForm;
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($t->toStr);
				}
			},
		);
		my $c = $res->content();
		$c =~ s{<form action="/">|</form>}{}g;
		is($c, qq{<input type="text" name="text" value="val">}, '[xhtml] text (html)');
	}
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'xhtml';
					my $tmpl = q{<form action="">};
					$tmpl   .= q{<input type="text" name="text">};
					$tmpl   .= q{</form>};
					my $form = { text => 'val' };
					my $t = $TL->newTemplate->setTemplate($tmpl)->setForm($form)->extForm;
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($t->toStr);
				}
			},
		);
		my $c = $res->content();
		$c =~ s{<form action="/">|</form>}{}g;
		is($c, qq{<input type="text" name="text" value="val" />}, '[xhtml] text (xhtml)');
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'html';
					my $tmpl = q{<form action="">};
					$tmpl   .= q{<input type="radio" name="radio" value="val">};
					$tmpl   .= q{</form>};
					my $form = { radio => 'val' };
					my $t = $TL->newTemplate->setTemplate($tmpl)->setForm($form)->extForm;
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($t->toStr);
				}
			},
		);
		my $c = $res->content();
		$c =~ s{<form action="/">|</form>}{}g;
		is($c, qq{<input type="radio" name="radio" value="val" checked>}, '[xhtml] radio (html)');
	}
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'xhtml';
					my $tmpl = q{<form action="">};
					$tmpl   .= q{<input type="radio" name="radio" value="val">};
					$tmpl   .= q{</form>};
					my $form = { radio => 'val' };
					my $t = $TL->newTemplate->setTemplate($tmpl)->setForm($form)->extForm;
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($t->toStr);
				}
			},
		);
		my $c = $res->content();
		$c =~ s{<form action="/">|</form>}{}g;
		is($c, qq{<input type="radio" name="radio" value="val" checked="checked" />}, '[xhtml] radio (xhtml)');
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'html';
					my $tmpl = q{<form action="">};
					$tmpl   .= q{<input type="checkbox" name="chk" value="val">};
					$tmpl   .= q{</form>};
					my $form = { chk => 'val' };
					my $t = $TL->newTemplate->setTemplate($tmpl)->setForm($form)->extForm;
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($t->toStr);
				}
			},
		);
		my $c = $res->content();
		$c =~ s{<form action="/">|</form>}{}g;
		is($c, qq{<input type="checkbox" name="chk" value="val" checked>}, '[xhtml] checkbox (html)');
	}
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'xhtml';
					my $tmpl = q{<form action="">};
					$tmpl   .= q{<input type="checkbox" name="chk" value="val">};
					$tmpl   .= q{</form>};
					my $form = { chk => 'val' };
					my $t = $TL->newTemplate->setTemplate($tmpl)->setForm($form)->extForm;
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($t->toStr);
				}
			},
		);
		my $c = $res->content();
		$c =~ s{<form action="/">|</form>}{}g;
		is($c, qq{<input type="checkbox" name="chk" value="val" checked="checked" />}, '[xhtml] checkbox (xhtml)');
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'html';
					my $tmpl = q{<form action="">};
					$tmpl   .= q{<select name="sel">};
					$tmpl   .= q{<option value="val">label</option>};
					$tmpl   .= q{</select>};
					$tmpl   .= q{</form>};
					my $form = { sel => 'val' };
					my $t = $TL->newTemplate->setTemplate($tmpl)->setForm($form)->extForm;
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($t->toStr);
				}
			},
		);
		my $c = $res->content();
		$c =~ s{<form action="/">|</form>}{}g;
		$c =~ s{<select name="sel">|</select>}{}g;
		is($c, qq{<option value="val" selected>label</option>}, '[xhtml] option (html)');
	}
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'xhtml';
					my $tmpl = q{<form action="">};
					$tmpl   .= q{<select name="sel">};
					$tmpl   .= q{<option value="val">label</option>};
					$tmpl   .= q{</select>};
					$tmpl   .= q{</form>};
					my $form = { sel => 'val' };
					my $t = $TL->newTemplate->setTemplate($tmpl)->setForm($form)->extForm;
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($t->toStr);
				}
			},
		);
		my $c = $res->content();
		$c =~ s{<form action="/">|</form>}{}g;
		$c =~ s{<select name="sel">|</select>}{}g;
		is($c, qq{<option value="val" selected="selected">label</option>}, '[xhtml] option (xhtml)');
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'html';
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($TL->newTemplate()->setTemplate("1<br><&VAL>")->setAttr(VAL=>'br')->expand(VAL=>"test\nmsg\n")->toStr());
				}
			},
		);
		my $c = $res->content();
		is($c, qq{1<br>test<br>\nmsg<br>\n}, '[xhtml] br (html)');
	}
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				
				sub main {
					my $filt = 'xhtml';
					$TL->setContentFilter('Tripletail::Filter::HTML',type=>$filt);
					$TL->print($TL->newTemplate()->setTemplate("1<br><&VAL>")->setAttr(VAL=>'br')->expand(VAL=>"test\nmsg\n")->toStr());
				}
			},
		);
		my $c = $res->content();
		is($c, qq{1<br />test<br />\nmsg<br />\n}, '[xhtml] br (xhtml)');
	}
	
}

# -----------------------------------------------------------------------------
# Tripletail::InputFilter::MobileHTML
# 
sub test_09_input_filter_mobile
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->setInputFilter('Tripletail::InputFilter::MobileHTML');
				$TL->startCgi(
					-main => \&main,
				 );
				sub main {
					$TL->setContentFilter('Tripletail::Filter::HTML', charset => 'UTF-8');
					$TL->print(
						sprintf('%s-%s', $TL->CGI->getSliceValues(qw[foo bar])),
				 );
				}
			},
			env => {
				QUERY_STRING => 'foo=%e3%81%84%e3%81%ac&bar=C%20D',
			},
			ini => {
				InputFilter => {
					charset => 'UTF-8',
				},
			},
		);
		# テスト文字は自動判定で文字化けする文字なら何でもよい
		is $res->content, 'いぬ-C D', '[input] get UTF-8(no CCC)';
	}
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
