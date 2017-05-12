use strict;
$^W++;
use Win32::Security::ACE;
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 74,
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1; #Repeated to avoid warnings

#Testing ACE creation by a variety of methods
my $ace1 = Win32::Security::ACE->new('FILE', 'ALLOW', 'FULL_INHERIT', 'FULL', 'BUILTIN\\Administrators');
my $rawAce1 = $ace1->rawAce();
ok($rawAce1, "\x{00}\x{03}\x{18}\x{00}\x{ff}\x{01}\x{1f}\x{00}\x{01}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{05}\x{20}\x{00}\x{00}\x{00}\x{20}\x{02}\x{00}\x{00}");
ok(${Win32::Security::ACE->new('SE_FILE_OBJECT', $rawAce1)}, ${$ace1});
ok(Win32::Security::ACE->new('SE_FILE_OBJECT', $rawAce1) ne $ace1);
ok(${Win32::Security::ACE::SE_FILE_OBJECT->new($rawAce1)}, ${$ace1});
ok(${Win32::Security::ACE::SE_FILE_OBJECT->new('ALLOW', 'FULL_INHERIT', 'FULL', 'BUILTIN\\Administrators')}, ${$ace1});
ok(${Win32::Security::ACE::SE_FILE_OBJECT::ACCESS_ALLOWED_ACE_TYPE->new($rawAce1)}, ${$ace1});
ok(${Win32::Security::ACE::SE_FILE_OBJECT::ACCESS_DENIED_ACE_TYPE->new($rawAce1)}, ${$ace1});
ok(ref(Win32::Security::ACE::SE_FILE_OBJECT::ACCESS_DENIED_ACE_TYPE->new($rawAce1)), 'Win32::Security::ACE::SE_FILE_OBJECT::ACCESS_ALLOWED_ACE_TYPE');
ok(${Win32::Security::ACE::SE_FILE_OBJECT::ACCESS_ALLOWED_ACE_TYPE->new('FULL_INHERIT', 'FULL', 'BUILTIN\\Administrators')}, ${$ace1});
ok(${$ace1->new($rawAce1)}, ${$ace1});
ok(${$ace1->new('FULL_INHERIT', 'FULL', 'BUILTIN\\Administrators')}, ${$ace1});

#Testing cloning
ok(${$ace1->clone()}, ${$ace1});
ok($ace1->clone() ne $ace1);

#Testing creation via new()
my $ace2 = $ace1->new('FULL_INHERIT', 'READ', 'BUILTIN\\Administrators');
ok(${$ace2} ne ${$ace1});

#Preparing for testing ACE mutation
my $ace3 = $ace2->clone();
ok(${$ace3}, ${$ace2});
ok($ace3 ne $ace2);
ok(${$ace3} ne ${$ace1});
ok($ace3 ne $ace1);

#Testing ACE mutation via rawAce()
$ace3->rawAce($rawAce1);
ok(${$ace3}, ${$ace1});
ok($ace3 ne $ace1);
ok(${$ace2} ne ${$ace1});
ok($ace2 ne $ace1);

#Testing rawAceType()
ok($ace1->rawAceType(), 0);
my $ace4 = Win32::Security::ACE::SE_FILE_OBJECT->new('DENY', 'FULL_INHERIT', 'FULL', 'BUILTIN\\Administrators');
ok($ace4->rawAceType(), 1);

#Testing aceType()
ok($ace1->aceType(), 'ACCESS_ALLOWED_ACE_TYPE');
ok($ace4->aceType(), 'ACCESS_DENIED_ACE_TYPE');

#Testing rawAceFlags(), including mutation
ok($ace1->rawAceFlags(), 3);
$ace3->rawAceFlags('');
ok($ace3->rawAceFlags(), 0);
ok($ace1->rawAceFlags(), 3);
ok($ace2->rawAceFlags(), 3);
ok($ace4->rawAceFlags(), 3);

#Testing aceFlags()
ok(join("|", sort keys %{$ace1->aceFlags()}), 'CI|CONTAINER_INHERIT_ACE|FI|FULL_INHERIT|OBJECT_INHERIT_ACE|OI');
ok(join("|", sort keys %{$ace3->aceFlags()}), '');

