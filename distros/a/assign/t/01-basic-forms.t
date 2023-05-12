use assign::Test;

# Array destructuring:

test <<'...', "Unpack aref into 'my' vars";
my [ $a, $b, $c ] = $aref;
+++
my $a = $aref->[0];
my $b = $aref->[1];
my $c = $aref->[2];
#line 1
...

test <<'...', "Unpack a literal aref";
my [ $a, $b, $c ] = [111, 222, 333];
+++
my $_1 = [111, 222, 333];
my $a = $_1->[0];
my $b = $_1->[1];
my $c = $_1->[2];
#line 1
...

test <<'...', "Unpack aref into 'our' vars";
our [ $a, $b, $c ] = $aref;
+++
our $a = $aref->[0];
our $b = $aref->[1];
our $c = $aref->[2];
#line 1
...

test <<'...', "Unpack aref into 'local' vars";
local [ $a, $b, $c ] = $aref;
+++
local $a = $aref->[0];
local $b = $aref->[1];
local $c = $aref->[2];
#line 1
...

test <<'...', "Unpack aref into 'local' vars";
my $a; our $b; local $c;
[ $a, $b, $c ] = $aref;
+++
my $a; our $b; local $c;
$a = $aref->[0];
$b = $aref->[1];
$c = $aref->[2];
#line 2
...

# Hash destructuring:

test <<'...', "Unpack href into 'my' vars";
my { $a, $b, $c } = $href;
+++
my $a = $href->{a};
my $b = $href->{b};
my $c = $href->{c};
#line 1
...

test <<'...', "Unpack literal href into 'my' vars";
my { $a, $b, $c } = {a => 111, b => 222, c => 333};
+++
my $_1 = {a => 111, b => 222, c => 333};
my $a = $_1->{a};
my $b = $_1->{b};
my $c = $_1->{c};
#line 1
...
