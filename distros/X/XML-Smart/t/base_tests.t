use strict                  ;
use warnings FATAL => 'all' ;

use Test::More              ;

use ExtUtils::MakeMaker     ;

use XML::Smart              ;


my $DATA = q`<?xml version="1.0" encoding="iso-8859-1"?>
<hosts>
    <server os="linux" type="redhat" version="8.0">
      <address>192.168.0.1</address>
      <address>192.168.0.2</address>
    </server>
    <server os="linux" type="suse" version="7.0">
      <address>192.168.1.10</address>
      <address>192.168.1.20</address>
    </server>
    <server address="192.168.2.100" os="linux" type="conectiva" version="9.0"/>
    <server address="192.168.3.30" os="bsd" type="freebsd" version="9.0"/>
</hosts>
`;


##if (0) {
#########################
subtest 'HTML Tests' => sub {

    my  $XML = XML::Smart->new( q`
  <html>
    <head>
      <title>Blah blah</title>
    </head>
    <body>
      <form>
        <input id="0"/>        
        <br/>
        <input id="2"/>
        <br/>            
      </form>
    </body>
    <null/>
  </html>
  ` );
  
  my $data = $XML->data( noheader => 1 ) ;
  $data =~ s/\s+/ /gs ;
  
  cmp_ok($data, 'eq', q`<html> <head> <title>Blah blah</title> </head> <body> <form> <input id="0"/> <br/> <input id="2"/> <br/> </form> </body> <null/> </html> `) ;
  
  my @order = $XML->{html}{body}{form}->order ;
  cmp_ok( join(" ", @order), 'eq', 'input br input br') ;
  
  $XML->{html}{body}{form}->set_order( qw(br input input br) ) ;
  @order = $XML->{html}{body}{form}->order ;
  cmp_ok( join(" ", @order), 'eq', 'br input input br') ;

  $data = $XML->data( noheader => 1 ) ;
  $data =~ s/\s+/ /gs ;
  
  cmp_ok( $data, 'eq', q`<html> <head> <title>Blah blah</title> </head> <body> <form> <br/> <input id="0"/> <input id="2"/> <br/> </form> </body> <null/> </html> `) ;

    done_testing() ;

} ;



subtest 'Pointer Tests' => sub {

  my $XML = XML::Smart->new(q`
<root>
content0
<tag1 arg1="123">
  <sub arg="1">sub_content</sub>
</tag1>
content1
<tag2 arg1="123"/>
content2
</root>
  ` , 'XML::Smart::Parser') ;
  
  my $data = $XML->data(noheader => 1) ;
  
  cmp_ok($data, 'eq', q`<root>
content0
<tag1 arg1="123">
    <sub arg="1">sub_content</sub></tag1>
content1
<tag2 arg1="123"/>
content2
</root>

`) ;
  

  my $tmp = tied $XML->{root}->pointer->{CONTENT} ;
  isnt( tied $XML->{root}->pointer->{CONTENT}, undef ) ;
  
  my $cont = $XML->{root}->{CONTENT} ;
  
  cmp_ok($cont, 'eq', q`
content0

content1

content2
`) ;
  
  my $cont_ = $XML->{root}->content ;

  cmp_ok( $cont_, 'eq', q`
content0

content1

content2
`) ;
  
  $XML->{root}->content(1,"set1") ;
  
  my @cont = $XML->{root}->content ;
  
  cmp_ok($cont[0], 'eq', "\ncontent0\n") ;
  cmp_ok($cont[1], 'eq', "set1") ;
  cmp_ok($cont[2], 'eq', "\ncontent2\n") ;
  
  $XML->{root}->{CONTENT} = 123 ;
  
  my $cont_2 = $XML->{root}->content ;
  
  subtest 'Perl Version Tests' => sub { 
      if( $] >= 5.007 && $] <= 5.008 ) { 
	  plan skip_all => "Skip on $]" ;
      }
      cmp_ok( $cont_2, '==', 123) ;
      is( tied $XML->{root}->pointer->{CONTENT}, undef ) ;
      done_testing() ;
  } ;
  
  
  is( tied $XML->{root}{tag1}{sub}->pointer->{CONTENT}, undef, 'Undefined' ) ;
  
  my $sub_cont = $XML->{root}{tag1}{sub}->{CONTENT} ;
  
  cmp_ok($sub_cont, 'eq',  'sub_content') ;
  
  $data = $XML->data(noheader => 1) ;
  
  subtest 'Perl Version Tests' => sub { 
      if( $] >= 5.007 && $] <= 5.008 ) { 
	  plan skip_all => "Skip on $]" ;
      }
      cmp_ok( $data , 'eq', q`<root>123<tag1 arg1="123">
    <sub arg="1">sub_content</sub>
  </tag1>
  <tag2 arg1="123"/></root>

`
	  ) ;
      done_testing() ;
  
  };

  done_testing() ;

} ;





subtest 'Content Set tests' => sub {
  
  my $xml = new XML::Smart(q`<?xml version="1.0" encoding="iso-8859-1" ?>
<root>
  <phone>aaa</phone>
  <phone>bbb</phone>
</root>
`) ;

  $xml = $xml->{root} ;

  $xml->{phone}->content('XXX') ;
  
  $xml->{phone}[1]->content('YYY') ;

  $xml->{test}->content('ZZZ') ;

  my $data = $xml->data(noheader => 1) ;

  cmp_ok($data, 'eq', q`<root>
  <phone>XXX</phone>
  <phone>YYY</phone>
  <test>ZZZ</test>
</root>

`) ;  

  done_testing() ;

} ;





subtest 'Data Order Tests' => sub {

  my $xml = new XML::Smart(q`
<foo>
TEXT1 & more
<if.1>
  aaa
</if.1>
<!-- CMT -->
<elsif.2>
  bbb
</elsif.2>
</foo>  
  `,'html') ;
  
  my $data = $xml->data(noident=>1 , noheader => 1 , wild=>1) ;
  
  cmp_ok($data, 'eq', q`<foo>
TEXT1 &amp; more
<if.1>
  aaa
</if.1>
<!-- CMT -->
<elsif.2>
  bbb
</elsif.2></foo>

`) ;

  done_testing() ;

} ;
#########################



