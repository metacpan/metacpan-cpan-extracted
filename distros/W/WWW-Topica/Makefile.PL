use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'WWW::Topica',
    'VERSION_FROM' => 'lib/WWW/Topica.pm', 
    'PREREQ_PM'    => { 
                        'Carp' => 0, 
                        'Date::Parse' => 0,
						'Email::Date' => 0,
                        'Email::Simple' => 0,
                        'Email::Simple::Creator' => 0,
                        'Email::LocalDelivery' => 0, 
                        'File::Basename' => 0,
						'HTML::Scrubber' => 0,
                        'LWP::UserAgent' => 0, 
                        'Time::Piece' => 0,
                        'URI'         => 0,
                      },
    'EXE_FILES'    => [ 'bin/topica2mail' ],
);

