use ExtUtils::MakeMaker;

# If we are on platforms other than Windows,
# exit now. This should play nice for CPAN testers.
my $running_on_windows = $^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys';
# So I can build it on Linux too
die qq(OS unsupported\n) unless $running_on_windows or $ENV{WIN32_API_BUILD};

WriteMakefile(
    NAME              => 'Win32::ExeAsDll',
    VERSION_FROM      => 'lib/Win32/ExeAsDll.pm',
    PREREQ_PM         => {},
    TEST_REQUIRES     => {'Win32::API' => 0.84},
    ABSTRACT_FROM     => 'lib/Win32/ExeAsDll.pm',
    AUTHOR            => 'Daniel Dragan <bulkdd@cpan.org>',
    LICENSE           => 'perl',
    PL_FILES          => {},
    clean => {FILES => "*.bak *.obj *.o *.pdb tmp*"}
    # dynamic_lib => {OTHERLDFLAGS => ' --enable-stdcall-fixup '},
);

package MY; #subs below use SUPER::, subs above use main:: vars
sub cflags {
    my($self) = shift;
    my $dlib = $self->SUPER::cflags(@_);
    #$dlib =~ s/-O1/ -O2 -Gy -GL -Os/;
    #$dlib =~ s/-O1/ -Od/;
    my $pos = index($dlib,'CCFLAGS = ',0);
    die "bad CCFLAGS match" if $pos == -1;
    my $len = $pos+length('CCFLAGS = ');
    $dlib = substr($dlib, 0, $len)
        #.' --enable-stdcall-fixup '
        #.' -Wdeclaration-after-statement '
        .substr($dlib, $len, length($dlib)-$len);
    #$dlib =~ s/(^OPTIMIZE = .+)$/$1 ${\main::no_stackprotector()}/m;
    return $dlib;
}