subtest 'XML::Smart::Parser Tests' => sub {

  my $XML = XML::Smart->new('<a>text1<b>foo</b><c>bar</c>text2</a>' , 'XML::Smart::Parser') ;

  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//g ;

  cmp_ok($data, 'eq', '<a>text1<b>foo</b><c>bar</c>text2</a>') ;

  done_testing() ;
  
} ;
#########################



subtest 'XML::Smart::Parser args test' => sub {

  my $XML = XML::Smart->new('<root><foo bar="x"/></root>' , 'XML::Smart::Parser') ;
  my $data = $XML->data(noheader => 1) ;
  
  $data =~ s/\s//gs ;
  cmp_ok($data, 'eq', '<root><foobar="x"/></root>') ;

  done_testing() ;

} ;
#########################



subtest 'XML::Smart::Parser nometagen tests' => sub {
  
  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  
  my $data = $XML->data(nometagen => 1) ;
  $data =~ s/\s//gs ;
  
  my $data_org = $DATA ;
  $data_org =~ s/\s//gs ;
  
  cmp_ok( $data, 'eq', $data_org) ;

  done_testing() ;
    
} ;
#########################



subtest 'XML::Smart::HTMLParser Tests' => sub {

  my $XML = XML::Smart->new('<root><foo bar="x"/></root>' , 'XML::Smart::HTMLParser') ;
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  cmp_ok( $data, 'eq', '<root><foobar="x"/></root>' ) ;
  
  $XML = XML::Smart->new(q`
  <html><title>TITLE</title>
  <body bgcolor='#000000'>
    <foo1 baz="y1=name\" bar1=x1 > end" w=q>
    <foo2 bar2="" arg0 x=y>FOO2-DATA</foo2>
    <foo3 bar3=x3>
    <foo4 url=http://www.com/dir/file.x?query=value&x=y>
  </body>
  </html>
  ` , 'HTML') ;
  
  $data = $XML->data(noheader => 1 , nospace => 1 ) ;
  cmp_ok($data, 'eq', q`<html><title>TITLE</title><body bgcolor="#000000"><foo1 baz='y1=name\" bar1=x1 &gt; end' w="q"/><foo2 bar2="" arg0="" x="y">FOO2-DATA</foo2><foo3 bar3="x3"/><foo4 url="http://www.com/dir/file.x?query=value&amp;x=y"/></body></html>`) ;

  $XML = XML::Smart->new(q`
  <html><title>TITLE</title>
  <body bgcolor='#000000'>
    <foo1 bar1=x1>
    <SCRIPT LANGUAGE="JavaScript"><!--
    function stopError() { return true; }
    window.onerror = stopError;
    document.writeln("some >> written!");
    --></SCRIPT>
    <foo2 bar2=x2>
  </body></html>
  ` , 'HTML') ;
  
  $data = $XML->data(noheader => 1 , nospace => 1) ;
  $data =~ s/\s//gs ;
  
  cmp_ok($data, 'eq', q`<html><title>TITLE</title><bodybgcolor="#000000"><foo1bar1="x1"/><SCRIPTLANGUAGE="JavaScript"><!--functionstopError(){returntrue;}window.onerror=stopError;document.writeln("some>>written!");--></SCRIPT><foo2bar2="x2"/></body></html>`);

  done_testing() ;

} ;
#########################






subtest 'XML::Smart::HTMLParser args Tests' => sub {
  my $XML = XML::Smart->new(q`
  <root>
    <foo name='x' *>
      <.sub1 arg="1" x=1 />
      <.sub2 arg="2"/>
      <bar size="100,50" +>
      content
      </bar>
    </foo>
  </root>
  ` , 'XML::Smart::HTMLParser') ;
  
  my $data = $XML->data(noheader => 1 , wild => 1) ;
  
  cmp_ok( $data, 'eq', q`<root>
  <foo name="x" *>
    <.sub1 arg="1" x="1"/>
    <.sub2 arg="2"/>
    <bar size="100,50" +>
      content
      </bar>
  </foo>
</root>

`);

  done_testing() ;

} ;
#########################






subtest 'XML::Smart::Parser Tree tests' => sub {
  my $XML0 = XML::Smart->new(q`<root><foo1 name='x'/></root>` , 'XML::Smart::Parser') ;
  my $XML1 = XML::Smart->new(q`<root><foo2 name='y'/></root>` , 'XML::Smart::Parser') ;
  
  my $XML = XML::Smart->new() ;
  
  $XML->{sub}{sub2} = $XML0->tree ;
  push(@{$XML->{sub}{sub2}} , $XML1->tree ) ;
  
  my $data = $XML->data(noheader => 1) ;
  
  $data =~ s/\s//gs ;
  cmp_ok( $data, 'eq', '<sub><sub2><root><foo1name="x"/></root></sub2><sub2><root><foo2name="y"/></root></sub2></sub>') ;

  done_testing() ;

} ;
#########################




subtest 'XML::Smart::Parser Array Tests' => sub {

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  $XML = $XML->{hosts} ;
  
  my $addr = $XML->{server}[0]{address} ;
  cmp_ok($addr, 'eq', '192.168.0.1') ;
  
  my $addr0 = $XML->{server}[0]{address}[0] ;
  cmp_ok( $addr, 'eq', $addr0);
  
  my $addr1 = $XML->{server}{address}[1] ;
  cmp_ok( $addr1, 'eq', '192.168.0.2') ;
  
  my $addr01 = $XML->{server}[0]{address}[1] ;
  cmp_ok( $addr1, 'eq', $addr01);
  
  my @addrs = @{$XML->{server}{address}} ;
  
  cmp_ok( $addrs[0], 'eq', $addr0);
  cmp_ok( $addrs[1], 'eq', $addr1);
  
  @addrs = @{$XML->{server}[0]{address}} ;
  
  cmp_ok( $addrs[0], 'eq', $addr0);
  cmp_ok( $addrs[1], 'eq', $addr1);
  
  done_testing() ;

} ;
#########################




