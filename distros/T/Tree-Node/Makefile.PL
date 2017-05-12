use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Tree::Node',
    VERSION_FROM      => 'lib/Tree/Node.pm',
    PREREQ_PM         => {
      'base'                           => 0,
      'File::Copy'                     => 0,
      'File::Spec'                     => 0,
      'Test::More'                     => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tree/Node.pm', # retrieve abstract from module
       AUTHOR         => 'Robert Rothenberg <rrwo at cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)',
);
if  (eval {require ExtUtils::Constant; 1}) {
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Tree::Node',
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
