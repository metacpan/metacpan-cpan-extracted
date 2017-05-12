use utf8;
use strict;
use Test::More tests => 122;
use Text::Template::Compact;
use Encode;
use IO::Handle;
use Data::Dumper;
binmode STDOUT,":encoding(utf8)";
binmode STDERR,":encoding(utf8)";

{
	package Foo;
	sub new{
		my $class = shift;
		return bless[@_],$class;
	}
	sub hello{
		my $self = shift;
		return join(',',"hello!",@$self,@_,@{$_->{testif}});
	}
}

my $param = {
	text=>"this is text.",
	index=>"0",
	hash=>{ a => "深い階層にあるパラメータです", },
	tlist =>[
		"これはutf8フラグのついたテキストです",
		Encode::encode('cp932',"これはutf8フラグのないテキストです"),
	],
	htmltest => "日本語ABC<>&\"';[\n]",
	
	varlist =>[
		undef
		,'',' ','0E0'
		,0,1,2,3
		,0.0001
		,[1,2,3]
		,{ a=>1,b=>2,c=>3}
		,new IO::Handle
	],

	true => 1,

	testif =>[ (0..5)],
	
	obj => new Foo("わーるど"),
};

my $code='';
my $result='';
my $count = 0;
my $tmpl = new Text::Template::Compact;
$tmpl->param_encoding('cp932');
$tmpl->filter_default('html');
$tmpl->undef_supply( '(null)');
sub check{
	++$count;
	my $r = $tmpl->loadText("code$count",\$code);
	ok($r);
	if(not $r ){
		warn $tmpl->error;
		warn "<<<\n$code===\n";
	}else{
		my $try = $tmpl->toString($param);
		for( \$try ,\$result ){
			$$_ =~ s/\(eval \d+\)/(eval ***)/g;
			$$_ =~ s/\(0x[0-9A-Fa-f]+\)/(0x******)/g;
		}
		$try =~/\x0a$/ or $try .= "\x0a";
		ok( $try eq $result );
		if( $try ne $result){
			warn "!!!!not match.\n";
			warn "<<<\n$code>>>\n$try===\n";
			print STDERR Dumper($tmpl->{block}{''});
		}
	}
	$code ='';
	$result='';
}

my $rTo;
while(<DATA>){
	$_ =~s/[\x0d\x0a]+//g;
	   if( $_ eq '<<<'){ $rTo = \$code; }
	elsif( $_ eq '>>>'){ $rTo = \$result; }
	elsif( $_ eq '==='){ check();}
	else{ $$rTo .= $_."\x0a";}
}

