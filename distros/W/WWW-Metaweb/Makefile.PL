use 5.008006;
use ExtUtils::MakeMaker;


# Check for freebase user/password in ENV for extended testing.
if (length $ENV{FREEBASE_USER} > 0 && length $ENV{FREEBASE_PASS} > 0)  {
        print qq{
The Metaweb tests will use these values for a Freebase test:
    FREEBASE_USER=$ENV{FREEBASE_USER}
    FREEBASE_PASS=$ENV{FREEBASE_PASS}

This will cause a new object to be created on the Freebase sandbox (usually reset weekly), which contains the version of WWW::Metaweb being used and the current system UNIX time.
Due to the nature of Freebase this object can be traced back to the user who created it (the one above). If you are uncomfortable with this - remove the environment variable before continueing.

};
}
else  {
        print qq{
Metaweb can use Freebase credentials to test read/write queries.
Set the environment variables FREEBASE_USER & FREEBASE_PASS to use these tests.

};
}

WriteMakefile(
    NAME              => 'WWW::Metaweb',
    VERSION_FROM      => 'lib/WWW/Metaweb.pm', # finds $VERSION
    PREREQ_PM         => {
	Test::Simple => 0.40, # For testing of course.
	Carp => 1.03,
	JSON::XS => 1.5,
	LWP::UserAgent => 2.033,
	URI::Escape => 3.2,
	HTTP::Request => 1.4
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Metaweb.pm', # retrieve abstract from module
       AUTHOR         => 'Hayden Stainsby <hds@cpan.org>') : ()),
);
