use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $PreReq = {};

if ( "\L$^O" =~ m/win32/ )
	{
	if (Win32::IsWinNT())
		{ $PreReq->{'Win32::EventLog'} = 0; };
	}
else
	{ $PreReq->{'Unix::Syslog'} = 0.01; };

$PreReq->{'Carp'}           = 0;
$PreReq->{'IO::File'}       = 0;
$PreReq->{'POSIX'}          = 0;
$PreReq->{'File::Path'}     = 0;
$PreReq->{'File::Basename'} = 0;

WriteMakefile(
    'NAME'		=> 'UniLog',
    'VERSION_FROM'	=> 'UniLog.pm', # finds $VERSION
    'PREREQ_PM'		=> $PreReq, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'UniLog.pm', # retrieve abstract from module
       AUTHOR     => 'Daniel Podolsky <tpaba@cpan.org>') : ()),
);
