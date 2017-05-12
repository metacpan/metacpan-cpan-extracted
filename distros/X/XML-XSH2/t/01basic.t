# -*- cperl -*-
use Test;

use IO::File;

BEGIN {
  autoflush STDOUT 1;
  autoflush STDERR 1;

  @xsh_test=split /\n\n/, <<'EOF';
quiet;

list;

list | wc

count /;

insert element 'foo' into /*;

count count(//foo)>0;

assign $bar=0;

count $bar=0;

while count(//foo)<10 {
  count count(//foo)<10;
  count count(//foo);
  insert element "<foo bar='${bar}' count=${(count(//foo))}" into /*;
  $bar=$bar+1;
  echo $bar;
};

count count(//foo)=10;

insert attribute "bar=8" into //foo[3]

count count(//foo[@bar="8"])=2;

map :i { $_=1 } //foo[3]/@bar

count count(//foo[@count and @bar=string(@count)-1])>0;

perl { 1+1; };

exec ls -l;

! echo -n " sh test: " ; echo " (success)"; >&2

$t := clone $scratch;

list | wc;

def myfunc { defs; encoding iso-8859-2; };

myfunc;

files;

ls $scratch;

foreach $scratch//foo { 
  pwd;
  local $WARNINGS=0;
  insert text "no. " into .; ls;
  copy ./@bar append ./text()
}

indent 1;

ls //foo;

ls //foo/text()[starts-with(.,'no. 8')] | cat;

if count(//foo/text()[starts-with(.,'no. 8')])!=1 { perl die };

map {uc} //foo/text();

unless count(//foo/text()[starts-with(.,'NO. 8')])=1 { perl die };

rename { join "",reverse split "",$_; } //foo;

count count(//oof)=10

if 1+1!=2 { perl die } else { unless (1+2!=3) { expr 1 } else { perl die } };

if 1+1=2 { unless 1+2=3 { perl die } else { expr 1 } } else { perl die };

test-mode; perl die;

run-mode;

unless &{ eval 'expr 1+1=2' } { throw "1+1!=2 ?" }

ls $scratch//oof[not(@bar)] | cat

move $scratch//oof[not(@bar)] into $t//foo[@bar='1'];

count count($scratch/scratch/oof)=9;

ls $t/scratch/foo[@bar='1'] | cat

count count($t/scratch/foo/oof)=1;

locate //oof | cat

cd $t/scratch/foo/oof/text()

pwd | cat

remove $t//oof;

pwd | cat

count count($t/scratch/foo/oof)=0;

cd $scratch;

count count($t//foo)=10;

$new1 := create "test"

count count(//*)=1;

list / | cat;

$new2 := create 
"<?xml version='1.0' encoding='iso-8859-1'?>
<!DOCTYPE root [
  <!ELEMENT root (#PCDATA | br)*>
  <!ATTLIST root id ID #REQUIRED>
  <!ELEMENT br EMPTY>
]>
<root id='root1'>
My test document <br/>is quite nice and <br/>simple.
</root>
"

count id('root1');
count //root;
count count(//br)=2;
count //text()[contains(.,'simple')];

dtd | cat;

validate --yesno;

validate;

list | cat

xinsert element "silly" after //br

list / | cat

count count(//br[./following-sibling::silly])=2

ls $scratch | cat;
ls $t | cat;
ls $new1 | cat;
ls $new2 | cat

cd $t;

close $t;

ls / | cat
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

my $separator = ('MSWin32' eq $^O) ? '&'
                                   : ';';
foreach (@xsh_test) {
  print STDERR "\n\n[[ $_ ]]\n" if $verbose;
  eval { xsh($_) };
  print STDERR $@ if $@;
  ok( !$@ );
  undef $@;
}
