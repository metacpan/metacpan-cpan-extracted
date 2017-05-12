# -*- cperl -*-
use Test;

use IO::File;

BEGIN {
  autoflush STDOUT 1;
  autoflush STDERR 1;

  @xsh_test=split /\n\n/, <<'EOF';
quiet;
def xml_assert $node $xml
{ perl { my $real=serialize($node); die "Assertion failed: expected\n".$xml."\ngot\n".$real."\n " unless ($real eq $xml) } }
indent 1;

$t := create 'test';

insert chunk "<x n='1'>abc</x><x n='2'/><x n='3'/>" into $t/test;

insert chunk "<z u='v'>zzz</z>" into $t/test;

$expect='<test><x n="1">abc</x><x n="2"/><x n="3"/><z u="v">zzz</z></test>';

if { xml_list('$t/test') ne $expect } {
  perl { die "Resulting XML does not match what was expected:\n<RESULT>".
              xml_list('$t/test').
             "</RESULT>\nversus\n".
             "<EXPECTED>$expect</EXPECTED>\n"
       }
}

foreach (/test/x/@n|/test/x|/test/x/text()) {
  unless (self::*|self::text()) insert attribute 'after_attribute=b' after .;
  xcopy /test/z after .;
  insert text 'after_text' after .;
  insert pi 'after_pi' after .;
  insert comment 'after_comment' after .;
  unless (. = ../@*) insert chunk '<after_chunk>a</after_chunk><after_chunk>b</after_chunk>' after .;
}

$scratch := create '<a/>';
set /a/d[5];
set /a/d[3]/following-sibling::b;
for //d set . position();
call xml_assert /a '<a><d>1</d><d>2</d><d>3</d><b/><d>4</d><d>5</d></a>';

wrap --while self::d "x" //d;
call xml_assert /a '<a><x><d>1</d><d>2</d><d>3</d></x><b/><x><d>4</d><d>5</d></x></a>';

$str = xsh:serialize(a);

xmove --respective --preserve-order //d after ..;
call xml_assert /a '<a><x/><d>1</d><d>2</d><d>3</d><b/><x/><d>4</d><d>5</d></a>';

$scratch := create $str;
call xml_assert /a $str;

xmove --respective //d after ..;
call xml_assert /a '<a><x/><d>3</d><d>2</d><d>1</d><b/><x/><d>5</d><d>4</d></a>';

$scratch := create $str;
for //x xmove d after .;
call xml_assert /a '<a><x/><d>3</d><d>2</d><d>1</d><b/><x/><d>5</d><d>4</d></a>';

$scratch := create $str;
for //x xmove :p d after .;
call xml_assert /a '<a><x/><d>1</d><d>2</d><d>3</d><b/><x/><d>4</d><d>5</d></a>';

ls --depth 2 /test | cat

EOF

  plan tests => 4+@xsh_test;
}
END { ok(0) unless $loaded; }
use XML::XSH2 qw/&xsh &xsh_init &set_quiet &xsh_set_output/;
$loaded=1;
ok(1);

($::RD_ERRORS,$::RD_WARN,$::RD_HINT)=(1,1,1);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.

my $verbose=$ENV{HARNESS_VERBOSE};

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