subtest 'XML::Smart::Parser args Tests' => sub {

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  $XML = $XML->{hosts} ;
  
  my $addr = $XML->{'server'}('type','eq','suse'){'address'} ;
  cmp_ok( $addr, 'eq', '192.168.1.10') ;
  
  my $addr0 = $XML->{'server'}('type','eq','suse'){'address'}[0] ;
  cmp_ok( $addr, 'eq', $addr0) ;
  
  my $addr1 = $XML->{'server'}('type','eq','suse'){'address'}[1] ;
  cmp_ok( $addr1, 'eq', '192.168.1.20') ;
  
  my $type = $XML->{'server'}('version','>=','9'){'type'} ;
  cmp_ok( $type, 'eq', 'conectiva') ;
  
  $addr = $XML->{'server'}('version','>=','9'){'address'} ;
  cmp_ok( $addr, 'eq', '192.168.2.100') ;
  
  $addr0 = $XML->{'server'}('version','>=','9'){'address'}[0] ;
  cmp_ok( $addr0, 'eq', $addr) ;

  done_testing() ;
    
} ;
#########################




subtest 'XML::Smart::Parser Args Array Tests' => sub {

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  $XML = $XML->{hosts} ;

  my $newsrv = {
      os => 'Linux' ,
      type => 'mandrake' ,
      version => 8.9 ,
      address => '192.168.3.201' ,
  } ;

  push(@{$XML->{server}} , $newsrv) ;
  
  my $addr0 = $XML->{'server'}('type','eq','mandrake'){'address'}[0] ;
  cmp_ok( $addr0, 'eq', '192.168.3.201') ;
  
  $XML->{'server'}('type','eq','mandrake'){'address'}[1] = '192.168.3.202' ;

  my $addr1 = $XML->{'server'}('type','eq','mandrake'){'address'}[1] ;
  cmp_ok( $addr1, 'eq', '192.168.3.202') ;
  
  push(@{$XML->{'server'}('type','eq','conectiva'){'address'}} , '192.168.2.101') ;

  $addr1 = $XML->{'server'}('type','eq','conectiva'){'address'}[1] ;
  cmp_ok( $addr1, 'eq', '192.168.2.101') ;
  
  $addr1 = $XML->{'server'}[2]{'address'}[1] ;
  cmp_ok( $addr1, 'eq', '192.168.2.101') ;
  
  done_testing() ;

} ;
#########################






subtest 'Args regex Match Tests' => sub {
  
  my $XML = XML::Smart->new(q`
  <users>
    <joe name="Joe X" email="joe@mail.com"/>
    <jonh name="JoH Y" email="jonh@mail.com"/>
    <jack name="Jack Z" email="jack@mail.com"/>
  </users>
  ` , 'XML::Smart::Parser') ;
  
  my @users = $XML->{users}('email','=~','^jo') ;
  
  cmp_ok( $users[0]->{name}, 'eq', 'Joe X') ;
  cmp_ok( $users[1]->{name}, 'eq', 'JoH Y') ;

  done_testing() ;
  
} ;
#########################




subtest 'Default Parser Array Test' => sub {

  my $XML = XML::Smart->new() ;
  
  $XML->{server} = {
      os => 'Linux' ,
      type => 'mandrake' ,
      version => 8.9 ,
      address => '192.168.3.201' ,
  } ;
  
  $XML->{server}{address}[1] = '192.168.3.202' ;
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
    
  my $dataok = q`<serveros="Linux"type="mandrake"version="8.9"><address>192.168.3.201</address><address>192.168.3.202</address></server>`;
  cmp_ok( $data, 'eq', $dataok ) ;

  done_testing() ;

} ;
#########################






subtest 'XML::Smart::Parser tags Test' => sub {

  my $XML = XML::Smart->new('<foo port="80">ct<i>a</i><i>b</i></foo>' , 'XML::Smart::Parser') ;
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  my $dataok = qq`<fooport="80">ct<i>a</i><i>b</i></foo>` ;
  
  cmp_ok( $data, 'eq', $dataok ) ;

  done_testing() ;

} ;
#########################




subtest 'XML::Smart::Parser data() options tests' => sub {

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  
  $XML->{'hosts'}{'server'}('type','eq','conectiva'){'address'}[1] = '' ;
  
  my $data = $XML->data(
      noident => 1 ,
      nospace => 1 ,
      lowtag => 1 ,
      upertag => 1 ,
      uperarg => 1 ,
      noheader => 1 ,
      ) ;
  
  $data =~ s/\s//gs ;
  
  my $dataok = q`<HOSTS><SERVEROS="linux"TYPE="redhat"VERSION="8.0"><ADDRESS>192.168.0.1</ADDRESS><ADDRESS>192.168.0.2</ADDRESS></SERVER><SERVEROS="linux"TYPE="suse"VERSION="7.0"><ADDRESS>192.168.1.10</ADDRESS><ADDRESS>192.168.1.20</ADDRESS></SERVER><SERVERADDRESS="192.168.2.100"OS="linux"TYPE="conectiva"VERSION="9.0"/><SERVERADDRESS="192.168.3.30"OS="bsd"TYPE="freebsd"VERSION="9.0"/></HOSTS>`;
  cmp_ok( $data, 'eq', $dataok ) ;
  
  done_testing() ;

} ;
#########################





subtest 'XML::Smart::Parser Data populate test' => sub {

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
  
  $XML->{data} = 'aaa' ;
  $XML->{var } = 10    ;
  
  $XML->{addr} = [qw(1 2 3)] ;
  
  my $data = $XML->data(length => 1 , nometagen => 1 ) ;
  $data =~ s/\s//gs ;
  
  my $dataok = q`<?xmlversion="1.0"encoding="iso-8859-1"length="88"?><rootdata="aaa"var="10"><addr>1</addr><addr>2</addr><addr>3</addr></root>`;

  cmp_ok( $data, 'eq', $dataok ) ;

  done_testing() ;

} ;
#########################