#Testing aceFlags() return values for invariance in the face of manipulation
my $aceFlags1 = $ace1->aceFlags();
ok(join("|", sort keys %{$aceFlags1}), 'CI|CONTAINER_INHERIT_ACE|FI|FULL_INHERIT|OBJECT_INHERIT_ACE|OI');
$aceFlags1->{hithere} = 1;
ok(join("|", sort keys %{$aceFlags1}), 'CI|CONTAINER_INHERIT_ACE|FI|FULL_INHERIT|OBJECT_INHERIT_ACE|OI|hithere');
ok(join("|", sort keys %{$ace1->aceFlags()}), 'CI|CONTAINER_INHERIT_ACE|FI|FULL_INHERIT|OBJECT_INHERIT_ACE|OI');

#Testing ACE mutation via aceFlags()
$ace3->aceFlags('CONTAINER_INHERIT_ACE');
ok(join("|", sort keys %{$ace3->aceFlags()}), 'CI|CONTAINER_INHERIT_ACE');

#Testing explainAceFlags()
ok(join("|", sort keys %{$ace1->explainAceFlags()}), 'FULL_INHERIT');

#Testing explainAceFlags() return values for invariance in the face of manipulation
my $explainAceFlags1 = $ace1->explainAceFlags();
ok(join("|", sort keys %{$explainAceFlags1}), 'FULL_INHERIT');
$explainAceFlags1->{hithere} = 1;
ok(join("|", sort keys %{$explainAceFlags1}), 'FULL_INHERIT|hithere');
ok(join("|", sort keys %{$ace1->explainAceFlags()}), 'FULL_INHERIT');

#Testing ACE mutation via explainAceFlags()
$ace3->explainAceFlags({FULL_INHERIT => 1, CONTAINER_INHERIT_ACE => 0});
ok(join("|", sort keys %{$ace3->aceFlags()}), 'OBJECT_INHERIT_ACE|OI');

#Testing trustee() and sid()
ok($ace1->trustee(), 'BUILTIN\\Administrators');
ok($ace1->sid(), "\x{01}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{05}\x{20}\x{00}\x{00}\x{00}\x{20}\x{02}\x{00}\x{00}");

#Preparing for more ACE mutation
my $ace5 = $ace3->clone();
ok($ace3->trustee(), 'BUILTIN\\Administrators');
ok($ace5->trustee(), 'BUILTIN\\Administrators');

#Testing ACE mutation via trustee()
$ace5->trustee('Everyone');
ok($ace3->trustee(), 'BUILTIN\\Administrators');
ok($ace5->trustee(), 'Everyone');

#Testing ACE mutation via sid()
$ace5->sid('System');
ok($ace3->trustee(), 'BUILTIN\\Administrators');
ok($ace5->trustee(), 'NT AUTHORITY\\SYSTEM');

#Testing ACE mutation via trustee() with sid value
$ace5->trustee($ace1->sid());
ok($ace3->trustee(), 'BUILTIN\\Administrators');
ok($ace5->trustee(), 'BUILTIN\\Administrators');
ok(${$ace3}, ${$ace5});
ok($ace3 ne $ace5);

#Testing rawAccessMask()
ok($ace1->rawAccessMask(), 2032127);
ok($ace2->rawAccessMask(), 1179817);

my $full_list = 'DELETE|F|FILE_ADD_FILE|FILE_ADD_SUBDIRECTORY|FILE_APPEND_DATA|'.
	'FILE_CREATE_PIPE_INSTANCE|FILE_DELETE_CHILD|FILE_EXECUTE|FILE_GENERIC_EXECUTE|'.
	'FILE_GENERIC_READ|FILE_GENERIC_WRITE|FILE_LIST_DIRECTORY|FILE_READ_ATTRIBUTES|'.
	'FILE_READ_DATA|FILE_READ_EA|FILE_TRAVERSE|FILE_WRITE_ATTRIBUTES|FILE_WRITE_DATA|'.
	'FILE_WRITE_EA|FULL|M|MODIFY|R|READ|READ_CONTROL|STANDARD_RIGHTS_ALL|'.
	'STANDARD_RIGHTS_EXECUTE|STANDARD_RIGHTS_READ|STANDARD_RIGHTS_REQUIRED|'.
	'STANDARD_RIGHTS_WRITE|SYNCHRONIZE|WRITE_DAC|WRITE_OWNER';

