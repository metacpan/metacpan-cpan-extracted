use ExtUtils::MakeMaker;
my %options = %{ {
    NAME          => 'cppAdaptive2',
    VERSION_FROM  => 'lib/cppAdaptive2.pm',
    ABSTRACT_FROM => 'lib/cppAdaptive2.pm',
    'LIBS'        => ['-lstdc++'],
    'TYPEMAPS'    => ['CPP.map'],
    'INC'         => '-I./src/',
    'CC'          => 'g++ -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -xc++',

    # 'CC'          => 'g++ -std=c++11 -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_FORTIFY_SOURCE=2 -xc++',
    'CCFLAGS' => ' -std=c++14 -w',
} };

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile {''}
