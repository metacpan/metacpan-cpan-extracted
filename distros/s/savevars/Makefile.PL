use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	  => 'savevars',
   'VERSION_FROM' => 'savevars.pm', # finds $VERSION
   'PREREQ_PM'    => {'Data::Dumper' => 0},
#   'dist'         => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => '.gz',
#		      'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
);

sub MY::postamble {
	if (defined $ENV{USER} && $ENV{USER} eq 'eserte') {
		<<'EOF';
release :: dist
	cpan-upload $(DISTVNAME).tar$(SUFFIX)

EOF
	}
}
