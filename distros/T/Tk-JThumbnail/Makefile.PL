use 5.028001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::JThumbnail',
    VERSION_FROM      => 'lib/Tk/JThumbnail.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Tk'          => '0',
        'Tk::JPEG'    => '0',
        'Tk::PNG'     => '0',
        'File::Basename' => '0'
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Tk/JThumbnail.pm', # retrieve abstract from module
    AUTHOR            => 'Jim Turner <turnerjw784@yahoo.com>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
