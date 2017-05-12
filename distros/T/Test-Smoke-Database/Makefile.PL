use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %make = (
    'NAME'		=> 'Test::Smoke::Database',
    'VERSION_FROM'	=> 'lib/Test/Smoke/Database.pm', # finds $VERSION
    'PREREQ_PM'		=> {'DBI' => 0,
			    'CGI' => 0,
			    'News::NNTPClient' =>0,
			    'Data::Dumper'=>0,
			    'DBD::mysql'=>0,
			    'Test::More'=>0
#		    	    'GD::Graph'=>0 not mandatory
			   },
    'EXE_FILES'         => [ 'bin/admin_smokedb' ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Add / parse / view perl reports smoke database', 
      AUTHOR     => 'alian <alian@cpan.org>') : ()),
);

my $tes = prompt("Do you want to do advanced tests ? ".
		 "(others than load tests)","no");
if ($tes ne 'no') {
  my $user = prompt("Mysql user to use ?","root"); #$ENV{USER});
  my $pass = prompt("Mysql password for this user ?");
  my $db = prompt("Database for test?", "test");
  open(FILE,">.m") || warn "Can't create .m for test: $!\n";
  print FILE $user,"\t",$pass,"\t",$db;
  close FILE;
}

WriteMakefile(%make);

eval("use GD::Graph;");
print "\nDefault database used is smoke. (you must create it).
Database test will be used for test. Read the README.\n";
print "You doesn't seem to have GD::Graph. Install it by hand
if you want create graph.\n" if ($@);

