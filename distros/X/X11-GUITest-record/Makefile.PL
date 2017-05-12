use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

&write_doc;

WriteMakefile(
    NAME              => 'X11::GUITest::record',
    VERSION_FROM      => 'lib/X11/GUITest/record.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Perl implementation of the X11 record extension', # retrieve abstract from module
       AUTHOR         => 'Marc Koderer <mkoderer@cpan.org>, Gerald Richter/ecos GmbH') : ()),
    LIBS              => ['-L/usr/X11R6/lib -lX11 -lXtst'], 
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    clean             => {FILES   => 'X11-GUITest-record.pod'},
    'MAN3PODS'        => {'X11-GUITest-record.pod' => '$(INST_MAN3DIR)/X11::GUITest::record.$(MAN3EXT)'} ,
    OBJECT            => 'datastructure.o record.o', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'X11::GUITest::record',
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

sub write_doc
{
my $podfile = 'X11-GUITest-record.pod';
	print "Writing POD file\n";
        # Combine POD containing files into one.  Don't love
        # the system() calls, but acceptable as short-term.
        system("cat lib/X11/GUITest/record.pm >$podfile");
        system("cat record.xs >>$podfile");
}
