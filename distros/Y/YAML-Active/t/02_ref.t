use warnings;
use strict;
use YAML::Active 'Load';
use Test::More tests => 2;
use lib 't/lib';
my $data = Load(<<'EOYAML');
x: &REF
  foo: 1
y: *REF
EOYAML
TODO: {
    local $TODO = 'retaining references not implemented yet';
    is("$data->{x}", "$data->{y}", 'references are preserved');
}
$data = Load(<<'EOYAML');
x: &REF !YAML::Active::Concat
  - one
  - two
  - three
y: *REF
EOYAML
is("$data->{x}", "$data->{y}", 'references are preserved');
