#!perl -w

use strict;

my $winpid = $^O eq 'cygwin' ? Cygwin::pid_to_winpid($$) : $$;

my @tests = (
	"EnumProcesses",
	"EnumProcessModules",
	"GetLastProcessStatusError",
	"GetModuleBaseName",
	"GetModuleFileNameEx",
	"GetModuleInformation",
	"SetLastProcessStatusError"
);

sub speak { printf "\n%-70s", @_; }
sub croak { printf "\n%-70s", @_; }

use Test;
speak "plan tests: "; plan tests => scalar @tests + 1;

use Win32API::ProcessStatus ':All';
speak "test use Win32API::ProcessStatus ':All': "; ok 1;

my $result = 1;
foreach my $test (@tests) {
	speak "test $test: ";
	if (eval "Test$test") {
		ok 1;
	} else {
		croak "  GetLastProcessStatusError() returned \"" . GetLastProcessStatusError . "\"";
		ok 0;
		$result = 0;
	}
}
speak "summarize tests: "; print $result ? "success" : "failure", "\n";


sub TestEnumProcesses {
	my ($result, $IDs);

	$result = EnumProcesses($IDs);
	croak "  EnumProcesses(\$IDs) returned \"$result\"";
	if (!$result) { return 0; }

	1
}


sub TestEnumProcessModules {
	my ($result, $handle, $handles, $result2);

	use Win32API::Process ':All';

	$handle = OpenProcess(PROCESS_ALL_ACCESS, 0, $winpid);
	croak "  OpenProcess(PROCESS_ALL_ACCESS, 0, $winpid) returned \"$handle\"";
	if ($handle == 0) { return 0; }

	$result = EnumProcessModules($handle, $handles);
	croak "  EnumProcessModules($handle, \$handles) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseProcess($handle);
	croak "  CloseProcess($handle) returned \"$result2\"";
	if (!$result2) { return 0; }

	$result
}


sub TestGetLastProcessStatusError {
	my ($result, $IDs, $error, $handles);

	SetLastProcessStatusError(0);
	croak "  SetLastProcessStatusError(0) called";

	$result = EnumProcesses($IDs);
	croak "  EnumProcesses(\$IDs) returned \"$result\"";
	if (!$result) { return 0; }

	$error = GetLastProcessStatusError();
	croak "  GetLastProcessStatusError() returned \"$error\"";
	if ($error != 0) { return 0; }

	$result = EnumProcessModules(0, $handles);
	croak "  EnumProcessModules(0, \$handles) returned \"$result\"";
	if ($result) { return 0; }

	$error = GetLastProcessStatusError();
	croak "  GetLastProcessStatusError() returned \"$error\"";
	if ($error == 0) { return 0; }

	1
}


sub TestGetModuleBaseName {
	my ($result, $handle, $handles, $name, $result2);

	use Win32API::Process ':All';

	$handle = OpenProcess(PROCESS_ALL_ACCESS, 0, $winpid);
	croak "  OpenProcess(PROCESS_ALL_ACCESS, 0, $winpid) returned \"$handle\"";
	if ($handle == 0) { return 0; }

	$result = EnumProcessModules($handle, $handles);
	croak "  EnumProcessModules($handle, \$handles) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = GetModuleBaseName($handle, $$handles[0], $name);
	croak "  GetModuleBaseName($handle, $$handles[0], \$name) returned \"$result\"";
	if (!$result) { return 0; }
EXIT:
	$result2 = CloseProcess($handle);
	croak "  CloseProcess($handle) returned \"$result2\"";
	if (!$result2) { return 0; }

	$result
}


sub TestGetModuleFileNameEx {
	my ($result, $handle, $handles, $name, $result2);

	use Win32API::Process ':All';

	$handle = OpenProcess(PROCESS_ALL_ACCESS, 0, $winpid);
	croak "  OpenProcess(PROCESS_ALL_ACCESS, 0, $winpid) returned \"$handle\"";
	if ($handle == 0) { return 0; }

	$result = EnumProcessModules($handle, $handles);
	croak "  EnumProcessModules($handle, \$handles) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = GetModuleFileNameEx($handle, $$handles[0], $name);
	croak "  GetModuleFileNameEx($handle, $$handles[0], \$name) returned \"$result\"";
	if (!$result) { return 0; }
EXIT:
	$result2 = CloseProcess($handle);
	croak "  CloseProcess($handle) returned \"$result2\"";
	if (!$result2) { return 0; }

	$result
}


sub TestGetModuleInformation {
	my ($result, $handle, $handles, $modinfo, $result2);

	use Win32API::Process ':All';

	$handle = OpenProcess(PROCESS_ALL_ACCESS, 0, $winpid);
	croak "  OpenProcess(PROCESS_ALL_ACCESS, 0, $winpid) returned \"$handle\"";
	if ($handle == 0) { return 0; }

	$result = EnumProcessModules($handle, $handles);
	croak "  EnumProcessModules($handle, \$handles) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = GetModuleInformation($handle, $$handles[0], $modinfo);
	croak "  GetModuleInformation($handle, $$handles[0], \$modinfo) returned \"$result\"";
	if (!$result) { return 0; }
EXIT:
	$result2 = CloseProcess($handle);
	croak "  CloseProcess($handle) returned \"$result2\"";
	if (!$result2) { return 0; }

	$result
}


sub TestSetLastProcessStatusError {
	my ($error);

	SetLastProcessStatusError(0);
	croak "  SetLastProcessStatusError(0) called";

	$error = GetLastProcessStatusError();
	croak "  GetLastProcessStatusError() returned \"$error\"";
	if ($error != 0) { return 0; }

	SetLastProcessStatusError(18);
	croak "  SetLastProcessStatusError(18) called";

	$error = GetLastProcessStatusError();
	croak "  GetLastProcessStatusError() returned \"$error\"";
	if ($error != 18) { return 0; }

	1
}