subtest 'XML::Smart::Parser Data Populate Array test' => sub {

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
  
  $XML->{hosts}{server} = {
      os => 'lx'  ,
      type => 'red'  ,
      ver => 123 ,
  } ;
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  my $dataok = q`<hosts><serveros="lx"type="red"ver="123"/></hosts>`;
  
  cmp_ok( $data, 'eq', $dataok ) ;
                       
  $XML->{hosts}[1]{server}[0] = {
      os => 'LX'  ,
      type => 'red'  ,
      ver => 123 ,
  } ;

  $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  $dataok = q`<root><hosts><serveros="lx"type="red"ver="123"/></hosts><hosts><serveros="LX"type="red"ver="123"/></hosts></root>`;
  
  cmp_ok( $data, 'eq', $dataok ) ;

  done_testing() ;

} ;

#########################





subtest 'XML::Smart::Parser Array assign test' => sub {

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
                          
  $XML->{hosts}[1]{server}[0] = {
      os => 'LX'  ,
      type => 'red'  ,
      ver => 123 ,
  } ;
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  my $dataok = q`<hosts><serveros="LX"type="red"ver="123"/></hosts>`;
  
  cmp_ok( $data, 'eq', $dataok ) ;

  done_testing() ;

} ;
#########################







subtest 'XML::Smart::Parser Hash assign test' => sub {

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
                          
  my $srv = {
      os => 'lx'  ,
      type => 'red'  ,
      ver => 123 ,
  } ;

  push( @{$XML->{hosts}} , {XXXXXX => 1}) ;
  
  unshift( @{$XML->{hosts}}  , $srv) ;
  
  push( @{$XML->{hosts}{more}}  , {YYYY => 1}) ;
  
  my $data = $XML->data(noheader => 1) ;
  $data =~ s/\s//gs ;
  
  my $dataok = q`<root><hostsos="lx"type="red"ver="123"><moreYYYY="1"/></hosts><hostsXXXXXX="1"/></root>` ;
  
  cmp_ok( $data, 'eq', $dataok ) ;

  done_testing() ;

} ;
#########################





subtest 'XML::Smart::Parser Extended Hash assign test' => sub {

  my $XML = XML::Smart->new('' , 'XML::Smart::Parser') ;
  
  $XML->{hosts}{server} = [
      { os => 'lx' , type => 'a' , ver => '1' ,} ,
      { os => 'lx ', type => 'b' , ver => '2' ,} ,
      ];
  
  cmp_ok( $XML->{hosts}{server}{type}, 'eq', 'a' ) ;
  
  my $srv0 = shift( @{$XML->{hosts}{server}} ) ;
  cmp_ok( $$srv0{type}, 'eq', 'a' ) ;
  
  cmp_ok( $XML->{hosts}{server}{type}, 'eq', 'b' ) ;
  cmp_ok( $XML->{hosts}{server}{type}[0], 'eq', 'b' ) ;
  cmp_ok( $XML->{hosts}{server}[0]{type}[0], 'eq', 'b' ) ;
  cmp_ok( $XML->{hosts}[0]{server}[0]{type}[0], 'eq', 'b' ) ;
  
  my $srv1 = pop( @{$XML->{hosts}{server}} ) ;
  cmp_ok( $$srv1{type}, 'eq', 'b' ) ;
  
  my $data = $XML->data(noheader => 1 , nospace=>1) ;
  cmp_ok($data, 'eq', '<hosts></hosts>' ) ;

  done_testing() ;

} ;
#########################






subtest 'XML::Smart::Parser node extraction test' => sub {

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser' ) ;

  my @types = $XML->{hosts}{server}('[@]','type') ;
  cmp_ok("@types", 'eq', 'redhat suse conectiva freebsd' ) ;

  @types = $XML->{hosts}{server}{type}('<@') ;
  cmp_ok("@types", 'eq', 'redhat suse conectiva freebsd' ) ;

  done_testing() ;
  
} ;
#########################




subtest 'XML::Smart::Parser Extended node extraction test' => sub {

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;

  my @srvs = $XML->{hosts}{server}('os','eq','linux') ;
  
  my @types ;
  foreach my $srvs_i ( @srvs ) { push(@types , $srvs_i->{type}) ;}
  cmp_ok("@types", 'eq', 'redhat suse conectiva' ) ;

  @srvs = $XML->{hosts}{server}(['os','eq','linux'],['os','eq','bsd']) ;
  @types = () ;
  foreach my $srvs_i ( @srvs ) { push(@types , $srvs_i->{type}) ;}
  cmp_ok("@types", 'eq', 'redhat suse conectiva freebsd' ) ;

  done_testing() ;
  
} ;
#########################





subtest 'XML::Smart::Parser Data encode test' => sub {

  my $wild = pack("C", 127 ) ;

  my $data = qq`<?xml version="1.0" encoding="iso-8859-1"?><code>$wild</code>`;
  
  my $XML = XML::Smart->new($data , 'XML::Smart::Parser') ;

  cmp_ok( $XML->{code}, 'eq', $wild ) ;
  $data = $XML->data() ;
  
  $XML = XML::Smart->new($data , 'XML::Smart::Parser') ;

  cmp_ok( $XML->{code}, 'eq', $wild ) ;
  
  my $data2 = $XML->data() ;
  cmp_ok( $data, 'eq', $data2 ) ;

  done_testing() ;

} ;
#########################






subtest 'XML::Smart::Parser cut_root test' => sub {

  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  
  my $addr1 = $XML->{hosts}{server}{address} ;
  
  my $XML2 = $XML->cut_root ;
  my $addr2 = $XML2->{server}{address} ;

  cmp_ok( $addr1, 'eq', $addr2 ) ;

  done_testing() ;

} ;
#########################





