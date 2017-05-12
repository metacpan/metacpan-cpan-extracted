use ExtUtils::MakeMaker;
WriteMakefile( 'NAME' => 'TheSchwartz::Worker::SendEmail',
               'VERSION_FROM' => 'lib/TheSchwartz/Worker/SendEmail.pm',
               'PREREQ_PM'    => {
                   'TheSchwartz::Worker' => 0,
                   'Net::DNS'            => 0,
                   'Storable'            => 0,
                   'Net::SMTP'           => 0,
                   'Net::Config'         => 0,
                   'Net::Cmd'            => 0,
               },
               ABSTRACT_FROM => 'lib/TheSchwartz/Worker/SendEmail.pm',
               AUTHOR     => 'Brad Fitzpatrick <brad@danga.com>',
               );


