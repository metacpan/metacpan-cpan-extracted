######################################################################
# Makefile.PL for ZWave::Protocol
# 2015, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mschilli/zwave-protocol.git',
        },
    }
};

WriteMakefile(
    'NAME'         => 'ZWave::Protocol',
    'VERSION_FROM' => 'lib/ZWave/Protocol.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Moo                => 1.006,
        Log::Log4perl      => 1,
        Device::SerialPort => 1.04,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/ZWave/Protocol.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
