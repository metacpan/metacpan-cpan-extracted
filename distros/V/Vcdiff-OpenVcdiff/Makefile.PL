use strict;

use ExtUtils::MakeMaker;


use Alien::OpenVcdiff;
 
my $openvcdiff = Alien::OpenVcdiff->new;
 
my $libs = $openvcdiff->libs;
my $cflags = $openvcdiff->cflags;

## Hack: Alien::Base is returning one directory too deep
## for the include path we need...
$cflags =~ s{(-I\S+)/google\b}{$1/};


my %args = (
    NAME              => 'Vcdiff::OpenVcdiff',
    VERSION_FROM      => 'lib/Vcdiff/OpenVcdiff.pm',
    XSOPT             => '-C++',
    CC                => 'g++',
    CCFLAGS           => $cflags,
    LIBS              => $libs,
    PREREQ_PM => {
      'Alien::OpenVcdiff' => 0,
      'Vcdiff' => '0.505',
      'Sys::Mmap' => 0,
      'Guard' => 0,
      'Carp' => 0,
    },
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => 0,
      'Alien::OpenVcdiff' => 0,
    },
    BUILD_REQUIRES => {
      'ExtUtils::MakeMaker' => 0,
      'Alien::OpenVcdiff' => 0,
    },
    OBJECT            => 'Interface.o',
    LICENSE           => 'perl',
    dist => {
      PREOP => 'perldoc -uT $(VERSION_FROM) > README.pod; pod2text README.pod > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Vcdiff-OpenVcdiff.git',
            bugtracker => 'https://github.com/hoytech/Vcdiff-OpenVcdiff/issues',
        },
    };
}

WriteMakefile(%args);
