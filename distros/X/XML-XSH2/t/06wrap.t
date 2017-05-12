# -*- cperl -*-
use Test;

use IO::File;

BEGIN {
  autoflush STDOUT 1;
  autoflush STDERR 1;

  @xsh_test=split /\n\n/, <<'EOF';
quiet;
def x_assert $cond
{ perl { xsh("unless ($cond) throw concat('Assertion failed ',\$cond)") } }

def xml_assert $node $xml
{ perl { my $real=serialize($node); die "Assertion failed: expected\n".$xml."\ngot\n".$real."\n " unless ($real eq $xml) } }


x_assert '/scratch';

try {
  call x_assert '/xyz';
  throw "x_assert failed";
} catch local $err {
  unless { $err =~ /^Assertion failed \/xyz/ } throw $err;
};

xml_assert * '<scratch/>';

try {
  call xml_assert * 'foo';
  throw "xml_assert failed";
} catch local $err {
  unless { $err =~ /^Assertion failed/ } throw $err;
};


call x_assert 'count(//node()) = 1 and name(*)="scratch"';

wrap 'foo' *;

call x_assert 'count(//node()) = 2 and /foo/scratch';

insert attribute 'bar=baz' into /foo/scratch;
insert text 'some text' into //scratch;

call x_assert '/foo/scratch[text()="some text" and @bar="baz"]';

wrap --namespace 'http://foo/bar' 'a:A' //@*;

call x_assert '/foo/scratch[text()="some text" and node()[name()="a:A" and namespace-uri()="http://foo/bar"]]';

wrap 'text aaa="bbb"' //text();

call x_assert '/foo/scratch[not(@bar) and text[@aaa="bbb"]/text()="some text" and *[name()="a:A" and namespace-uri()="http://foo/bar" and @bar="baz"]]';

$w := wrap '<elem ccc=ddd>' /foo//*;

ls /;

ls $w;

call x_assert <<'XPATH'
/foo[count(node())=1]
  /elem[count(node())=1 and @ccc="ddd"]
  /scratch[count(node())=2 and 
     count(elem[@ccc="ddd" and count(node())=1 and text[@aaa="bbb" and text()="some text"]])=1 and
     count(elem[@ccc="ddd" and count(node())=1 and *[name()="a:A" and namespace-uri()="http://foo/bar" and @bar="baz"]])=1	
   ]
XPATH

call x_assert 'count($w)=3';

call x_assert '$w[name()="elem"]';

call x_assert 'not($w[name()!="elem"])';

$scratch := create '<foo/>';

call x_assert 'count(//node())=1';

insert pi 'foo' before /foo;

insert comment 'foo' after /foo;

call x_assert 'count(//node())=3';

perl { $list = xml_list('//node()') };

ls $list;

count "${list}"

call x_assert '"${list}"="<?foo ?><foo/><!--foo-->"';

call x_assert '"${list}"=xsh:serialize(//node())';

wrap 'bar' /foo;

call x_assert 'xsh:serialize(/node())="<?foo ?><bar><foo/></bar><!--foo-->"';

delete /bar;

call x_assert 'xsh:serialize(/node())="<?foo ?><!--foo-->"';

wrap 'foo' /processing-instruction();

count (xsh:serialize(/node())) | cat 2>&1;

call x_assert 'xsh:serialize(/node())="<foo><?foo ?></foo><!--foo-->"';

move /foo/processing-instruction() replace /foo;

call x_assert 'xsh:serialize(/node())="<?foo ?><!--foo-->"';

wrap 'foo' /comment();

call x_assert 'xsh:serialize(/node())="<?foo ?><foo><!--foo--></foo>"';

$scratch := create '<a><b/>foo<c/><b/><d/><c/><b/><c/></a>';

wrap-span 's' //b //c;

call x_assert 'xsh:serialize(/a)="<a><s><b/>foo<c/></s><s><b/><d/><c/></s><s><b/><c/></s></a>"';

$scratch := create '<!--start--><mid/><!--end-->';
wrap-span 's' /comment()[1] /mid;
call x_assert 'xsh:serialize(/node())="<s><!--start--><mid/></s><!--end-->"';

$scratch := create '<!--start--><mid/><!--end-->';
wrap-span 's' /mid /comment()[2];
call x_assert 'xsh:serialize(/node())="<!--start--><s><mid/><!--end--></s>"';

$scratch := create '<!--start--><mid/><!--end-->';
wrap-span 's' /comment()[1] /comment()[2];
call x_assert 'xsh:serialize(/node())="<s><!--start--><mid/><!--end--></s>"';

$scratch := create '<a><c/><c/><c/></a>';
$w=/a;
$w +:= wrap 'w' //c;
call x_assert 'count($w)=4 and count($w[name()="w"])=3 and count($w[name()="a"])=1';

$scratch := create '<a><c/><c/><c/></a>';
$w=/a;
$w +:= wrap-span 'w' //c //c;
call x_assert 'count($w)=4 and count($w[name()="w"])=3 and count($w[name()="a"])=1';

$scratch := create '<a><c/><c/><c/></a>';
$w=/a;
$w := wrap 'w' //c;
call x_assert 'count($w)=3 and count($w[name()="w"])=3';

$scratch := create '<a><c/><c/><c/></a>';
$w=/a;
$w := wrap-span 'w' //c //c;
call x_assert 'count($w)=3 and count($w[name()="w"])=3';

$scratch := create '<a><c/></a>';
wrap --namespace 'nam' 'u:v' //c;
call x_assert '/a/*[name()="u:v" and namespace-uri()="nam" and c]';

$scratch := create '<a><b/><c/></a>';
wrap-span --namespace 'nam' 'u:v' //b //c;
call x_assert '/a/*[name()="u:v" and namespace-uri()="nam" and b and c]';

$scratch := create '<a><b/><b/> <b/><c/>  <b/><!-- comment --><b/>  </a>';
wrap --while self::b "x" //b;
call xml_assert /a '<a><x><b/><b/></x> <x><b/></x><c/>  <x><b/></x><!-- comment --><x><b/></x>  </a>';

$scratch := create '<a><b/><b/> <b/><c/>  <b/><!-- comment --><b/>  </a>';
wrap --skip-whitespace --while self::b "x" //b;
call xml_assert /a '<a><x><b/><b/> <b/></x><c/>  <x><b/></x><!-- comment --><x><b/></x>  </a>';

$scratch := create '<a><b/><b/> <b/><c/>  <b/><!-- comment --><b/>  </a>';
wrap --skip-comments --skip-whitespace --while self::b "x" //b;
call xml_assert /a '<a><x><b/><b/> <b/></x><c/>  <x><b/><!-- comment --><b/></x>  </a>';

$scratch := create '<a><b/><?foo?><?bar?><b/><b/><c/><b/>  <b/><!-- comment --><b/>  </a>';
wrap --skip-pi --while self::b "x" //b;
call xml_assert /a '<a><x><b/><?foo?><?bar?><b/><b/></x><c/><x><b/></x>  <x><b/></x><!-- comment --><x><b/></x>  </a>';

$scratch := create '<a><b/>foo<b/> <b/><c/>  <b/><!-- comment --><b/>  </a>';
wrap --until self::*[not(self::b)] "x" //b;
call xml_assert /a '<a><x><b/>foo<b/> <b/></x><c/>  <x><b/><!-- comment --><b/>  </x></a>';


EOF

  plan tests => 4+@xsh_test;
}
END { ok(0) unless $loaded; }
use XML::XSH2 qw/&xsh &xsh_init &set_quiet &xsh_set_output/;
$loaded=1;
ok(1);

my $verbose=$ENV{HARNESS_VERBOSE};

($::RD_ERRORS,$::RD_WARN,$::RD_HINT)=(1,1,1);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.

#xsh_set_output(\*STDERR);
set_quiet(0);
xsh_init();

print STDERR "\n" if $verbose;
ok(1);

print STDERR "\n" if $verbose;
ok ( XML::XSH2::Functions::create_doc("scratch","scratch") );

print STDERR "\n" if $verbose;
ok ( XML::XSH2::Functions::set_local_xpath('/') );

foreach (@xsh_test) {
  print STDERR "\n\n[[ $_ ]]\n" if $verbose;
  eval { xsh($_) };
  print STDERR $@ if $@;
  ok( !$@ );
}
