use strict;
use warnings;

use Test;

BEGIN {
    eval {require Win32};
    unless (defined &Win32::IsAdminUser && Win32::IsAdminUser()) {
	print"1..0 # skip Must be running as an administrator\n";
	exit 0;
    }
};

use Win32::Registry;

plan tests => 44;

ok($HKEY_CLASSES_ROOT->Create('ntperl.test.key', my $hkey));

ok($HKEY_CLASSES_ROOT->DeleteKey('ntperl.test.key'));

ok(not $HKEY_CLASSES_ROOT->DeleteKey('ntperl.test.key'));

ok($HKEY_CLASSES_ROOT->Create('ntperl.test.key', my $hkey2));

ok($hkey->Close());

ok($HKEY_CLASSES_ROOT->DeleteKey('ntperl.test.key'));

ok($hkey2->Close());

ok($HKEY_CLASSES_ROOT->Create('ntperl.test.key', $hkey));

ok($hkey->Create('k0', my $sk0));
ok($hkey->Create('k1', my $sk1));
ok($hkey->Create('k2', my $sk2));

$hkey->GetKeys(my $keys = []);
ok(scalar @$keys, 3);

my $i = 0;
foreach (sort(@$keys)) {
    ok($_, qr/^k$i$/);
    $i++;
}

ok($hkey->SetValue('k0', REG_SZ, "silly piece of info"));

ok($hkey->QueryValue('k0', my $data));
ok($data, "silly piece of info");

ok($sk0->DeleteValue("\000"));

ok($hkey->QueryValue('k0', $data));
ok($data ne "silly piece of info");

ok(not $sk0->DeleteValue("\000"));

ok($sk0->SetValueEx("string$_", undef, REG_SZ, "data$_")) for 0..2;

ok($sk0->SetValueEx('none', undef, REG_NONE, ""));
ok($sk0->DeleteValue('none'));

$sk0->GetValues(\my %values);
ok(scalar keys(%values), 3);

$i = 0;
foreach (sort(keys(%values))) {
    my($name, $type, $data) = @{$values{$_}};
    ok($name, "string$i");
    ok($type, REG_SZ);
    ok($data, "data$i");
    $i++;
}

ok($sk0->DeleteValue("string$_")) for 0..2;

$sk0->Close();
$sk1->Close();
$sk2->Close();

ok($hkey->DeleteKey("k$_")) for 0..2;

$hkey->Close();

ok($HKEY_CLASSES_ROOT->DeleteKey('ntperl.test.key'));
