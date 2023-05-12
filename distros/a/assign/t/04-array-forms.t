use assign::Test;

# Array destructuring:

test <<'...', "Unpack aref with _ skips";
my [ $a, _, _, $d ] = $aref;
+++
my $a = $aref->[0];
my $d = $aref->[3];
#line 1
...

test <<'...', "Unpack into \$_ global var";
my [ $a, $_, $b ] = $aref;
+++
my $a = $aref->[0];
$_ = $aref->[1];
my $b = $aref->[2];
#line 1
...

test <<'...', "Unpack aref with numeric skips";
my [ 7, $a, 42, $b ] = $aref;
+++
my $a = $aref->[7];
my $b = $aref->[50];
#line 1
...

test <<'...', "Unpack unref with defaults";
my [ $a, $b=42, $c="hi\nthere", $d=$a, $e='ok computer' ] = $aref;
+++
my $a = $aref->[0];
my $b = $aref->[1] // 42;
my $c = $aref->[2] // "hi\nthere";
my $d = $aref->[3] // $a;
my $e = $aref->[4] // 'ok computer';
#line 1
...
