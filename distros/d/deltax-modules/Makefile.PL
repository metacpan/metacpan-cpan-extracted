use ExtUtils::MakeMaker qw/prompt/;
use ExtUtils::MakeMaker;
# Configuration for Database and Session tests

print <<ENT;

*** Tests configuration questions ***

This package includes DeltaX::Database and DeltaX::Session modules, which - for
full tests - need functional database connection.
Two test tables will be created and dropped, no other objects will be touched.
Please, give me some information for tests...

ENT

my $do_tests = prompt("Do you want to setup database tests [y/n]?", "n");
if (lc($do_tests) ne 'y') {
	print "\n*** Database tests will be skipped ***\n\n";
}
else {
	open OUF, ">t/.dbconf" or die "cannot write to t/.dbconf ?!";

	#---------------------------------------------------------------------
	my $answer = prompt("Database driver [Oracle|Pg|MySQL|Informix|DB2|Solid|MSSQL]", "Pg");
	if (lc($answer) eq 'oracle') {
		print OUF "Oracle\n";
	}
	elsif (lc($answer) eq 'pg') {
		print OUF "Pg\n";
	}
	elsif (lc($answer) eq 'mysql') {
		print OUF "mysql\n";
	}
	elsif (lc($answer) eq 'informix') {
		print OUF "Informix\n";
	}
	elsif (lc($answer) eq 'db2') {
		print OUF "DB2\n";
	}
	elsif (lc($answer) eq 'solid') {
		print OUF "Solid\n";
	}
	elsif (lc($answer) eq 'mssql') {
		print OUF "mssql\n";
	}
	else {
		die "Sorry, unknown driver";
	}
	#---------------------------------------------------------------------
	$answer = prompt("Database host name", "");
	print OUF $answer, "\n";
	#---------------------------------------------------------------------
	$answer = prompt("Database name", "test");
	print OUF $answer, "\n";
	#---------------------------------------------------------------------
	$answer = prompt("Database user", "test");
	print OUF $answer, "\n";
	#---------------------------------------------------------------------
	$answer = prompt("Database password", "");
	print OUF $answer, "\n";

	close OUF;

	print "\n*** Thank you ***\n\n";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'DeltaX',
	'VERSION_FROM' => 'DeltaX/Database.pm',
	'PREREQ_PM'		=> {
		DBI => 0,
		Time::HiRes => 0,
		GDBM_File => 0
	}, # e.g., Module::Name => 1.1
	realclean => { FILES => 't/.dbconf'}
);
