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
call x_assert '/scratch';
try {
  call x_assert '/xyz';
  throw "x_assert failed";
} catch local $err {
  unless { $err =~ /Assertion failed \/xyz/ } throw $err;
};

xpath-extensions;

#function xsh:new-attribute
call x_assert 'new-attribute("foo","bar")[name()="foo" and .="bar" and node-type(.)="attribute"]';

call x_assert 'new-attribute("foo","bar","baz","gaz")[name()="foo" and .="bar"]';

call x_assert 'new-attribute("foo","bar","baz","gaz")[name()="baz" and .="gaz"]';

#function xsh:new-element
call x_assert 'new-element("foo")/self::foo';

call x_assert 'new-element("foo","bar","baz","bag","dag")/self::foo[@bar="baz" and @bag="dag"]';

call x_assert 'new-element-ns("f:foo","gee","bar","baz","bag","dag")/self::*[name()="f:foo" and local-name()="foo" and namespace-uri()="gee" and @bar="baz" and @bag="dag"]';

call x_assert 'new-text("some text")/self::text()="some text"';

call x_assert 'new-comment("some text")/self::comment()="some text"';

call x_assert 'new-pi("name","value")/self::processing-instruction()[name()="name"]="value"';

call x_assert 'new-cdata("some text")/self::text()="some text"';

call x_assert 'serialize(new-cdata("some text"))="<![CDATA[some text]]>"';

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
