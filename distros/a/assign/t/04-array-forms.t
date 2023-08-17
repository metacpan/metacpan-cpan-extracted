use assign::Test;

# Array destructuring:

test <<'...', "Unpack aref with _ skips";
my [ $a, _, _, $d ] = $aref;
+++
my ($a, $d);
$a = $aref->[0];
$d = $aref->[3];
#line 1
...

test <<'...', "Unpack into \$_ global var";
my [ $a, $_, $b ] = $aref;
+++
my ($a, $b);
$a = $aref->[0];
$_ = $aref->[1];
$b = $aref->[2];
#line 1
...

test <<'...', "Unpack aref with numeric skips";
my [ 7, $a, 42, $b ] = $aref;
+++
my ($a, $b);
$a = $aref->[7];
$b = $aref->[50];
#line 1
...

test <<'...', "Unpack unref with defaults";
my [ $a, $b=42, $c="hi\nthere", $d=$a, $e='ok computer' ] = $aref;
+++
my ($a, $b, $c, $d, $e);
$a = $aref->[0];
$b = $aref->[1] // 42;
$c = $aref->[2] // "hi\nthere";
$d = $aref->[3] // $a;
$e = $aref->[4] // 'ok computer';
#line 1
...

test <<'...', "Inside a subroutine";
sub foo {
    my [$a, $b] = $self->data;
}
+++
sub foo {
    my $_1 = $self->data;
my ($a, $b);
$a = $_1->[0];
$b = $_1->[1];
#line 2
}
...

test <<'...', "Glob rest into array";
sub foo {
    my [$a, $b, @c] = $aref;
}
+++
sub foo {
    my ($a, $b, @c);
$a = $aref->[0];
$b = $aref->[1];
@c = @$aref[2..@$aref-1];
#line 2
}
...

test <<'...', "Glob rest into an array ref";
sub foo {
    my [$a, $b, @$c] = $aref;
}
+++
sub foo {
    my ($a, $b, $c);
$a = $aref->[0];
$b = $aref->[1];
$c = [@$aref[2..@$aref-1]];
#line 2
}
...
