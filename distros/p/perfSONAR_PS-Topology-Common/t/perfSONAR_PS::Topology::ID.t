use Test::More 'no_plan';

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

use_ok('perfSONAR_PS::Topology::ID');
use perfSONAR_PS::Topology::ID;

my $type1 = "domain";
my $type2 = "node";
my $type3 = "port";
my $type4 = "link";
my $field1 = "field1";
my $field2 = "field2";
my $field3 = "field3";
my $field4 = "field4";

my $id1 = idConstruct($type1, $field1, "", "", "", "", "", "");

ok($id1 eq "urn:ogf:network:$type1=$field1");

my $id2 = idConstruct($type1, $field1, $type2, $field2, "", "", "", "");

ok($id2 eq "urn:ogf:network:$type1=$field1:$type2=$field2");

my $id3 = idConstruct($type1, $field1, $type2, $field2, $type3, $field3, "", "");

ok($id3 eq "urn:ogf:network:$type1=$field1:$type2=$field2:$type3=$field3");

my $id4 = idConstruct($type1, $field1, $type2, $field2, $type3, $field3, $type4, $field4);

ok($id4 eq "urn:ogf:network:$type1=$field1:$type2=$field2:$type3=$field3:$type4=$field4");

my $id5 = idAddLevel($id3, $type4, $field4);

ok ($id5 eq $id4);

my $type;

my $id6 = idRemoveLevel($id4, \$type);

ok ($id6 eq $id3);
ok ($type eq $type3);

my $base = idBaseLevel($id4, \$type);

ok ($base eq $field4);

my $str_encoded = "%25%3A%23%2F%3F";
my $str_decoded = "%:#/?";

ok (idDecode($str_encoded) eq $str_decoded);

ok (idEncode($str_decoded) eq $str_encoded);

my @split;
@split = idSplit($id4, 0, 0);
ok ($#split == 9);
ok ($split[0] == 0);
ok ($split[1] eq $type4);
ok ($split[2] eq $type4);
ok ($split[3] eq $field4);
ok ($split[4] eq $type3);
ok ($split[5] eq $field3);
ok ($split[6] eq $type2);
ok ($split[7] eq $field2);
ok ($split[8] eq $type1);
ok ($split[9] eq $field1);

@split = idSplit($id4, 0, 1);
ok ($#split == 9);
ok ($split[0] == 0);
ok ($split[1] eq $type4);
ok ($split[2] eq $type1);
ok ($split[3] eq $field1);
ok ($split[4] eq $type2);
ok ($split[5] eq $field2);
ok ($split[6] eq $type3);
ok ($split[7] eq $field3);
ok ($split[8] eq $type4);
ok ($split[9] eq $field4);

@split = idSplit($id4, 1, 1);
ok ($#split == 9);
ok ($split[0] == 0);
ok ($split[1] eq $type4);
ok ($split[2] eq $type1);
ok ($split[3] eq idConstruct($type1, $field1, "", "", "", "", "", ""));
ok ($split[4] eq $type2);
ok ($split[5] eq idConstruct($type1, $field1, $type2, $field2, "", "", "", ""));
ok ($split[6] eq $type3);
ok ($split[7] eq idConstruct($type1, $field1, $type2, $field2, $type3, $field3, "", ""));
ok ($split[8] eq $type4);
ok ($split[9] eq idConstruct($type1, $field1, $type2, $field2, $type3, $field3, $type4, $field4));

print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

