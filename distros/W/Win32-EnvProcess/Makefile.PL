use 5.006001;
use ExtUtils::MakeMaker;

package MY;
use Config;

sub postamble {

    # Which compiler?
    if ($Config{cc} eq 'gcc') {
    
        return <<'MAKE_GNU_FRAG';
 
Dll: EnvProcessDll.c
	$(CC) -c EnvProcessDll.c 
	$(CC) -shared -o .\$(INST_ARCHLIB)\auto\$(FULLEXT)\EnvProcessDll.$(SO) EnvProcessDll.o
MAKE_GNU_FRAG

    }
    else {
        
        return <<'MAKE_FRAG';
 
Dll: EnvProcessDll.c
	$(CC) $(CCFLAGS) EnvProcessDll.c  /link /OUT:.\$(INST_ARCHLIB)\auto\$(FULLEXT)\EnvProcessDll.$(SO) -dll
        if exist EnvProcessDll.manifest mt.exe -nologo -manifest EnvProcessDll.manifest -outputresource:EnvProcessDll;2
MAKE_FRAG

    }
}

sub top_targets {
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited =~ s/(\npure_all\s+::.+)/$1 Dll/;
  return $inherited;
}

1;

package main;

die 'OS unsupported' if $^O ne 'MSWin32';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::EnvProcess',
    VERSION_FROM      => 'lib/Win32/EnvProcess.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Win32/EnvProcess.pm', # retrieve abstract from module
       AUTHOR         => 'C. B. Darke <clive.darke@talk21.com>') : ()),
    LIBS              => [ ], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Win32::EnvProcess',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

1;

