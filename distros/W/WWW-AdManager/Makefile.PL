use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'WWW::AdManager',
    VERSION_FROM	=> 'AdManager.pm',
    PREREQ_PM           => {
        CGI_Lite                => undef,
        File::Path              => undef,
        TempDir                 => undef,
        Data::Dumper            => undef,
        IO::File                => undef,
        IO::Dir                 => undef,
        Fcntl                   => undef,
        HTML::Entities          => undef,
        URI                     => undef,
        Image::Size             => undef,
        LWP::Simple             => undef,
        Apache::Constants       => undef,
    },
);
