#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Path qw(make_path);

# --- Environment Detection ---
my $is_cygwin  = ($^O eq 'cygwin');
my $is_windows = ($^O eq 'MSWin32');

unless ($is_windows) 
    {
    # create the source file if absent to force Make to treat bin, 
    if (! -f 'tstregex') 
        {
        print "Creation du proxy Tstregex pour Linux...\n";
        open my $fh, '>', 'tstregex' or die $!;
        print $fh "#!/usr/bin/perl\nuse Tstregex;\n main( scalar \@ARGV, \\\@ARGV );\n";
        close $fh;
        chmod 0755, 'tstregex';
        }
    }

# --- Pre-configuration: Windows Launcher ---
# If we are on pure Windows, we create a small .bat wrapper 
# that points to the .pm engine in the lib folder.
if ($is_windows) 
    {
    make_path('bin') unless -d 'bin';
    print "Windows detected: Creating launcher bin/tstregex.bat...\n";
    open my $fh, '>', 'bin/tstregex.bat' or die "Could not create bat file: $!";
    
    # use standard syntax of Windows CPAN wrappers,
    # to avoid perl trying to compil the batch itself
    print $fh '@rem = ', "'--*- Perl -*--'\n";
    print $fh '@echo off',"\n";
    print $fh 'perl -I"%~dp0..\lib" "%~dp0..\lib\tstregex.pm" %*' . "\n";
    print $fh "goto endofperl\n";
    print $fh "';\n"; # End of fake for Perl
    print $fh "############### Fin du Batch ###############\n";
    print $fh ":endofperl\n";
    close $fh;
    }
    
my %WriteMakefileArgs = 
    (
    NAME             => 'Tstregex',
    AUTHOR           => 'Olivier Delouya <olivier_delouya@hotmail.com>',
    # Source of truth is now in lib/
    VERSION_FROM     => 'lib/Tstregex.pm', 
    ABSTRACT_FROM    => 'lib/Tstregex.pm', 
    LICENSE          => 'artistic_2',
    META_MERGE       => 
        {
        'meta-spec' => { version => 2 },
        resources   => 
            {
            repository => 
                {
                type => 'git',
                url  => 'https://github.com/odjectif/tstregex.git',
                web  => 'https://github.com/odjectif/tstregex',
                },
            },
        },
    
    # Under Windows, we install the .bat. Under Unix/Cygwin, 
    # we don't need a physical file in bin/ yet (handled by symlink).
    EXE_FILES        => [ $is_windows ? 'bin/tstregex.bat' : 'tstregex' ],    
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => 
        {
        'Term::ANSIColor' => 0,
        'Time::HiRes'     => 0,
        },
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    # Clean up the generated .bat and build artifacts
    clean            => { FILES => 'tstregex-* MYMETA.* blib* bin/tstregex.bat' },
    );

if ($is_windows) 
    {
    $WriteMakefileArgs{PREREQ_PM}->{'Win32::Console::ANSI'} = 0;
    }

WriteMakefile(%WriteMakefileArgs);
   
sub MY::postamble {
    my $res = '';

    # Post-install: Create the symlink tstregex -> lib/Tstregex.pm
    unless ($is_windows) {
        $res .= <<'MAKE_FRAG';
pure_all ::
	@echo "Normalizing line endings in blib/script/Tstregex.pm..."
	$(PERL) -pi -e 's/\r//g' lib/Tstregex.pm

install ::
    # On Unix/Cygwin, create a direct symlink to the .pm engine.
	@echo "Creating symlink in $(DESTDIR)$(INSTALLSCRIPT)..."
	#ensure bin dir exists
	$(MKPATH) $(DESTDIR)$(INSTALLSCRIPT)
	#supress old stub
	$(RM_F) $(DESTDIR)$(INSTALLSCRIPT)/tstregex
	# Use absolute paths via MakeMaker variables to avoid dandling links
	ln -sfv $(DESTDIR)$(INSTALLSITELIB)/Tstregex.pm $(DESTDIR)$(INSTALLSCRIPT)/tstregex
	chmod +x $(DESTDIR)$(INSTALLSCRIPT)/tstregex $(DESTDIR)$(INSTALLSITELIB)/Tstregex.pm
MAKE_FRAG
    }

    # SUPERCLEAN rule : the big clean 
    $res .= <<'MAKE_FRAG';

superclean :: veryclean
	@echo "The big clean (Superclean)..."
	$(RM_RF) bin none
	$(RM_F) Makefile.old MANIFEST.bak MYMETA.json MYMETA.yml pm_to_blib
MAKE_FRAG

    return $res;
}
    

# Status messages
if ($is_cygwin) 
    {
    print "\n" . "=" x 60 . "\n";
    print "CYGWIN ENVIRONMENT DETECTED:\n";
    print "Symlink 'tstregex' will be created during 'make install'.\n";
    print "=" x 60 . "\n\n";
    }
elsif ($is_windows) 
    {
    print "\n" . "=" x 60 . "\n";
    print "WINDOWS ENVIRONMENT DETECTED:\n";
    print "Launcher 'tstregex.bat' created in bin/ and ready for install.\n";
    print "=" x 60 . "\n\n";
    }
else 
    {
    print "\n" . "=" x 60 . "\n";
    print "UNIX/LINUX ENVIRONMENT DETECTED:\n";
    print "Symlink created: tstregex -> Tstregex.pm\n";
    print "Line endings normalized (LF).\n";
    print "=" x 60 . "\n\n";
    }
1;
