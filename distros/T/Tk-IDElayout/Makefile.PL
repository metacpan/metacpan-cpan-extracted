use 5.6.0;
use Cwd;
use Config;
no  lib '.';
use ExtUtils::MakeMaker;
BEGIN {

    warn("### Note: 'Building Outside of Tk itself' Messages are Expected Here ####\n");

    $IsWin32 = ($^O eq 'MSWin32' || $Config{'ccflags'} =~ /-D_?WIN32_?/);

    $VERSION = '0.37';
    $win_arch = shift @ARGV if @ARGV and $ARGV[0] =~ /^(open32|pm|x|MSWin32)$/;
    require('fix_4_os2.pl'), OS2_massage() if $^O eq 'os2';

    # Currently 'x', 'pm', 'open32', 'MSWin32'
    $win_arch = ($IsWin32) ? 'MSWin32' : 'x' if not defined $win_arch;

    eval { require './myConfig'; 1; };
    if( $@ ){
        warn $@;
        print STDERR "\n#### Error requiring 'myConfig': Perhaps you don't have Tk installed ###\n";
        print STDERR   "####  This module requires a Tk installation                         ###\n";

        # Write out a simple makefile with PREREQ_PM, so CPAN will at least detect our
        #   prerequisites.
        WriteMakefile(
            'VERSION_FROM'  => 'IDElayout.pm',
            'NAME'     => 'Tk::IDElayout',
            'DISTNAME' => "Tk-IDElayout",
            # XXX: duplicated below in TkExtMakefile()
            'LICENSE'  => 'perl_5',
            'META_MERGE' => {
                'meta-spec' => { version => 2 },
                no_index => {
                    'package' => [ 'Tk', 'Tk::CaptureRelease' ],
                },
                resources => {
                    repository => {
                        type => 'git',
                        url => 'https://github.com/asb-capfan/Tk-IDElayout.git',
                        web => 'https://github.com/asb-capfan/Tk-IDElayout',
                    },
                    bugtracker => {
                        web => 'https://github.com/asb-capfan/Tk-IDElayout/issues',
                    },
                },
            },
            'PREREQ_PM'  => {
                'Tk' => '804.027',
                'Tk::DynaTabFrame' => '0.23',
                'Graph' => '0.50',
            },
        );
        exit();
    }

  # use lib ($Tk::MMutil::dir=getcwd);

} # /BEGIN

use Tk::MMutil;

# Path to the installed shared Tk library (needed on unix)
my $TkLibPath = ' ';

if ($IsWin32) {
    *MY::makeaperl = \&makeWin32perl;
    if ($Config{cc} =~ /^gcc/i) {
        @libs = ('');
    }
} else {
    # We need to link in the Tk Library on Unix (unless it is a Darwin/macOS
    # Mach-O bundle not meant for linking) to get TkpWmSetState and other symbols
    #    (These are exported in the TkintplatdeclsVptr in windows, but not on unix)
    $TkLibPath = Tk::MMutil::findINC('auto/Tk/Tk.'.$Config{dlext});
    if ($^O eq 'darwin') {
        # Check for MH_BUNDLE header fields (based on `struct mach_header` and
        # `struct mach_header_64` from <mach-o/loader.h>):
        #    - magic    (uint32_t at bytes 0 to 4)
        #    - filetype (uint32_t at bytes 12 to 15)
        my $MH_MAGIC    = 0xfeedface;
        my $MH_CIGAM    = 0xcefaedfe;
        my $MH_MAGIC_64 = 0xfeedfacf;
        my $MH_CIGAM_64 = 0xcffaedfe;
        my $MH_BUNDLE   = 0x8;
        open my $TkLibFH, '<:raw', $TkLibPath;
        my $header_size = read $TkLibFH, my $header, 16;
        die "Couldn't read header of $TkLibPath" unless $header_size == 16;
        close $TkLibFH;
        my ($magic, $filetype) = unpack('L x8 L', $header);
        #printf("Got magic == 0x\%x, filetype == 0x\%x\n", $magic, $filetype);
        $TkLibPath = ' ' if (
            ($magic == $MH_MAGIC or
             $magic == $MH_CIGAM or
             $magic == $MH_MAGIC_64 or
             $magic == $MH_CIGAM_64)
            and ($filetype == $MH_BUNDLE));
    }

    my $plibs = $Config{'libs'};
    my $libs  = "$xlib -lX11";   # Used to have -lpt in here as well.
    my @try   = qw(-lsocket -lnsl -lm);
    push(@try,'-lc') if $^O eq 'svr4';
    my $lib;
    # perl needs sockets and math library too
    # so only include these if they made it through perl's Configure
    foreach $lib (@try) {
        $libs .= " $lib" if ($plibs =~ /$lib\b/);
    }
    @libs = ("$libs");
}

