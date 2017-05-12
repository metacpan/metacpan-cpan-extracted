use ExtUtils::MakeMaker;
use File::Copy;

if ( $^O =~ /cygwin|MSWin32/ ) {
    copy 'xs/VersionInfo.xs' => 'VersionInfo.xs';
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Win32::File::VersionInfo',
    'VERSION_FROM' => 'VersionInfo.pm',            # finds $VERSION
    'PREREQ_PM'    => {},                          # e.g., Module::Name => 1.1
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT_FROM => 'VersionInfo.pm', # retrieve abstract from module
            AUTHOR => 'Alexey Toptygin <alexeyt@cpan.org>'
            )
        : ()
    ),
    (   $^O eq 'cygwin' ? ( 'MYEXTLIB' => "/usr/lib/w32api/libversion.a" )
        : ()
    ),
    'DEFINE' => '',   # e.g., '-DHAVE_SOMETHING'
                      # Insert -I. if you add *.h files later:
    'INC'    => '',   # e.g., '-I/usr/include/other'
                      # Un-comment this if you add C files to link with later:
                      # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
