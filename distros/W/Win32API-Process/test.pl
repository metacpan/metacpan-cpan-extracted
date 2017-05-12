#!perl -w

use strict;

my @tests = (
	"CloseProcess",
	"GetLastProcessError",
	"OpenProcess",
	"SetLastProcessError",
#	"TerminateProcess"
);

sub speak { printf "\n%-70s", @_; }
sub croak { printf "\n%-70s", @_; }

use Test;
speak "plan tests: "; plan tests => scalar @tests + 1;

use Win32API::Process ':All';
speak "test use Win32API::Process ':All': "; ok 1;

my $result = 1;
foreach my $test (@tests) {
	speak "test $test: ";
	if (eval "Test$test") {
		ok 1;
	} else {
		croak "  GetLastProcessError() returned \"" . GetLastProcessError . "\"";
		ok 0;
		$result = 0;
	}
}
speak "summarize tests: "; print $result ? "success" : "failure", "\n";


sub TestCloseProcess {
	my ($result, $handle);

	$handle = OpenProcess(PROCESS_ALL_ACCESS, 0, $$);
	croak "  OpenProcess(PROCESS_ALL_ACCESS, 0, $$) returned \"$handle\"";
	if ($handle == 0) { return 0; }

	$result = CloseProcess($handle);
	croak "  CloseProcess($handle) returned \"$result\"";
	if (!$result) { return 0; }

	1
}


sub TestGetLastProcessError {
	my ($result, $handle, $error);

	SetLastProcessError(0);
	croak "  SetLastProcessError(0) called";

	$handle = OpenProcess(PROCESS_ALL_ACCESS, 0, $$);
	croak "  OpenProcess(PROCESS_ALL_ACCESS, 0, $$) returned \"$handle\"";
	if ($handle == 0) { return 0; }

	$result = CloseProcess($handle);
	croak "  CloseProcess($handle) returned \"$result\"";
	if (!$result) { return 0; }

	$error = GetLastProcessError();
	croak "  GetLastProcessError() returned \"$error\"";
	if ($error != 0) { return 0; }

	$result = CloseProcess(0);
	croak "  CloseProcess(0) returned \"$result\"";
	if ($result) { return 0; }

	$error = GetLastProcessError();
	croak "  GetLastProcessError() returned \"$error\"";
	if ($error == 0) { return 0; }

	1
}


sub TestOpenProcess {
	my ($result, $handle);

	$handle = OpenProcess(PROCESS_ALL_ACCESS, 0, $$);
	croak "  OpenProcess(PROCESS_ALL_ACCESS, 0, $$) returned \"$handle\"";
	if ($handle == 0) { return 0; }

	$result = CloseProcess($handle);
	croak "  CloseProcess($handle) returned \"$result\"";
	if (!$result) { return 0; }

	1
}


sub TestSetLastProcessError {
	my ($error);

	SetLastProcessError(0);
	croak "  SetLastProcessError(0) called";

	$error = GetLastProcessError();
	croak "  GetLastProcessError() returned \"$error\"";
	if ($error != 0) { return 0; }

	SetLastProcessError(18);
	croak "  SetLastProcessError(18) called";

	$error = GetLastProcessError();
	croak "  GetLastProcessError() returned \"$error\"";
	if ($error != 18) { return 0; }

	1
}


sub TestTerminateProcess {
	my ($result, $handle, $result2);

	$handle = OpenProcess(PROCESS_ALL_ACCESS, 0, $$);
	croak "  OpenProcess(PROCESS_ALL_ACCESS, 0, $$) returned \"$handle\"";
	if ($handle == 0) { return 0; }

	$result = TerminateProcess($handle);
	croak "  TerminateProcess($handle) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseProcess($handle);
	croak "  CloseProcess($handle) returned \"$result2\"";
	if (!$result2) { return 0; }

	$result
}
