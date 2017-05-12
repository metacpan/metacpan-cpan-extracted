# -*- cperl -*-
use Test;

use IO::File;

BEGIN {
  autoflush STDOUT 1;
  autoflush STDERR 1;

  @xsh_test=grep {!/^\s+#/} split /\n\n/, <<'EOF';

# define assert

def p_assert $cond
{ perl { xsh("unless {$cond} throw \"Assertion failed \$cond\"") } }

def x_assert $cond
{ perl { xsh("unless ($cond) throw \"Assertion failed \$cond\"") } }

call x_assert '/scratch';

try {
  call x_assert '/xyz';
  throw "x_assert failed";
} catch local $err {
  unless { $err eq 'Assertion failed /xyz' } throw $err;
};

# rename
insert chunk '<foo bar="baz"><?hippi value?></foo>' into /scratch

call x_assert '/scratch/foo'

rename s/foo/xyz/ //*

call x_assert '/scratch/xyz'

rename { $_=uc($_) } /scratch/xyz/@bar

call x_assert '/scratch/xyz/@BAR'

rename { $_='abc' } /scratch/xyz/node()

call x_assert '/scratch/xyz/node()[name()="abc"]'

# sort
cd scratch

del node()

call x_assert 'not(/scratch/node())'

insert chunk "<c1/><a10/><b8/><d3/>" into .

%nodes = *

sort name() { $a cmp $b } %nodes;

xmove %nodes into .;

call p_assert 'xml_list(".") eq "<scratch><a10/><b8/><c1/><d3/></scratch>"'

%nodes = *

sort substring(name(),2) { $a <=> $b } %nodes;

xmove %nodes into .;

call p_assert 'xml_list(".") eq "<scratch><c1/><d3/><b8/><a10/></scratch>"'
EOF

  plan tests => 4+@xsh_test;
}
END { ok(0) unless $loaded; }
use XML::XSH qw/&xsh &xsh_init &set_quiet &xsh_set_output/;
$loaded=1;
ok(1);

($::RD_ERRORS,$::RD_WARN,$::RD_HINT)=(1,1,1);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.

xsh_set_output(\*STDERR);
set_quiet(0);
xsh_init();

print STDERR "\n";
ok(1);

print STDERR "\n";
ok ( XML::XSH::Functions::create_doc("scratch","scratch") );

print STDERR "\n";
ok ( XML::XSH::Functions::set_local_xpath(['scratch','/']) );

foreach (@xsh_test) {
  print STDERR "\n\n[[ $_ ]]\n";
  ok( xsh($_) );
}
