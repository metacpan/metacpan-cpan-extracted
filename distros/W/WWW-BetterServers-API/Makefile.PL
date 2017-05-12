use 5.010001;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME              => 'WWW::BetterServers::API',
              VERSION_FROM      => 'lib/WWW/BetterServers/API.pm',
              PREREQ_PM         => {Mojolicious     => 4.50,
                                    IO::Socket::SSL => 1.75},
              ABSTRACT_FROM     => 'lib/WWW/BetterServers/API.pm',
              AUTHOR            => 'Scott Wiersdorf <scott@betterservers.com>'
             );