my $read_list = 'FILE_EXECUTE|FILE_GENERIC_EXECUTE|FILE_GENERIC_READ|FILE_LIST_DIRECTORY|'.
	'FILE_READ_ATTRIBUTES|FILE_READ_DATA|FILE_READ_EA|FILE_TRAVERSE|R|READ|READ_CONTROL|'.
	'STANDARD_RIGHTS_EXECUTE|STANDARD_RIGHTS_READ|STANDARD_RIGHTS_WRITE|SYNCHRONIZE';

#Testing accessMask()
ok(join("|", sort keys %{$ace1->accessMask()}), $full_list);
ok(join("|", sort keys %{$ace2->accessMask()}), $read_list);

#Testing accessMask() return values for invariance in the face of manipulation
my $accessMask2 = $ace2->accessMask();
ok(join("|", sort keys %{$accessMask2}), $read_list);
$accessMask2->{hithere} = 1;
ok(join("|", sort keys %{$accessMask2}), "$read_list|hithere");
ok(join("|", sort keys %{$ace2->accessMask()}), $read_list);

#Testing ACE mutation via explainAccessMask()
my $ace6 = $ace2->clone();
ok(join("|", sort keys %{$ace6->accessMask()}), $read_list);
$ace6->explainAccessMask('FULL');
ok(join("|", sort keys %{$ace6->accessMask()}), $full_list);
ok(join("|", sort keys %{$ace2->accessMask()}), $read_list);

#Testing cleansedAccessMask()
my $ace7 = $ace1->new('FULL_INHERIT|INHERIT_ONLY_ACE', 'GENERIC_READ|GENERIC_EXECUTE', 'BUILTIN\\Administrators');
ok(join("|", sort keys %{$ace7->accessMask()}), 'GENERIC_EXECUTE|GENERIC_READ');
ok(join("|", sort keys %{$ace7->cleansedAccessMask()}), 'FILE_GENERIC_EXECUTE|FILE_GENERIC_READ');
ok(join("|", sort keys %{$ace7->dbmAccessMask->break_mask($ace7->cleansedAccessMask())}), $read_list);

#Testing inheritable() for simple inheritance
ok(join("|", sort keys %{$ace3->aceFlags()}), 'OBJECT_INHERIT_ACE|OI');
ok(join("|", map {$_->rawAce()} $ace3->inheritable('CONTAINER')),
   join("|", map {$_->rawAce()} Win32::Security::ACE::SE_FILE_OBJECT->new('ALLOW', 'OBJECT_INHERIT_ACE|INHERIT_ONLY_ACE|INHERITED_ACE', 'FULL', 'BUILTIN\\Administrators'))
  );
ok(join("|", map {$_->rawAce()} $ace3->inheritable('OBJECT')),
   join("|", map {$_->rawAce()} Win32::Security::ACE::SE_FILE_OBJECT->new('ALLOW', 'INHERITED_ACE', 'FULL', 'BUILTIN\\Administrators'))
  );

#Testing inheritable() for INHERIT_ONLY_ACE
ok(join("|", map {$_->rawAce()} $ace7->inheritable('CONTAINER')),
   join("|", map {$_->rawAce()} Win32::Security::ACE::SE_FILE_OBJECT->new('ALLOW', 'INHERITED_ACE', 'READ', 'BUILTIN\\Administrators'),
                                Win32::Security::ACE::SE_FILE_OBJECT->new('ALLOW', 'FULL_INHERIT|INHERIT_ONLY_ACE|INHERITED_ACE', 'GENERIC_READ|GENERIC_EXECUTE', 'BUILTIN\\Administrators'))
  );
ok(join("|", map {$_->rawAce()} $ace7->inheritable('OBJECT')),
   join("|", map {$_->rawAce()} Win32::Security::ACE::SE_FILE_OBJECT->new('ALLOW', 'INHERITED_ACE', 'READ', 'BUILTIN\\Administrators'))
  );

#Testing inheritable() for invariance in return value manipulation
ok(($ace7->inheritable('OBJECT'))[0]->trustee('Everyone')->rawAce(), Win32::Security::ACE::SE_FILE_OBJECT->new('ALLOW', 'INHERITED_ACE', 'READ', 'Everyone')->rawAce());
ok(join("|", map {$_->rawAce()} $ace7->inheritable('OBJECT')),
   join("|", map {$_->rawAce()} Win32::Security::ACE::SE_FILE_OBJECT->new('ALLOW', 'INHERITED_ACE', 'READ', 'BUILTIN\\Administrators'))
  );
