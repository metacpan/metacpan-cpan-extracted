use 5.006;

use ExtUtils::MakeMaker;

my @utils_to_install = qw (kocos.pl rank.pl combig.pl huge-count.pl huge-merge.pl huge-sort.pl huge-split.pl huge-delete.pl count2huge.pl find-compounds.pl);
#my @utils_to_install = qw (kocos.pl rank.pl combig.pl huge-count.pl huge-combine.pl sort-bigrams.pl split-data.pl);

my @required_to_install = qw(count.pl statistic.pl);

my @sh_to_install = qw( kocos-script.sh rank-script.sh combig-script.sh );

WriteMakefile(
    NAME              => 'Text::NSP',
    VERSION_FROM      => 'lib/Text/NSP.pm', # finds $VERSION
    PREREQ_PM         => {},
##
## don't display detailed help messages
## seems to cause problems with Windows installs
##
##    CONFIGURE         => \&configSub,
    EXE_FILES         => [
                           map ("bin/$_", @required_to_install),
                           map ("bin/utils/$_", @utils_to_install),
                           map ("bin/utils/$_", @sh_to_install),
                         ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/Text/NSP.pm', # retrieve abstract from module
    AUTHOR         => 'Ted Pedersen <tpederse at d.umn.edu>') : ()),
   # allows make dist to create .tar.gz with correct name/version
   'dist'             => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
   # allows for automatic creation of META.yml
   ($ExtUtils::MakeMaker::VERSION ge '6.30_00'?
   ('LICENSE' => 'GPL', ) : ()),
);


sub configSub
{

  print "#################################################################\n";
  print " You are running Makefile.PL. When this finishes, remember that you\n";
  print " will also need to run the following to finish the install of NSP:\n";
  print "\n";
  print "        make\n";
  print "        make test\n";
  print "        make install\n";
  print "        cd Testing\n";
  print "        csh ./ALL-TESTS.sh\n";
  print "        cd ..\n";
  print "        make clean\n";
  print "\n";
  print " if \"make install\" fails and indicates that you don\'t have proper\n";
  print " permissions to install, you do have the option to install NSP in\n";
  print " a local directory of your own choosing. You can do this as follows:\n";
  print "\n";
  print "        perl Makefile.PL PREFIX=~/MyNSP LIB=~/MyPerlLib\n";
  print "        make\n";
  print "        make test\n";
  print "        make install\n";
  print "        cd Testing\n";
  print "        csh ./ALL-TESTS.sh\n";
  print "        cd ..\n";
  print "        make clean\n";
  print "\n";
  print " where ~ is your home directory (or any directory you control)\n";
  print "#################################################################\n";

  return {};
}

# modified postambe to return nothing, in order to improve the
# chances of successful windows install
# also, now that Text-NSP behaves like a stanard Perl module
# such help messages aren't really that necessary (since it
# behaves likes most any other Perl module on installation
# this fix suggested by sean [...] semanticbible.com 
# #20371: MakeMaker postamble breaks under nmake/Windows

sub MY::postamble {
  my $postamble = "";
#   my $postamble = <<'END';
# html:
# 	@echo "*****************************************************"
# 	@echo "Installing the Ngram Statistics Package, V $(VERSION)..."
# 	@echo " ...into $(SITEPREFIX) (/doc /bin /lib /man) "
# 	@echo "Make sure that the following are in your PATH:"
# 	@echo "     $(INSTALLBIN)"
# 	@echo "and the following in your PERL5LIB:"
# 	@echo "     $(INSTALLSITELIB)"
# 	@echo "*****************************************************"
# END
  return ($postamble);
}

## revert to a more standard method of testing and installation

#sub MY::install
#{
#  my $self = shift;
#  my $string = $self->MM::install;
##  my $add = 'html';
#  $string =~ s/(pure_install\s+)(.*)/$1 $add $2/;
#  return $string;
#}

# For testing
#sub MY::test
#{
#    q(
#TEST_VERBOSE=0
#
#test: all
#	$(FULLPERL) t/TEST $(TEST_VERBOSE)

#);
#}

