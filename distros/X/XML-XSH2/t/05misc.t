# -*- cperl -*-
use Test;

use IO::File;

BEGIN {
  autoflush STDOUT 1;
  autoflush STDERR 1;

  @xsh_test=grep {!/^\s+#/} split /\n\n/, <<'EOF';
quiet

# define assert
def p_assert $cond
{ perl { xsh("unless {$cond} throw concat('Assertion failed \"',\$cond,'\"')") } }

def x_assert $cond
{ perl { xsh("unless ($cond) throw concat('Assertion failed \"',\$cond,'\"')") } }

call x_assert '/scratch';

try {
  call x_assert '/xyz';
  throw "x_assert failed";
} catch local $err {
  unless { $err =~ /^Assertion failed "\/xyz" at/ } throw $err;
};

# rename
insert chunk '<foo bar="baz"><?hippi value?></foo>' into /scratch

call x_assert '/scratch/foo'

rename :i { s/foo/xyz/ } //*

call x_assert '/scratch/xyz'

rename { uc($_) } /scratch/xyz/@bar

call x_assert '/scratch/xyz/@BAR'

rename { 'abc' } /scratch/xyz/node()

call x_assert '/scratch/xyz/node()[name()="abc"]'

# sort
cd /scratch

del node()

x_assert 'not(/scratch/node())'

insert chunk "<c1>4.2</c1><a10>4.3</a10><b8>-20</b8><d3>-12</d3>" into .

$result := sort *;
p_assert ' join(",",map {$_->nodeName } @$result) eq "d3,b8,c1,a10" ';

$result := sort --numeric *;
p_assert ' join(",",map {$_->nodeName } @$result) eq "b8,d3,c1,a10" ';

$result := sort --key name() *;
p_assert ' join(",",map {$_->nodeName } @$result) eq "a10,b8,c1,d3" ';

$result := sort :k name() *;
p_assert ' join(",",map {$_->nodeName } @$result) eq "a10,b8,c1,d3" ';

$result := sort --key { current()->nodeName } *;
p_assert ' join(",",map {$_->nodeName } @$result) eq "a10,b8,c1,d3" ';

$result := sort --descending --key { current()->nodeName } *;
p_assert ' join(",",map {$_->nodeName } @$result) eq "d3,c1,b8,a10" ';

$result := sort --key string(.) --compare { $a <=> $b } *;
p_assert ' join(",",map {$_->nodeName } @$result) eq "b8,d3,c1,a10" ';

$result := sort --key name() --compare { $a cmp $b } *;
p_assert ' join(",",map {$_->nodeName } @$result) eq "a10,b8,c1,d3" ';

rm */text();

xmove &{ sort :kname() :c{ $a cmp $b } * } into .;
ls .;

call p_assert 'xml_list(".") eq "<scratch><a10/><b8/><c1/><d3/></scratch>"'

$nodes = *

perl { echo xml_list("."),"\n" }

$nodes := sort :k substring(name(),2) :c { $a <=> $b } $nodes;

xmove {@$nodes} into .;

ls {$nodes};

call p_assert 'xml_list(".") eq "<scratch><c1/><d3/><b8/><a10/></scratch>"';

set /scratch/a[5] 'yes';

# Test that number literals are parsed as such.
$index = 5;

x_assert 'count(/scratch/a[$index]) = 1';

x_assert '/scratch/a[$index] = "yes"';

$index = 005.0;

x_assert 'count(/scratch/a[$index]) = 1';

x_assert '/scratch/a[$index] = "yes"';

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
