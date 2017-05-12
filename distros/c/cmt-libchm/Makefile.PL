use 5.008;
use ExtUtils::MakeMaker;

my $DIRT_HOME=$ENV{DIRT_HOME};

push @ARGV, "PREFIX=$DIRT_HOME/0"
    if -f "$DIRT_HOME/.dirt";

my $INCLUDE = join ' ', map { $_ ne '' ? "-I$_" : '' }
                split(/\s*;\s*/, $ENV{INCLUDE});
my $LIB     = join ' ', map { $_ ne '' ? "-L$_" : ''  }
                split(/\s*;\s*/, $ENV{LIB});

WriteMakefile(
    NAME              => 'cmt::libchm',
    VERSION_FROM      => 'lib/cmt/libchm.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/cmt/libchm.pm', # retrieve abstract from module
       AUTHOR         => 'Xima Lenik <lenik@bodz.net>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Ichmlib', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(CHM_COMPRESSED CHM_ENUMERATE_ALL CHM_ENUMERATE_DIRS
		 CHM_ENUMERATE_FILES CHM_ENUMERATE_META CHM_ENUMERATE_NORMAL
		 CHM_ENUMERATE_SPECIAL CHM_ENUMERATOR_CONTINUE
		 CHM_ENUMERATOR_FAILURE CHM_ENUMERATOR_SUCCESS CHM_MAX_PATHLEN
		 CHM_PARAM_MAX_BLOCKS_CACHED CHM_RESOLVE_FAILURE
		 CHM_RESOLVE_SUCCESS CHM_UNCOMPRESSED));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'cmt::libchm',
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

sub MY::postambles {'
'}
