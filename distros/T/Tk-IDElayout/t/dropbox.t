# Basic method tests for the dropbox object

use strict;

use Test::More tests => 5;

use Tk::IDElayout::DropBox;

my $dropbox = Tk::IDElayout::DropBox->instance();

ok(defined($dropbox), "Dropbox instance create");

my $data1 = "data1";

$dropbox->set("1" => $data1);

is($dropbox->get("1"), "data1", "Dropbox set/get check1");

$dropbox->set("2" => "data2");

is($dropbox->get("2"), "data2", "Dropbox set/get check2");


is($dropbox->delete("2"), "data2", "Dropbox delete check1");

# Make sure 2 was actually deleted
ok(!defined($dropbox->get("2")), "Dropbox delete check2");


