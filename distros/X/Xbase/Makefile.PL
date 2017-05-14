use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     'NAME'      => 'Xbase',
     'DISTNAME'  => 'Xbase',
     'VERSION'   => '1.07',
     'PM'  => {'Xbase.pm' => '$(INST_LIBDIR)/Xbase.pm'},
     'linkext'   => { LINKTYPE=>'' },
     'dist'      => {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'}
);

print "\n";
print "Do a 'make install' to install the module.\n";
print "Enjoy !\n";
print "REMEMBER the name has changed from xbase.pm to Xbase.pm\n";
print "-pratap\n";
