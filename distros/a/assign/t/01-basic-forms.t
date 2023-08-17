use assign::Test;

# Array destructuring:

test <<'...', "Unpack aref into 'my' vars";
my [ $a, $b, $c ] = $aref;
+++
my ($a, $b, $c);
$a = $aref->[0];
$b = $aref->[1];
$c = $aref->[2];
#line 1
...

test <<'...', "Multi-line declaration";

my [
    $a,
    $b,
    $c,
]
    = $aref;
print $b;
+++

my ($a, $b, $c);
$a = $aref->[0];
$b = $aref->[1];
$c = $aref->[2];
#line 7
print $b;
...

test <<'...', "Unpack a literal aref";
my [ $a, $b, $c ] = [111, 222, 333];
+++
my $_1 = [111, 222, 333];
my ($a, $b, $c);
$a = $_1->[0];
$b = $_1->[1];
$c = $_1->[2];
#line 1
...

test <<'...', "Unpack aref into 'our' vars";
our [ $a, $b, $c ] = $aref;
+++
our ($a, $b, $c);
$a = $aref->[0];
$b = $aref->[1];
$c = $aref->[2];
#line 1
...

test <<'...', "Unpack aref into 'local' vars";
local [ $a, $b, $c ] = $aref;
+++
local ($a, $b, $c);
$a = $aref->[0];
$b = $aref->[1];
$c = $aref->[2];
#line 1
...

test <<'...', "Unpack aref into differently declared vars";
my $a; our $b; local $c;
[ $a, $b, $c, $d ] = $aref;
+++
my $a; our $b; local $c;
$a = $aref->[0];
$b = $aref->[1];
$c = $aref->[2];
$d = $aref->[3];
#line 2
...

# Hash destructuring:

test <<'...', "Unpack href into 'my' vars";
my { $a, $b, $c } = $href;
+++
my ($a, $b, $c);
$a = $href->{a};
$b = $href->{b};
$c = $href->{c};
#line 1
...

test <<'...', "Unpack literal href into 'my' vars";
my { $a, $b, $c } = {a => 111, b => 222, c => 333};
+++
my $_1 = {a => 111, b => 222, c => 333};
my ($a, $b, $c);
$a = $_1->{a};
$b = $_1->{b};
$c = $_1->{c};
#line 1
...
