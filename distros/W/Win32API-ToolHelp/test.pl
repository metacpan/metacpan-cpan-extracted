#!perl -w

use strict;

my @tests = (
	"CreateToolhelp32Snapshot",
	"CloseToolhelp32Snapshot",
	"GetLastToolHelpError",
#	"Heap32First",
#	"Heap32Next",
#	"Heap32ListFirst",
#	"Heap32ListNext",
	"Module32First",
	"Module32Next",
	"Process32First",
	"Process32Next",
	"SetLastToolHelpError",
	"Thread32First",
	"Thread32Next",
	"Toolhelp32ReadProcessMemory"
);

sub speak { printf "\n%-70s", @_; }
sub croak { printf "\n%-70s", @_; }

use Test;
speak "plan tests: "; plan tests => scalar @tests + 1;

use Win32API::ToolHelp ':All';
speak "test use Win32API::ToolHelp ':All': "; ok 1;

my $result = 1;
foreach my $test (@tests) {
	speak "test $test: ";
	if (eval "Test$test") {
		ok 1;
	} else {
		croak "  GetLastToolHelpError() returned \"" . GetLastToolHelpError . "\"";
		ok 0;
		$result = 0;
	}
}
speak "summarize tests: "; print $result ? "success" : "failure", "\n";


sub TestCreateToolhelp32Snapshot {
	my ($result, $handle);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result\"";
	if (!$result) { return 0; }

	1
}


sub TestCloseToolhelp32Snapshot {
	my ($result, $handle);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result\"";
	if (!$result) { return 0; }

	$result = CloseToolhelp32Snapshot(0);
	croak "  CloseToolhelp32Snapshot(0) returned \"$result\"";
	if ($result) { return 0; }

	$result = CloseToolhelp32Snapshot(0xffffffff);
	croak "  CloseToolhelp32Snapshot(0xffffffff) returned \"$result\"";
	if ($result) { return 0; }

	1
}


sub TestGetLastToolHelpError {
	my ($result, $handle, $error);

	SetLastToolHelpError(0);
	croak "  SetLastToolHelpError(0) called";

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result\"";
	if (!$result) { return 0; }

	$error = GetLastToolHelpError();
	croak "  GetLastToolHelpError() returned \"$error\"";
	if ($error != 0) { return 0; }

	$result = CloseToolhelp32Snapshot(0);
	croak "  CloseToolhelp32Snapshot(0) returned \"$result\"";
	if ($result) { return 0; }

	$error = GetLastToolHelpError();
	croak "  GetLastToolHelpError() returned \"$error\"";
	if ($error == 0) { return 0; }

	1
}


sub TestHeap32First {
	my ($result, $handle, $hl, $he, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, $$);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPHEAPLIST, $$) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Heap32ListFirst($handle, $hl);
	croak "  Heap32ListFirst($handle, \$hl) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = Heap32First($he, $$, $hl->{th32HeapID});
	croak "  Heap32First(\$he, $$, $hl->{th32HeapID}) returned \"$result\"";
	if (!$result) { return 0; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestHeap32Next {
	my ($result, $handle, $hl, $he, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, $$);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPHEAPLIST, $$) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Heap32ListFirst($handle, $hl);
	croak "  Heap32ListFirst($handle, \$hl) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = Heap32First($he, $$, $hl->{th32HeapID});
	croak "  Heap32First(\$he, $$, $hl->{th32HeapID}) returned \"$result\"";
	if (!$result) { return 0; }

	$result = Heap32Next($he, $$, $hl->{th32HeapID});
	croak "  Heap32Next(\$he, $$, $hl->{th32HeapID}) returned \"$result\"";
	if (!$result) { return 0; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestHeap32ListFirst {
	my ($result, $handle, $hl, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, $$);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPHEAPLIST, $$) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Heap32ListFirst($handle, $hl);
	croak "  Heap32ListFirst($handle, \$hl) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestHeap32ListNext {
	my ($result, $handle, $hl, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, $$);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPHEAPLIST, $$) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Heap32ListFirst($handle, $hl);
	croak "  Heap32ListFirst($handle, \$hl) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = Heap32ListNext($handle, $hl);
	croak "  Heap32ListNext($handle, \$hl) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result2) { return 0; }

	$result
}


sub TestModule32First {
	my ($result, $handle, $me, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, $$);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, $$) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Module32First($handle, $me);
	croak "  Module32First($handle, \$me) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestModule32Next {
	my ($result, $handle, $me, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, $$);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, $$) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Module32First($handle, $me);
	croak "  Module32First($handle, \$me) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = Module32Next($handle, $me);
	croak "  Module32Next($handle, \$me) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestProcess32First {
	my ($result, $handle, $me, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Process32First($handle, $me);
	croak "  Process32First($handle, \$me) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestProcess32Next {
	my ($result, $handle, $me, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Process32First($handle, $me);
	croak "  Process32First($handle, \$me) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = Process32Next($handle, $me);
	croak "  Process32Next($handle, \$me) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestSetLastToolHelpError {
	my ($error);

	SetLastToolHelpError(0);
	croak "  SetLastToolHelpError(0) called";

	$error = GetLastToolHelpError();
	croak "  GetLastToolHelpError() returned \"$error\"";
	if ($error != 0) { return 0; }

	SetLastToolHelpError(6);
	croak "  SetLastToolHelpError(6) called";

	$error = GetLastToolHelpError();
	croak "  GetLastToolHelpError() returned \"$error\"";
	if ($error != 6) { return 0; }

	1
}


sub TestThread32First {
	my ($result, $handle, $te, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, $$);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, $$) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Thread32First($handle, $te);
	croak "  Thread32First($handle, \$te) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestThread32Next {
	my ($result, $handle, $te, $result2);

	$handle = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, $$);
	croak "  CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, $$) returned \"$handle\"";
	if ($handle == 0 || $handle == 0xffffffff) { return 0; }

	$result = Thread32First($handle, $te);
	croak "  Thread32First($handle, \$te) returned \"$result\"";
	if (!$result) { goto EXIT; }

	$result = Thread32Next($handle, $te);
	croak "  Thread32Next($handle, \$te) returned \"$result\"";
	if (!$result) { goto EXIT; }
EXIT:
	$result2 = CloseToolhelp32Snapshot($handle);
	croak "  CloseToolhelp32Snapshot($handle) returned \"$result2\"";
	if (!$result) { return 0; }

	$result
}


sub TestToolhelp32ReadProcessMemory {
	my ($result, $buf);

	$result = Toolhelp32ReadProcessMemory($$, 0, $buf, 4);
	croak "  Toolhelp32ReadProcessMemory($$, 0, \$buf, 4) returned \"$result\"";
	if (!$result) { return 0; }

	1
}
