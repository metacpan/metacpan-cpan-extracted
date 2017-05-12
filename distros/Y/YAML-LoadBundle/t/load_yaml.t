# vim: ft=perl

use strict;
use warnings;

use Test::More tests => 26;
use Test::Exception;
use Fcntl qw(:seek);
use File::Temp qw(:POSIX);
use YAML::LoadBundle qw(load_yaml);

my $yaml = <<'...';
---
baroque:   gabrielli
classical: haydn
romantic:  false
...

my ($fh, $file) = tmpnam();
print $fh $yaml;
seek  $fh, 0, SEEK_SET;

check(load_yaml($yaml));
check(load_yaml($fh));
check(load_yaml($file));

unlink $file;

sub check {
    my $hash = shift;

    ok $hash;
    ok ref($hash);
    is ref($hash), 'HASH';
    is $hash->{baroque},   'gabrielli';
    is $hash->{classical}, 'haydn';
}

# error-handling

$yaml = <<'...';
---
comment: this should # disappear
...

my $ref = load_yaml($yaml);
is $ref->{comment}, 'this should', 'Strip trailing comment';

$yaml = <<"...";
---
\ttab: should raise sensible error
...

throws_ok { load_yaml($yaml) } qr/found character that cannot start any token/, 'Reports tab error';

$yaml = <<'...';
---
bracket: [trailing, space, survives]   # to show the space
...

lives_ok { load_yaml($yaml) } 'trailing space removed';

# reference-flattening

$yaml = <<'...';
---
foo:
  export: &foo { x: 1 }
  y: 2

bar:
  import: *foo
  export: &bar { z: 3 }

baz:
  import: [ *foo, *bar ]
  export: &baz { x: overridden }
...

$ref = load_yaml($yaml);
is_deeply(
    $ref,
    {
        foo => { x => 1, y => 2 },
        bar => { x => 1, z => 3 },
        baz => { x => 'overridden', z => 3 },
    },
    'reference-flattening',
);

is_deeply(
    load_yaml(<<'...'),
quux1: &quux1
  export:
    x:
      y: 2

quux2: &quux2
  x:
    y: 1
    z: 3

quux3: 
  -merge: [ *quux2, *quux1 ]
...
    {
        quux1 => { x => { y => 2 } },
        quux2 => { x => { y => 1, z => 3 } },
        quux3 => { x => { y => 2, z => 3 } },
    },
);

is_deeply(
    load_yaml(<<'...'),
foo: &foo
    - foo1
    - foo2
bar: &bar
    - bar1
baz: &baz
    - baz1
    - baz2
    - baz3
quux: { -flatten: [ *foo, *bar, *baz ] }
...
    { 
        foo  => [ qw(foo1 foo2) ],
        bar  => [ qw(bar1) ],
        baz  => [ qw(baz1 baz2 baz3) ],
        quux => [ qw(foo1 foo2 bar1 baz1 baz2 baz3) ],
    }
);

is_deeply(
    load_yaml(<<'...'),
foo: { -flatten: [ [ 1 ], { -flatten: [ [ 2 ], [ 3 ] ] } ] }
...
    {
        foo => [ 1, 2, 3 ],
    },
    'nested flatten',
);

is_deeply(
    load_yaml(<<'...'),
foo: &foo
    foo01: foo02
    foo11: foo12
bar: &bar
    bar1: bar2
baz: &baz
    baz01: baz02
    baz11: baz12
    baz21: baz22
quux: { -flattenhash: [ *foo, *bar, *baz ] }
...
    { 
        foo  => { foo01 => 'foo02', foo11 => 'foo12' },
        bar  => { bar1  => 'bar2' },
        baz  => { baz01 => 'baz02', baz11 => 'baz12', baz21 => 'baz22' },
        quux => {
            foo01 => 'foo02', foo11 => 'foo12',
            bar1  => 'bar2',
            baz01 => 'baz02', baz11 => 'baz12', baz21 => 'baz22',
        }
                
    }
);

is_deeply(
    load_yaml(<<'...'),
exporter:
    export: &e { x: 1 }
re_exporter:
    export: &f
        y: 2
        import: *e
importer:
    import: *f
    z: 3
...
    {
        exporter    => { x => 1 },
        re_exporter => { x => 1, y => 2 },
        importer    => { x => 1, y => 2, z => 3 },
    },
    'multi-step export/import',
);

# YAML that looks like a pseudo-hash shouldn't generate any warnings
{
$yaml = <<'...';
---
- export: &foo { x: 1 }
  y: 2
- things: one
  more:   two
  import: *foo
...

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, shift };
    $ref = load_yaml($yaml);
    is_deeply \@warnings, [], 'no warnings from loading a fake pseudo-hash';
    is_deeply(
        $ref,
        [
            { x => 1, y => 2 },
            { things => 'one', more => 'two', x => 1 },
        ],
        'not really a pseudo-hash'
    );
}
