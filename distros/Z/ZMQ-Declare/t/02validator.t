use strict;
use warnings;
use Test::More;
use File::Spec;

use ZMQ::Declare::ZDCF::Validator;
use Clone ();

my $validator = ZMQ::Declare::ZDCF::Validator->new;
isa_ok($validator, "ZMQ::Declare::ZDCF::Validator");

# Validate some v0 structures
ok($validator->validate({}), "validate empty");
ok($validator->validate($validator->validate_and_upgrade({})), "validate upgraded empty");

ok(!$validator->validate({foo => "bar"}), "invalid validate fails");
ok(!$validator->validate("asd"), "invalid validate fails 2");

validation_tests( "context only" => { context => {iothreads => 20} });
validation_tests( "device w/o sockets" => {
  context => {iothreads => 20},
  foo => {type => "baz"},
});

my $struct = {
  context => {iothreads => 20},
  foo => {
    type => "baz",
    foosock => {
      type => "pull",
      bind => "incproc://#1",
    },
  },
};
validation_tests( "single-device-single-socket" => $struct);
ok($validator->validate($struct, '0'));
ok(!$validator->validate($struct, '1'));

$struct->{foo}{foosock}{type} = "doesntexist";
ok(!$validator->validate($struct), "munged struct validation fails");


# Validate some structures read from file
my $datadir = -d 't' ? File::Spec->catdir(qw(t data)) : "data";
my $testzdcf_v0 = File::Spec->catfile($datadir, 'simple_v0.zdcf');
ok(-f $testzdcf_v0)
  or die "Missing test file";
my $testzdcf_v1 = File::Spec->catfile($datadir, 'simple_v1.zdcf');
ok(-f $testzdcf_v1)
  or die "Missing test file";

use JSON;
my $zdcf_v0 = JSON::decode_json(do {local $/; open my $fh, "<", $testzdcf_v0 or die $!; <$fh>});
my $zdcf_v1 = JSON::decode_json(do {local $/; open my $fh, "<", $testzdcf_v1 or die $!; <$fh>});

is($validator->find_spec_version($zdcf_v0), 0, "v0 is detected as v0");
ok($validator->validate($zdcf_v0), "v0 file ok");
is($validator->find_spec_version($zdcf_v1), 1, "v1 is detected as v1");
ok($validator->validate($zdcf_v1), "v1 file ok");

done_testing();

sub validation_tests {
  my $name = shift;
  my $structure = shift;
  $structure = Clone::clone($structure);
  ok($validator->validate($structure), "$name: validate");
  ok($validator->validate_and_upgrade($structure), "$name: validate-and-upgrade");
  $validator->upgrade_structure($structure);
  ok($structure->{version} >= 1, "$name: upgrade result gets version");
  ok($validator->validate($structure), "$name: upgraded structure is still valid");
}
