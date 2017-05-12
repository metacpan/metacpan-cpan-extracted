use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'WWW::Postini',
    VERSION_FROM      => 'lib/WWW/Postini.pm', # finds $VERSION
    PREREQ_PM         => {

                           Crypt::SSLeay    => 0,
                           Exception::Class => 0,
                           Exporter         => 0,
                           HTML::TokeParser => 0,
                           HTTP::Cookies    => 0,
                           HTTP::Request    => 0,
                           HTTP::Status     => 0,
                           LWP::UserAgent   => 0,
                           URI::Escape      => 0

    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Postini.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Guzis <pguzis@cpan.org>') : ()),
);