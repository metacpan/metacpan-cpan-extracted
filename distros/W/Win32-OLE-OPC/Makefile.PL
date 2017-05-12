use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Win32::OLE::OPC',
    'VERSION_FROM' => 'OPC.pm', # finds $VERSION
    'AUTHOR' => 'Martin Tomes <martin\@tomes.freeserve.co.uk',
);

sub MY::postamble {
  '
documentation: OPC.html OPC.txt
	$(PREFIX)\bin\pod2html.bat OPC.pm > OPC.html
	$(PREFIX)\bin\pod2text.bat OPC.pm > OPC.txt
';
}
