use 5.006004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $preop = 'find $(DISTVNAME) -type f -exec egrep -q Build V1.007 {} \; -exec sed -i "s/___EUMM_VERSION___/Build V$(VERSION)/" {} \; -print ;' .
'perldoc -uT $(DISTVNAME)/$(VERSION_FROM) > README.pod';

WriteMakefile(
    NAME              => 'Tk::DBI::LoginDialog',
    MIN_PERL_VERSION => '5.010001',
    LICENSE           => 'gpl_2',
    VERSION_FROM      => 'lib/Tk/DBI/LoginDialog.pm', # finds $VERSION
    BUILD_REQUIRES    => {
        'Test::More' => '0',
    },
    PREREQ_PM         => {
        'Carp' => '0',
        'Data::Dumper' => '0',
        'DBI' => '1.58',
        'Log::Log4perl' => '0',
        'Tk' => '800.024',
        'Tk::DialogBox' => '0',
        'Tk::BrowseEntry' => '0',
        'Tk::Label' => '0',
        'Tk::Entry' => '0',
        'Tk::ROText' => '0',
    }, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/DBI/LoginDialog.pm', # retrieve abstract from module
	AUTHOR        => 'tmcmeeki <tmcmeeki@cpan.org>') : ()),
        dist => { PREOP => $preop, },
);