my $dir = Tk::MMutil::find_subdir();
delete $dir->{'pTk'};

# Find path to existing pTk include files
my $ptkPath = Tk::MMutil::findINC('Tk/pTk/Lang.h');
$ptkPath =~ s/\/Lang\.h$//g;



Tk::MMutil::TkExtMakefile(
    'VERSION'  => $VERSION,
    'XS_VERSION' => $VERSION,
    'EXE_FILES' => [],
    'NAME'     => 'Tk::CaptureRelease',
    # XXX: duplicated from WriteMakefile() above.
    'LICENSE'  => 'perl_5',
    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        no_index => {
            'package' => [ 'Tk', 'Tk::CaptureRelease' ],
        },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/asb-capfan/Tk-IDElayout.git',
                web => 'https://github.com/asb-capfan/Tk-IDElayout',
            },
            bugtracker => {
                web => 'https://github.com/asb-capfan/Tk-IDElayout/issues',
            },
        },
    },
    'DIR'      => [reverse(sort(keys %$dir))],
    'DISTNAME' => "Tk-IDElayout",
    'DEFINE'   => $mydefine,
    'INC'    => "-I$ptkPath",
    'LIBS'    => \@libs,
    'OBJECT'  => '$(O_FILES)'. " $TkLibPath", # Tk Lib path will be the Tk library on Unix, blank for win32
    'PREREQ_PM' => {
        'Tk' => '804.027',
        'Tk::DynaTabFrame' => '0.23',
        'Graph' => '0.50',
    },
    @macro,
);


sub MY::post_initialize {
    my ($self) = @_;
    my ($ret) = '';
    my %files = ();
    my $dir = $self->catdir('$(INST_ARCHLIBDIR)','Tk');
    my $name;
    foreach $name (grep /(%|\.q4|\.bck|\.old)$/,keys %{$self->{PM}}) {
        delete $self->{PM}->{$name};
    }
    # delete $self->{PM}->{'Tk/Config.pm'};
    # $self->{PM}->{'Tk/Config.pm'} = $self->catfile($dir,'Config.pm');
    # $files{'typemap'} = 1;
    foreach $name ($self->lsdir(".")) {
        next if ($name =~ /^\./);
        next unless (-f $name);
        $files{$name} = 1 if ($name =~ /\.[tm]$/);
        $files{$name} = 1 if ($name =~ /\.def$/);
    }
    foreach $name (sort(@{$self->{H}},keys %files)) {
        $self->{PM}->{$name} = $self->catfile($dir,$name);
    }
    $ret;
}

sub needs_Test {
    my $file = shift;
    local $_;
    unless (open(TFILE,"$file")) {
        warn "Cannot open $file:$!";
        return 1;
    }
    my $code = 0;
    while (<TFILE>) {
        last if ($code = /^\s*(use|require)\s+Test\b/);
    }
    close(TFILE);
    warn "Skipping test $file needs 'Test.pm':$_" if $code;
    return $code;
}

sub MY::test {
    my ($self,%attrib) = @_;
    my @tests = sort glob($self->catfile('t','*.t'));
    eval { require Test };
    if ($@) {
        @tests = grep(!needs_Test($_),@tests);
    }
    $attrib{'TESTS'} = join(' ',@tests);

    # Temporarily remove sub-dirs from $self as we 'know'
    # there are no tests down there
    my $dir  = delete $self->{'DIR'};
    my $str  = $self->MM::test(%attrib);
    # Put sub-dirs back
    $self->{'DIR'} = $dir;
    return $str;
}

sub MY::postamble {
    '


Makefile     : myConfig

perlmain.c : config Makefile

basic      : $(INST_DYNAMIC) pm_to_blib

MANIFEST : MANIFEST.SKIP $(FIRST_MAKEFILE)
	$(MAKE) manifest

';
}
