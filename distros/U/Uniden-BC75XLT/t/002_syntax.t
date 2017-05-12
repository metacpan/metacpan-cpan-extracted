use File::Find;

find({ no_chdir=>1, wanted=>sub {
   return if $File::Find::name !~ /\.pm$/;
   eval ("require '$File::Find::name'; ");
   if($@) {
      print STDERR $@;
      print "Bail out!\n";
   }
}}, ".");
print "1..1\nok 1\n";
