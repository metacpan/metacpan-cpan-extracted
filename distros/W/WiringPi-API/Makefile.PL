use warnings;
use strict;

use ExtUtils::MakeMaker;
use version;

my $min_wpi_ver = 2.36;

if (! -f '/usr/include/wiringPi.h' && ! -f '/usr/local/include/wiringPi.h'){
    print "wiringPi is not installed, exiting...\n";
    exit;
}

if (my $path = (grep { -x "$_/gpio" } split /:/, $ENV{PATH})[0]){
    my $bin = "$path/gpio";
    my $gpio_info = `$bin -v`;

    if (my ($version) = $gpio_info =~ /version:\s+(\d+\.\d+)/){

        my $installed_ver = version->parse($version);

        if ($installed_ver < $min_wpi_ver){
            print "\nyou must have wiringPi version $min_wpi_ver" .
                  " or greater installed to continue.\n\n" .
                  "You have version $version\n";
            exit;
        }
    }
}
else {
    print "\ncan not determine wiringPi version. Ensure version 2.36+ " .
          " is installed. Can't continue\n";
    exit;
}

WriteMakefile(
    NAME              => 'WiringPi::API',
    VERSION_FROM      => 'lib/WiringPi/API.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WiringPi/API.pm',
       AUTHOR         => 'Steve Bertrand <steveb@cpan.org>') : ()),
    LIBS              => ['-lwiringPi -lwiringPiDev -lrt'],
    DEFINE            => '',
    INC               => '-I.',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/wiringpi-api/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/wiringpi-api.git',
                web => 'https://github.com/stevieb9/wiringpi-api',
            },
        },
    },
    MIN_PERL_VERSION  => 5.006,
    LICENSE           => 'perl_5',
    PREREQ_PM         => {
    },
);
