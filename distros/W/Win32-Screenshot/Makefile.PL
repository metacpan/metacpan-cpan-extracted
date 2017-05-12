use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Win32::Screenshot',
    VERSION_FROM      => 'Screenshot.pm',
    PREREQ_PM         => {
       Image::Magick => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'Screenshot.pm',
       AUTHOR         => 'P.Smejkal <petr.smejkal@seznam.cz>') : ()),
    LIBS              => ['comctl32.lib'],
    DEFINE            => '',
    INC               => '-I.',
);

if  (eval {require ExtUtils::Constant; 1}) {
  my @names = (qw(GW_CHILD GW_HWNDFIRST GW_HWNDLAST GW_HWNDNEXT GW_HWNDPREV
		 GW_OWNER SW_HIDE SW_MAXIMIZE SW_MINIMIZE SW_RESTORE SW_SHOW
		 SW_SHOWDEFAULT SW_SHOWMAXIMIZED SW_SHOWMINIMIZED
		 SW_SHOWMINNOACTIVE SW_SHOWNA SW_SHOWNOACTIVATE SW_SHOWNORMAL));

  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Win32::Screenshot',
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
