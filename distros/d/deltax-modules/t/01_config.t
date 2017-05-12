#!/usr/bin/perl

my $num = 1;

sub ok {
	my $ok = shift;
	if ($ok) { print "ok $num\n"; }
	else { print "not ok $num\n"; }
	$num++;
}

print "1..14\n";

use DeltaX::Config;

my $config = new DeltaX::Config(filename=>'t/01_config1.conf');
ok (defined $config);
ok ($config->isa('DeltaX::Config'));
my $data = $config->read();
ok (defined $data);
ok ($data->{key1} eq 'val1');
ok ($data->{key2} eq 'val2');
ok ($data->{key3}{subkey1} eq 'val31');
ok ($data->{key3}{subkey2} eq 'val32');
ok ($data->{key4} eq 'split41 split42');
ok ($data->{key5} eq 'split51 split52');

$config = new DeltaX::Config(filename=>'t/01_config2.conf');
ok (defined $config);
$data = $config->read();
ok (defined $data);
ok ($data->{key1} eq 'val1');
ok ($data->{key21} eq 'val21');
ok ($data->{'02_config22'}{key22} eq 'val22');