subtest 'XML::Smart::Parser Funny Char test' => sub {

  my $data = q`
  <root>
    <foo bar="x"> My Company &amp; Name + x &gt;&gt; plus &quot; + &apos;...</foo>
  </root>
  `;

  my $XML = XML::Smart->new($data , 'XML::Smart::Parser') ;
  
  cmp_ok( $XML->{root}{foo}, 'eq', q` My Company & Name + x >> plus " + '...` ) ;
  
  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', q`<root><foo bar="x"> My Company &amp; Name + x &gt;&gt; plus " + '...</foo></root>` ) ;

  done_testing() ;

} ;
#########################




subtest 'XML::Smart::Parser nodes test' => sub {

  my $XML = XML::Smart->new(q`
  <root>
    <foo arg1="x" arg2="y">
      <bar arg='z'>cont</bar>
    </foo>
  </root>
  ` , 'XML::Smart::Parser') ;
  
  my @nodes = $XML->{root}{foo}->nodes ;
  
  cmp_ok( $nodes[0]->{arg}, 'eq', 'z') ;

  
  @nodes = $XML->{root}{foo}->nodes_keys ;
  cmp_ok( "@nodes", 'eq', 'bar' ) ;

  isnt( $XML->{root}{foo}{bar}->is_node, undef ) ;
  
  my @keys = $XML->{root}{foo}('@keys') ;
  cmp_ok("@keys", 'eq', 'arg1 arg2 bar' ) ;  

  done_testing() ;

} ;
#########################




subtest 'XML::Smart::Parser CDATA test' => sub {

  my $data = qq`
  <root>
    <item arg1="x">
      <data><![CDATA[some CDATA code <non> <parsed> <tag> end]]></data>
    </item>
  </root>
  `;

  my $XML = XML::Smart->new($data , 'XML::Smart::Parser') ;
  
  cmp_ok( $XML->{root}{item}{data}, 'eq', q`some CDATA code <non> <parsed> <tag> end` ) ;

  done_testing() ;
  
} ;
#########################




subtest 'Default Parser Hash assign through array Test' => sub {

  my $XML = XML::Smart->new() ;
  
  $XML->{menu}{option}[0] = {
      name => "Help" ,
      level => {from => 1 , to => 99} ,
  } ;
  
  $XML->{menu}{option}[0]{sub}{option}[0] = {
      name => "Busca" ,
      level => {from => 1 , to => 99} ,
  } ;
  
  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  
  cmp_ok( $data, 'eq', q`<menu><option name="Help"><level from="1" to="99"/><sub><option name="Busca"><level from="1" to="99"/></option></sub></option></menu>`) ;

  done_testing() ;

} ;
#########################





subtest 'Default Parser integer data tests' => sub {
  
  my $XML = XML::Smart->new() ;
  
  $XML->{menu}{arg1} = 123 ;
  $XML->{menu}{arg2} = 456 ;
  
  $XML->{menu}{arg2}{subarg} = 999 ;
  
  cmp_ok($XML->{menu}{arg1}, '==', 123 ) ;
  cmp_ok($XML->{menu}{arg2}, '==', 456 ) ;
  cmp_ok($XML->{menu}{arg2}{subarg}, '==', 999 ) ;

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok($data, 'eq',  q`<menu arg1="123"><arg2 subarg="999">456</arg2></menu>` ) ;

  done_testing() ;

} ;
#########################





subtest 'Default Parser Args get Test' => sub {
  
  my $XML = XML::Smart->new() ;
  
  $XML->{menu}{arg1} = [1,2,3] ;
  $XML->{menu}{arg2} = 4 ;
  
  my @arg1 = $XML->{menu}{arg1}('@') ;
  cmp_ok( $#arg1, '==', 2 ) ;
  
  my @arg2 = $XML->{menu}{arg2}('@') ;
  cmp_ok( $#arg2, '==', 0 ) ;
  
  my @arg3 = $XML->{menu}{arg3}('@') ;  
  cmp_ok( $#arg3, '==', -1 ) ;  

  done_testing() ;

} ;
#########################





subtest 'Default Parser set_node and set_order Tests' => sub {

  
  my $XML = XML::Smart->new() ;
  
  $XML->{menu}{arg2} = 456 ;
  $XML->{menu}{arg1} = 123 ;
  
  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', q`<menu arg2="456" arg1="123"/>` ) ;

  $XML->{menu}{arg2}->set_node ;
  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', q`<menu arg1="123"><arg2>456</arg2></menu>` ) ;

  $XML->{menu}{arg2}->set_node(0) ;
  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', q`<menu arg2="456" arg1="123"/>` ) ;
  
  $XML->{menu}->set_order('arg1' , 'arg2') ;
  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', q`<menu arg1="123" arg2="456"/>` ) ;
  
  delete $XML->{menu}{arg2}[0] ;

  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', q`<menu arg1="123"/>` ) ;

  done_testing() ;

} ;
#########################




subtest 'Default Parser XML Structure verification' => sub {


  my $XML = XML::Smart->new() ;
  $XML->{root}{foo} = "bla bla bla";

  $XML->{root}{foo}->set_node(1) ;

  cmp_ok( $XML->tree->{root}{'/nodes'}{foo}, 'eq', '1' ) ;
  cmp_ok( $XML->tree->{root}{foo}{CONTENT}, 'eq', "bla bla bla" ) ;  
  

  cmp_ok( ref $XML->tree->{ root }{ foo }, 'eq', 'HASH' ) ;

  $XML->{root}{foo}->set_node(0) ;

  cmp_ok( ref $XML->tree->{ root }{ foo }, 'eq', '' ) ;
  is( $XML->tree->{root}{'/nodes'}{foo}, undef ) ;
  
  $XML->{root}{foo}->set_cdata(1) ;
  
  cmp_ok( $XML->tree->{root}{'/nodes'}{foo}, 'eq', 'cdata,1,' )   ;
  cmp_ok( $XML->tree->{root}{foo}{CONTENT} , 'eq', "bla bla bla" ) ;  
  
  $XML->{root}{foo}->set_node(1) ;
  
  cmp_ok( $XML->tree->{root}{'/nodes'}{foo}, 'eq', 'cdata,1,1' ) ;
  cmp_ok( $XML->tree->{root}{foo}{CONTENT},  'eq', "bla bla bla" ) ;  
  
  $XML->{root}{foo}->set_binary(1) ;
  
  cmp_ok( $XML->tree->{root}{'/nodes'}{foo}, 'eq', 'binary,1,1' ) ;
  cmp_ok( $XML->tree->{root}{foo}{CONTENT}, 'eq', "bla bla bla" ) ;  
  
  $XML->{root}{foo}->set_binary(0) ;

  cmp_ok( $XML->tree->{root}{'/nodes'}{foo}, 'eq', 'binary,0,1' ) ;
  cmp_ok( $XML->tree->{root}{foo}{CONTENT}, 'eq', "bla bla bla" ) ;  
  
  $XML->{root}{foo}->set_auto_node ;
  
  cmp_ok( $XML->tree->{root}{'/nodes'}{foo}, 'eq', 1 ) ;
  cmp_ok( $XML->tree->{root}{foo}{CONTENT}, 'eq', "bla bla bla" ) ;  
  
  $XML->{root}{foo}->set_cdata(0) ;
  
  cmp_ok( $XML->tree->{root}{'/nodes'}{foo}, 'eq', 'cdata,0,1'   ) ;
  cmp_ok( $XML->tree->{root}{foo}{CONTENT}, 'eq', "bla bla bla" ) ;
  
  $XML->{root}{foo}->set_binary(0) ;
  
  cmp_ok( $XML->tree->{root}{'/nodes'}{foo}, 'eq', 'binary,0,1' ) ;
  cmp_ok( $XML->tree->{root}{foo}{CONTENT}, 'eq', "bla bla bla" ) ;

  cmp_ok( ref( $XML->tree->{root}{foo} ), 'eq', 'HASH' ) ; 
  $XML->{root}{foo}->set_auto ;

  cmp_ok( ref( $XML->tree->{root}{foo} ), 'eq', '' ) ; 
  isnt( exists $XML->tree->{root}{'/nodes'}{foo}, undef ) ;

  done_testing() ;

} ;
#########################






subtest 'Default Parser CDATA and Bin data tests' => sub {

  my $XML = new XML::Smart ;
  $XML->{root}{foo} = "bla bla bla <tag> bla bla";

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', '<root><foo><![CDATA[bla bla bla <tag> bla bla]]></foo></root>' ) ;

  $XML->{root}{foo}->set_cdata(0) ;
  
  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', '<root><foo>bla bla bla &lt;tag&gt; bla bla</foo></root>' ) ;
  
  $XML->{root}{foo}->set_binary(1) ;
  
  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok ($data, 'eq', '<root><foo dt:dt="binary.base64">YmxhIGJsYSBibGEgPHRhZz4gYmxhIGJsYQ==</foo></root>' ) ;

  done_testing() ;

} ;
#########################





subtest 'Default Parser Funny Chars, Hex and Bin data Test' => sub {


  my $XML = new XML::Smart ;
  $XML->{root}{foo} = "<h1>test \x03</h1>";

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', '<root><foo dt:dt="binary.base64">PGgxPnRlc3QgAzwvaDE+</foo></root>' ) ;

  $XML->{root}{foo}->set_binary(0) ;
  
  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', "<root><foo>&lt;h1&gt;test \x03\&lt;/h1&gt;</foo></root>") ;
  
  $XML->{root}{foo}->set_binary(1) ;
  
  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', '<root><foo dt:dt="binary.base64">PGgxPnRlc3QgAzwvaDE+</foo></root>' ) ;

  done_testing() ;

} ;
#########################





subtest 'Default Parser CDATA test' => sub {


  my $XML = new XML::Smart ;
  $XML->{root}{foo} = "simple";

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', '<root foo="simple"/>' ) ;
  
  $XML->{root}{foo}->set_cdata(1) ;

  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', '<root><foo><![CDATA[simple]]></foo></root>' ) ;
  
  done_testing() ;

} ;
#########################





subtest 'Default Parser CDATA and funny chars' => sub {

  my $XML = new XML::Smart ;
  $XML->{root}{foo} = "<words>foo bar baz</words>";

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', '<root><foo><![CDATA[<words>foo bar baz</words>]]></foo></root>' ) ;
  
  $XML->{root}{foo}->set_cdata(0) ;

  $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', '<root><foo>&lt;words&gt;foo bar baz&lt;/words&gt;</foo></root>' ) ;  

  done_testing() ;

} ;
#########################






subtest 'Default Parser' => sub {
  
  my $XML = XML::Smart->new(q`<?xml version="1.0"?>
  <root>
    <entry><b>here's</b> a <i>test</i></entry>
  </root>
  `, 'XML::Parser');

  my $data = $XML->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', "<root><entry><b>here's</b> a <i>test</i></entry></root>") ;  

  done_testing() ;

} ;
#########################





subtest 'XML::Smart::Parser Path and XPath Tests' => sub {


  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  $XML = $XML->{hosts} ;
  
  my $addr = $XML->{'server'}('type','eq','suse'){'address'} ;
  
  cmp_ok( $addr->path, 'eq', '/hosts/server[1]/address' ) ;
  
  my $addr0 = $XML->{'server'}('type','eq','suse'){'address'}[0] ;
  
  cmp_ok( $addr0->path , 'eq',  '/hosts/server[1]/address[0]') ;
  cmp_ok( $addr0->path_as_xpath , 'eq',  '/hosts/server[2]/address') ;
  
  my $addr1 = $XML->{'server'}('type','eq','suse'){'address'}[1] ;
  
  my $type = $XML->{'server'}('version','>=','9'){'type'} ;

  cmp_ok($type->path , 'eq',  '/hosts/server[2]/type') ;
  
  $addr = $XML->{'server'}('version','>=','9'){'address'} ;

  cmp_ok($addr->path , 'eq',  '/hosts/server[2]/address') ;
  
  $addr0 = $XML->{'server'}('version','>=','9'){'address'}[0] ;

  cmp_ok($addr0->path , 'eq',  '/hosts/server[2]/address[0]') ;
  cmp_ok($addr0->path_as_xpath , 'eq',  '/hosts/server[3]/@address') ;
  
  $type = $XML->{'server'}('version','>=','9'){'type'} ;
  
  cmp_ok($type->path , 'eq',  '/hosts/server[2]/type') ;
  cmp_ok($type->path_as_xpath , 'eq',  '/hosts/server[3]/@type') ;

  done_testing() ;
    
} ;
#########################



subtest 'XML::Smart::Parser cut_root array Tests' => sub{

  my $XML = new XML::Smart(q`
  <root>
    <output name='123'>
      <frames format='a'/>
      <frames format='b'/>
    </output>
    <output>
      <name>456</name>
      <frames format='c'/>
      <frames format='d'/>
    </output>
  </root>
  `,'smart');
  
  $XML = $XML->cut_root ;
  
  my @frames_123 = @{ $XML->{'output'}('name','eq',123){'frames'} } ;
  my @formats_123 = map { $_->{'format'} } @frames_123 ;
  
  my @frames_456 = @{ $XML->{'output'}('name','eq',456){'frames'} } ;
  my @formats_456 = map { $_->{format} } @frames_456 ;

  cmp_ok( join(";", @formats_123) , 'eq',  'a;b' ) ;
  cmp_ok( join(";", @formats_456) , 'eq',  'c;d' ) ;

  done_testing() ;

} ;
#########################




subtest 'XML::Smart::HTMLParser Tests' => sub {
  
  my $html = q`
  <html>
  <p id="$s->{supply}->shift">foo</p>
   </html>
  `;
  
  my @tag ;

  my $p = XML::Smart::HTMLParser->new(
      Start => sub { shift; push(@tag , @_) ;},
      Char => sub {},
      End => sub {},
      );

  $p->parse($html) ;
  
  cmp_ok($tag[-1] , 'eq',  '$s->{supply}->shift') ;  

  done_testing() ;

} ;
#########################





subtest 'XML::Smart::Parser Array pop Test' => sub {
  
  my $xml = new XML::Smart(q`<?xml version="1.0" encoding="UTF-8"?>
<doc type="test">
  <data>test 1</data>
  <data>test 2</data>
  <data>test 3</data>
  <file>file 1</file>
</doc>
  `);

  $xml->{doc}{port}[0] = 0;
  $xml->{doc}{port}[1] = 1;
  $xml->{doc}{port}[2] = 2;
  $xml->{doc}{port}[3] = 3;
  
  my $data = $xml->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok($data, 'eq', q`<doc type="test"><data>test 1</data><data>test 2</data><data>test 3</data><file>file 1</file><port>0</port><port>1</port><port>2</port><port>3</port></doc>`) ;
  
  pop @{$xml->{doc}{'/order'}} ;

  $data = $xml->data(nospace => 1 , noheader => 1 ) ;
  cmp_ok( $data, 'eq', q`<doc type="test"><data>test 1</data><data>test 2</data><data>test 3</data><file>file 1</file><port>0</port><port>1</port><port>2</port><port>3</port></doc>`) ;

  done_testing() ;

} ;
#########################






subtest 'XML::XPath Tests' => sub {

  eval(q`use XML::XPath`) ;

  if( $@ ) {
      plan skip_all => 'XML::XPath Unavailable' ;
  }
  
  my $XML = XML::Smart->new($DATA , 'XML::Smart::Parser') ;
  
  my $xp1 = $XML->XPath ;
  my $xp2 = $XML->XPath ;
  cmp_ok( $xp1, 'eq', $xp2 ) ;
  
  $xp1 = $XML->XPath ;
  $XML->{hosts}{tmp} = 123 ;
  $xp2 = $XML->XPath ;
  
  ## Test cache of the XPath object:
  cmp_ok( $xp1, '!=', $xp2 ) ;
  
  delete $XML->{hosts}{tmp} ;
  
  my $data = $XML->XPath->findnodes_as_string('/') ;
  
  cmp_ok( $data, 'eq', q`<hosts><server os="linux" type="redhat" version="8.0"><address>192.168.0.1</address><address>192.168.0.2</address></server><server os="linux" type="suse" version="7.0"><address>192.168.1.10</address><address>192.168.1.20</address></server><server address="192.168.2.100" os="linux" type="conectiva" version="9.0" /><server address="192.168.3.30" os="bsd" type="freebsd" version="9.0" /></hosts>`) ;

  done_testing() ;

} ;

#########################



subtest 'XML::Smart::DTD Tests' => sub {

  use XML::Smart::DTD ;

  my $dtd = XML::Smart::DTD->new(q`
<!DOCTYPE curso [
<!ELEMENT curso (objetivo|descricao , curriculo? , aluno+ , professor+)>
<!ATTLIST curso
          centro  CDATA #REQUIRED
          nome    (a|b|c|"a simple | test",d) #REQUIRED "a"
          age    CDATA
>
<!ELEMENT objetivo (#PCDATA)>
<!ELEMENT curriculo (disciplina+)>
<!ELEMENT disciplina (requisito , professor+)>
<!ATTLIST disciplina
          codigo     CDATA #REQUIRED
          ementa     CDATA #REQUIRED
>
<!ELEMENT descricao (#PCDATA)>
<!ELEMENT requisito (#PCDATA)>
<!ELEMENT professor (#PCDATA)>
<!ELEMENT br EMPTY>
]>
  `) ;
  

  isnt( $dtd->elem_exists('curso') , undef ) ;
  isnt( $dtd->elem_exists('objetivo') , undef ) ;
  isnt( $dtd->elem_exists('curriculo') , undef ) ;
  isnt( $dtd->elem_exists('disciplina') , undef ) ;
  isnt( $dtd->elem_exists('descricao') , undef ) ;
  isnt( $dtd->elem_exists('requisito') , undef ) ;  
  isnt( $dtd->elem_exists('professor') , undef ) ;  
  isnt( $dtd->elem_exists('br') , undef ) ;  
  
  isnt( $dtd->is_elem_req('requisito') , undef ) ;
  isnt( $dtd->is_elem_uniq('requisito') , undef ) ;
  
  isnt( $dtd->is_elem_opt('curriculo') , undef ) ;
  isnt( !$dtd->is_elem_req('curriculo') , undef ) ;
  
  isnt( $dtd->is_elem_multi('professor') , undef ) ;
  
  isnt( $dtd->is_elem_pcdata('professor') , undef ) ;
  isnt( $dtd->is_elem_empty('br') , undef ) ;

  isnt( $dtd->attr_exists('curso','centro') , undef ) ;
  isnt( $dtd->attr_exists('curso','nome') , undef ) ;
  
  isnt( $dtd->attr_exists('curso','centro','nome') , undef ) ;
  
  is( $dtd->attr_exists('curso','centro','nomes'), undef ) ;
  
  my @attrs = $dtd->get_attrs('curso', undef ) ;
  cmp_ok( join(" ",@attrs), 'eq', 'centro nome age' ) ;
  
  @attrs = $dtd->get_attrs_req('curso') ;
  cmp_ok( join(" ",@attrs) , 'eq', 'centro nome') ;

  done_testing() ;
  
} ;
#########################






subtest 'Default Parser cds Tests' => sub {

  my $xml = XML::Smart->new()->{cds} ;
  
  $xml->{album}[0] = {
      title => 'foo' ,
      artist => 'the foos' ,
      tracks => 8 ,
  } ;
  
  $xml->{album}[1] = {
      title => 'bar' ,
      artist => 'the barss' ,
      tracks => [qw(6 7)] ,
      time => [qw(60 70)] ,
      type => 'b' ,
  } ;
  
  $xml->{album}[2] = {
      title => 'baz' ,
      artist => undef ,
      tracks => 10 ,
      type => '' ,
      br => 123 ,
  } ;
  
  $xml->{creator} = 'Joe' ;
  $xml->{date} = '2000-01-01' ;
  $xml->{type} = 'a' ;
  
  $xml->{album}[0]{title}->set_node(1);
  
  cmp_ok( $xml->data( noheader=>1 , nospace=>1), 'eq', q`<cds creator="Joe" date="2000-01-01" type="a"><album artist="the foos" tracks="8"><title>foo</title></album><album artist="the barss" title="bar" type="b"><time>60</time><time>70</time><tracks>6</tracks><tracks>7</tracks></album><album artist="" br="123" title="baz" tracks="10" type=""/></cds>`) ;
  
  $xml->apply_dtd(q`
<!DOCTYPE cds [
<!ELEMENT cds (album+)>
<!ATTLIST cds
          creator  CDATA
          date     CDATA #REQUIRED
          type     (a|b|c) #REQUIRED "a"
>
<!ELEMENT album (artist , tracks+ , time? , auto , br?)>
<!ATTLIST album
          title     CDATA #REQUIRED
          type     (a|b|c) #REQUIRED "a"
>
<!ELEMENT artist (#PCDATA)>
<!ELEMENT tracks (#PCDATA)>
<!ELEMENT auto (#PCDATA)>
<!ELEMENT br EMPTY>
]>
  `);
  
  cmp_ok( $xml->data(noheader=>1 , nospace=>1), 'eq', q`<!DOCTYPE cds [
<!ELEMENT cds (album+)>
<!ELEMENT album (artist , tracks+ , time? , auto , br?)>
<!ELEMENT artist (#PCDATA)>
<!ELEMENT tracks (#PCDATA)>
<!ELEMENT auto (#PCDATA)>
<!ELEMENT br EMPTY>
<!ATTLIST cds
          creator  CDATA
          date     CDATA #REQUIRED
          type     (a|b|c) #REQUIRED "a"
>
<!ATTLIST album
          title     CDATA #REQUIRED
          type     (a|b|c) #REQUIRED "a"
>
]><cds creator="Joe" date="2000-01-01" type="a"><album title="foo" type="a"><artist>the foos</artist><tracks>8</tracks><auto></auto></album><album title="bar" type="b"><artist>the barss</artist><tracks>6</tracks><tracks>7</tracks><time>60</time><auto></auto></album><album title="baz" type="a"><artist></artist><tracks>10</tracks><auto></auto><br/></album></cds>` );


  done_testing() ;

} ;
#########################







subtest 'Default Parser apply_dtd Tests' => sub {
  
  my $xml = XML::Smart->new;
  $xml->{customer}{phone} = "555-1234";
  $xml->{customer}{phone}{type} = "home";
  
  $xml->apply_dtd(q`
  <?xml version="1.0" ?>
  <!DOCTYPE customer [
  <!ELEMENT customer (type?,phone+)>
  <!ELEMENT phone (#PCDATA)>
  <!ATTLIST phone type CDATA #REQUIRED>
  <!ELEMENT type (#PCDATA)>
  ]>
  `);
  
  cmp_ok( $xml->data(noheader=>1 , nospace=>1 , nodtd=>1), 'eq', q`<customer><phone type="home">555-1234</phone></customer>` );

  done_testing() ;

} ;
#########################








subtest 'URL Tests' => sub {


    eval(q`use LWP::UserAgent`) ;

    if ( $@ ) {
	plan skip_all => 'URL Tests require LWP::UserAgent' ;
	done_testing() ;
    }

    if( !$ENV{ URL_TESTS } ) { 
	plan skip_all => 'Skipping URL test, Enable by setting ENV variable URL_TESTS' ;
	done_testing() ;
    }

    my $url = 'http://www.perlmonks.org/index.pl?node_id=16046' ;
	    
    diag( "\nGetting URL... " ) ;
    
    my $XML = XML::Smart->new($url , 'XML::Smart::Parser') ;
    
    cmp_ok( $XML->{XPINFO}{INFO}{sitename}, 'eq', 'PerlMonks' ) ;
    
    done_testing() ;
    
} ;

#########################

done_testing() ;

exit() ;