__DATA__
<<<
$${}
>>>
${}
===
<<<
$${ }
>>>
${ }
===
<<<
$$
>>>
$$
===
<<<
$${
>>>
${
===
<<<
$$${
>>>
$${
===
<<<
${%print text}
>>>
this is text.
===
<<<
${text}
>>>
this is text.
===
<<<
${hash.a}
>>>
深い階層にあるパラメータです
===
<<<
${tlist.0}
>>>
これはutf8フラグのついたテキストです
===
<<<
${%evalperl "1" tmp}${tlist[tmp]}
>>>
これはutf8フラグのないテキストです
===
<<<
${index} ${text}
${%for text in tlist index 10}
  ${index} ${text}
${%end}
${index} ${text}
>>>
0 this is text.
  10 これはutf8フラグのついたテキストです
  11 これはutf8フラグのないテキストです
0 this is text.
===
<<<
${%blockdefine block1}
	${v}
${%end}
${%evalperl "1" v }
${%blockpaste block1}
${%evalperl "2" v }
${%blockpaste block1}
${%evalperl "3" v }
${%blockpaste block1}
>>>
	1
	2
	3
===
<<<
${%evalperl "0" v}
>>>

===
<<<
${%evalperl "$_->{loop}=[(1..10)]"}
>>>

===
<<<
${%for n in loop}
	${%evalperl "$a+1" v v}${v}
${%end}
>>>
	1
	2
	3
	4
	5
	6
	7
	8
	9
	10
===
<<<
${%evalperl "$_->{loop}=[(1..10]"}
>>>
[eval failed: syntax error at (eval 21) line 1, near "10]"
]
===
<<<
${htmltest}
>>>
日本語ABC&lt;&gt;&amp;&quot;&#39;;[<br>
]
===
<<<
${htmltest #raw}
>>>
日本語ABC<>&"';[
]
===
<<<
${htmltest#html}
>>>
日本語ABC&lt;&gt;&amp;&quot;&#39;;[<br>
]
===
<<<
${htmltest#nobr}
>>>
日本語ABC&lt;&gt;&amp;&quot;&#39;;[
]
===
<<<
${htmltest#uri}
>>>
%e6%97%a5%e6%9c%ac%e8%aa%9eABC%3c%3e%26%22'%3b%5b%0a%5d
===
<<<
${%for v in varlist}
v=[${v}], ?:=[${v?"true":"false"}] &&=[${v&&"true"}] ||=[${v||"false"}]
${%end}
>>>
v=[(null)], ?:=[false] &&=[(null)] ||=[false]
v=[], ?:=[false] &&=[] ||=[false]
v=[ ], ?:=[true] &&=[true] ||=[ ]
v=[0E0], ?:=[true] &&=[true] ||=[0E0]
v=[0], ?:=[false] &&=[0] ||=[false]
v=[1], ?:=[true] &&=[true] ||=[1]
v=[2], ?:=[true] &&=[true] ||=[2]
v=[3], ?:=[true] &&=[true] ||=[3]
v=[0.0001], ?:=[true] &&=[true] ||=[0.0001]
v=[ARRAY(0x******)], ?:=[true] &&=[true] ||=[ARRAY(0x******)]
v=[HASH(0x******)], ?:=[true] &&=[true] ||=[HASH(0x******)]
v=[IO::Handle=GLOB(0x******)], ?:=[true] &&=[true] ||=[IO::Handle=GLOB(0x******)]
===
<<<
${%evalperl "1" th}
>>>

===
<<<
${%for v  in varlist}
[${v}] ${%if defined v}defined,${%end
 }${%if not defined v }not defined,${%end
 }${%if length v }length,${%end
 }${%if not length v }not length,${%end
 }${%if bool v }bool,${%end
 }${%if not v }not,${%end
 }${%if nz v }nz,${%end
 }${%if v > th }>${th},${%end
 }
${%end}
>>>
[(null)] not defined,not length,not,
[] defined,not length,not,
[ ] defined,length,bool,
[0E0] defined,length,bool,
[0] defined,length,not,
[1] defined,length,bool,nz,
[2] defined,length,bool,nz,>1,
[3] defined,length,bool,nz,>1,
[0.0001] defined,length,bool,nz,
[ARRAY(0x******)] defined,length,bool,nz,>1,
[HASH(0x******)] defined,length,bool,nz,>1,
[IO::Handle=GLOB(0x******)] defined,length,bool,nz,>1,
===
<<<
${%for v in testif}
[${v}]${%if    v ==1 }first${%elsif v ==2 }second${%elsif v ==3 }third${%else}else${%end}CRLF
${%end}
>>>
[0]elseCRLF
[1]firstCRLF
[2]secondCRLF
[3]thirdCRLF
[4]elseCRLF
[5]elseCRLF
===
<<<
${%for v in testif}
[${v}]${%ifc "$a==1" v }first${%elsifc "$a==2" v }second${%elsifc "$a==3" v }third${%else}else${%end}CRLF
${%end}
>>>
[0]elseCRLF
[1]firstCRLF
[2]secondCRLF
[3]thirdCRLF
[4]elseCRLF
[5]elseCRLF
===
<<<
${ 1,2,3 }
>>>
123
===
<<<
${ 1,2,print 3 }
>>>
312
===
<<<
${ print 1,2,3 }
>>>
123
===
<<<
${ 1,2,print 3,4 }
>>>
3412
===
<<<
${ join ",",1,2,3,4 }
>>>
1,2,3,4
===
<<<
${ 1,2,join ",",3,4 }
>>>
123,4
===
<<<
${ 1,2,scalar 3,4 }
>>>
122
===
<<<
${ defined(1,undef) }
>>>
0
===
<<<
${ print(1,2,3,(4)) }
>>>
1234
===
<<<
${ a=1,b=2,print a,b }
>>>
1212
===
<<<
${%eval a=1,b=2,print a,b }
>>>
12
===
<<<
${
	Loop: %for item in testif;
		%for item2 in testif;
			%if item2==item+1;
				%print "break!";
				%break;
			%end;
			%if item==5 and item2==4;
				%print "break loop!";
				%break Loop;
			%end;
			item2,",";
		%end;
	%end;
}
>>>
0,break!0,1,break!0,1,2,break!0,1,2,3,break!0,1,2,3,4,break!0,1,2,3,break loop!
===
<<<
${
	%while
		init i=0
		precheck i<10
		step i++
		;
		%print i,",";
	%end;
}
>>>
0,1,2,3,4,5,6,7,8,9,
===
<<<
${
	%while
		init i=0
		postcheck i<10
		step i++
		;
		%print i,",";
	%end;
}
>>>
0,1,2,3,4,5,6,7,8,9,10,
===
<<<
${
	%while
		init i=0
		postcheck i<10
		step i++
		final print i
		;
		%print i,",";
		%if i==7; %break; %end;
	%end;
}
>>>
0,1,2,3,4,5,6,7,7
===
<<<
${%eval push $$trim,18}
${%evalperl "0" v0}
${%evalperl "1" v1}
${%evalperl "2" v2}
${%evalperl "3" v3}
${%evalperl "[0,1,2,3]" va}
${%evalperl "[0,1,2,3]" $2 }
${%evalperl "{v2=>'hello',va=>[0,1,2,3]}" vh}
${%evalperl "'yes,defined'" $defined}
${%eval pop $$trim}
>>>

===
<<<
${va[2]}
>>>
2
===
<<<
${va[-1]}
>>>
3
===
<<<
${va[v2]}
>>>
2
===
<<<
${vh["v2"]}
>>>
hello
===
<<<
${vh.v2}
>>>
hello
===
<<<
${va.-1}
>>>
3
===
<<<
${va.(1+2)}
>>>
3
===
<<<
${vh."v2"}
>>>
hello
===
<<<
${va.2   }
>>>
2
===
<<<
${va.v3} (vaは配列なので'v3'は数値コンテキストで解釈されて0になる)
>>>
0 (vaは配列なので'v3'は数値コンテキストで解釈されて0になる)
===
<<<
${vh.(va.2)}
>>>
2
===
<<<
${ $2.2}
>>>
2
===
<<<
${ $.2.2}
>>>
2
===
<<<
${ $[2].2}
>>>
2
===
<<<
${ $defined }
>>>
yes,defined
===
<<<
${ $"defined" }
>>>
yes,defined
===
<<<
${%eval rv=call(obj,"hello",1,2,3),print "rv=",rv}
>>>
rv=hello!,わーるど,1,2,3,0,1,2,3,4,5
===
<<<
${%eval v=makearray(1,3,5);print v[-1]; }
>>>
5
===
<<<
${%eval v=makehash("a",1,"b",3,"c",5);print v.b; }
>>>
3
===
