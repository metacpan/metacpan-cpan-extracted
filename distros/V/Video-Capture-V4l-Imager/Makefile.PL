######################################################################
# Makefile.PL for Video::Capture::V4l::Imager
# 2007, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Video::Capture::V4l::Imager',
    'VERSION_FROM' => 'lib/Video/Capture/V4l/Imager.pm', # finds $VERSION
    'PREREQ_PM'    => { "Imager"              => 0.49,
                        "Video::Capture::V4l" => 0.9,
                        "Inline::C"           => 0.44,
                        "Log::Log4perl"       => 1.06,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Video/Capture/V4l/Imager.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
