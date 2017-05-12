use ExtUtils::MakeMaker;
die 'This module requires OpenVMS'
    unless $^O =~ /VMS/;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VMS::Time',
    LICENSE           => 'Artistic_2',
    VERSION_FROM      => 'lib/VMS/Time.pm', # finds $VERSION
    PREREQ_PM         => {'Test::More'  =>  0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VMS/Time.pm', # retrieve abstract from module
       AUTHOR         => 'Thomas Pfau <tfpfau@gmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    INC               => '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if (eval {require ExtUtils::Constant; 1}) {
    my @names =
	(
	 { name=>PACK, value=>0, macro=>VMSTIME_PACK },
	 { name=>LONGINT, value=>1, macro=>VMSTIME_LONGINT },
	 { name=>FLOAT, value=>2, macro=>VMSTIME_FLOAT },
	 { name=>HEX, value=>3, macro=>VMSTIME_HEX },
	 { name=>BIGINT, value=>4, macro=>VMSTIME_BIGINT },
	 );
    ExtUtils::Constant::WriteConstants( NAME         => 'VMS::Time',
					NAMES        => \@names,
					DEFAULT_TYPE => 'IV',
					C_FILE       => 'const-c.inc',
					XS_FILE      => 'const-xs.inc',
					);
} else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
