use YAML::Active 'Load';
use Test::More tests => 12;
use lib 't/lib';
my $data = Load(<<'EOYAML');
pid: !YAML::Active::PID
  doit:
foo: bar
include_test: !YAML::Active::Include
  filename: t/testperson.yaml
ticket_no: !YAML::Active::Concat
  - '20010101.1234'
  - !YAML::Active::PID
    doit:
  - !YAML::Active::Eval
    code: sub { sprintf "%04d", ++(our $cnt) }
setup:
  - !My::YAML::Active::WritePerson
     person:
       personname: Foobar
       nichdl: AB123456-NICAT
  - !My::YAML::Active::WritePerson
     person: !YAML::Active::Include
       filename: t/testperson.yaml
EOYAML

# result set by My::YAML::Active::WritePerson in t/lib.
our $result;    # avoid 'used only once' warning
is($result, <<EOTXT, 'result of WritePerson plugin');
Writing person:
 nichdl => AB123456-NICAT
 personname => Foobar
Writing person:
 personname => Franz Testler
 pid => $$
 postalcode => A-1090 Wien
EOTXT

# use Data::Dumper; print Dumper $data;
my $expect = {
    pid          => $$,
    foo          => 'bar',
    ticket_no    => sprintf("%s%d%04d", '20010101.1234', $$, 1),
    include_test => {
        pid        => $$,
        personname => 'Franz Testler',
        postalcode => 'A-1090 Wien',
    },
    setup => [ 'Foobar', 'Franz Testler' ],
};
is_deeply($data, $expect, 'multi-activated structure');
my $shuffle = Load(<<'EOYAML');
data: !YAML::Active::Shuffle
      - 1
      - 2
      - 3
      - 4
      - 5
      - 6
      - 7
      - 8
      - 9
EOYAML
ok(eq_set($shuffle->{data}, [ reverse 1 .. 9 ]), 'shuffle');
eval {
    my $error = Load(<<'EOYAML') };
data: !YAML::Active::Concat
       personname: Foobar
       nichdl: AB123456-NICAT
EOYAML
like($@, qr/^YAML::Active::Concat expects an array ref at/, 'assert_arrayref');
sub YAML::Active::NullTester::yaml_activate { YAML::Active::yaml_NULL }
my $null_hash = Load(<<'EOYAML');
foo: 42
bar: !YAML::Active::NullTester
  frobnule: flurble
baz: hello
EOYAML
is_deeply($null_hash, { foo => 42, baz => 'hello' }, 'null hash value');
my $null_array = Load(<<'EOYAML');
- foo
- !YAML::Active::NullTester
  - bar
- baz
EOYAML
is_deeply($null_array, [qw{foo baz}], 'null array value');
my $printer = Load(<<'EOYAML');
- foo
- !YAML::Active::Print
   - '# Hello, world!'
   - 'Goodbye, world!'
- baz
EOYAML
print "\n";
is_deeply($printer, [qw{foo baz}], 'print');
my $uc_array = Load(<<'EOYAML');
data: !YAML::Active::uc
  - Hello
  - world and
  - one: GOoD
    two: byE
  - wOrLd!
EOYAML
$expect =
  { data => [ 'HELLO', 'WORLD AND', { one => 'GOoD', two => 'byE' }, 'WORLD!' ],
  };
is_deeply($uc_array, $expect, 'uppercase array values');
my $uc_hash = Load(<<'EOYAML');
- !YAML::Active::uc
  foo:  Hello
  bar:  world and
  xxx:
   - one
   - two
  baz:  GOODBYE
EOYAML
$expect = [
    {   foo => 'HELLO',
        bar => 'WORLD AND',
        xxx => [qw/one two/],
        baz => 'GOODBYE',
    }
];
is_deeply($uc_hash, $expect, 'uppercase hash values');
my $lc_array = Load(<<'EOYAML');
data: !YAML::Active::lc
      - Hello
      - world and
      - GOODBYE
      - wOrLd!
EOYAML
$expect = { data => [ 'hello', 'world and', 'goodbye', 'world!' ], };
is_deeply($lc_array, $expect, 'uppercase array values');
my $lc_hash = Load(<<'EOYAML');
- !YAML::Active::lc
  foo:  Hello
  bar:  world and
  baz:  GOODBYE
EOYAML
$expect = [
    {   foo => 'hello',
        bar => 'world and',
        baz => 'goodbye',
    }
];
is_deeply($lc_hash, $expect, 'uppercase hash values');
my $add = Load(<<'EOYAML');
result: !My::YAML::Active::Add
  - 1
  - 2
  - 3
  - 7
  - 15
EOYAML
is_deeply($add, { result => 28 }, 'add');
