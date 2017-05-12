use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XMLRPC::Transport::HTTP::Server',
    AUTHOR              => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM        => 'lib/XMLRPC/Transport/HTTP/Server.pm',
    ABSTRACT_FROM       => 'lib/XMLRPC/Transport/HTTP/Server.pm',
    (! eval { ExtUtils::MakeMaker->VERSION(6.3002) } ? () :
        (LICENSE => 'perl')
    ),
    (eval { ExtUtils::MakeMaker->VERSION(6.5503) } ?
    (
        BUILD_REQUIRES => {
            'Test::More' => 0,
            'SOAP::Transport::HTTP' => 0.71,
            'XMLRPC::Lite' => 0.71,
            'XMLRPC::Transport::HTTP' => 0.71,
        },
        PREREQ_PM => {
            'SOAP::Transport::HTTP' => 0.71,
            'XMLRPC::Lite' => 0.71,
            'XMLRPC::Transport::HTTP' => 0.71,
        }
    ) : (
        PREREQ_PM => {
            'Test::More' => 0,
            'SOAP::Transport::HTTP' => 0.71,
            'XMLRPC::Lite' => 0.71,
            'XMLRPC::Transport::HTTP' => 0.71,
        }
    )),
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'http://github.com/jelu/xmlrpc-transport-http-server/wiki',
                repository => 'http://github.com/jelu/xmlrpc-transport-http-server',
                bugtracker => 'http://github.com/jelu/xmlrpc-transport-http-server/issues',
            },
        })
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XMLRPC-Transport-HTTP-Server-*' },
);
