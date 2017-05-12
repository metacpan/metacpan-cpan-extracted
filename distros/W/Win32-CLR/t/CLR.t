#!perl -w

use strict;
use Test::More tests => 48;
use utf8;

# binmode STDOUT, ":encoding(Shift_JIS)"; # japanese windows codepage
# binmode STDERR, ":encoding(Shift_JIS)";

BEGIN { use_ok("Win32::CLR") };

my $dt = Win32::CLR->create_instance("System.DateTime", 2007, 8, 9, 10, 11, 12);
ok(defined $dt);
isa_ok($dt, "Win32::CLR");
ok( $dt->derived_from("System.DateTime") );
is( $dt->get_property("Year"), 2007 );
is( $dt->get_value("Year"), 2007 );
is( $dt->get_property("Month"), 8 );
is( $dt->get_value("Month"), 8 );

is( $dt->get_year(), 2007 ); # autoload
is( $dt->get_y_e_Ar(), 2007 );

ok( Win32::CLR->has_member("System.DateTime", "Minute", "Property") );
ok( Win32::CLR->has_member("System.DateTime", "Second") );
ok( $dt->has_member("Minute", "Property") );
ok( $dt->has_member("Second") );

my $dt2 = Win32::CLR->create_instance("System.DateTime", 2007, 8, 9, 10, 11, 12);
my $dt3 = Win32::CLR->create_instance("System.DateTime", 2008, 8, 9, 10, 11, 12);
ok($dt == $dt);
ok($dt == $dt2);
ok($dt != $dt3);

$dt = $dt->call_method("AddYears", 1);
ok(defined $dt);
isa_ok($dt, "Win32::CLR");
ok( $dt->derived_from("System.DateTime") );
is( $dt->get_value("Year"), 2008 );

ok($dt > $dt2);
ok($dt2 < $dt);
ok($dt != $dt2);
ok( !($dt == $dt2) );
ok( !($dt != $dt3) );
ok($dt == $dt3);

cmp_ok( $dt->get_addr(), "==", $dt->get_addr() );
cmp_ok( $dt->get_addr(), "!=", $dt3->get_addr() );

my $asm_name = "System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
my $asm = Win32::CLR->load($asm_name);
isa_ok($asm, "Win32::CLR");
ok( $asm->derived_from("System.Reflection.Assembly") );

my $button = Win32::CLR->create_instance("System.Windows.Forms.Button");
isa_ok($button, "Win32::CLR");
ok( $button->derived_from("System.Windows.Forms.Button") );

my $event_args = Win32::CLR->get_field("System.EventArgs", "Empty");

my $test_sub = sub {
    my ($string, $event_args) = @_;
    ok( $event_args->derived_from("System.EventArgs") );
    is($string, "ABCDEFG");
};

my $deleg = Win32::CLR->create_delegate("System.EventHandler", $test_sub);
ok( $deleg->derived_from("System.Delegate") );
$deleg->call_method("DynamicInvoke", ["ABCDEFG", $event_args]);

my $dict = Win32::CLR->create_instance("System.Collections.Generic.Dictionary<System.String, System.Int32>");
isa_ok($dict, "Win32::CLR");
ok( $dict->derived_from("System.Collections.Generic.Dictionary<System.String, System.Int32>") );
$dict->set_property("Item", "ABC", 4321);
is( $dict->get_property("Item", "ABC"), 4321 );

my $dict2 = Win32::CLR->create_instance("System.Collections.Generic.Dictionary`2[System.String, System.Int32]");
isa_ok($dict2, "Win32::CLR");
ok( $dict2->derived_from("System.Collections.Generic.Dictionary<System.String, System.Int32>") );
$dict2->set_property("Item", "ABC", 4321);
is( $dict2->get_property("Item", "ABC"), 4321 );

my $array = Win32::CLR->create_array("System.String", "A", "B", "C");
isa_ok($array, "Win32::CLR");
is( $array->call_method("GetValue", 0), "A" );
is( $array->call_method("GetValue", 1), "B" );
is( $array->call_method("GetValue", 2), "C" );

eval {
    my $dt1 = Win32::CLR->create_instance("System.DateTime", 2007, 8, 9, 10);
};

ok($@);
is( $@->get_type_name(), "System.MissingMethodException" );
