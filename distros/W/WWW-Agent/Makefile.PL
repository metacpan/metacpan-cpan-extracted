use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Agent',
    VERSION_FROM      => 'lib/WWW/Agent.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Agent.pm', # retrieve abstract from module
       AUTHOR         => 'Robert Barta <rho@bigpond.net.au>') : ()),
##      'EXE_FILES'     => [ 'bin/tm' ],

       'NOECHO'        => '@',
       'PREREQ_PM'     => {
# do a 'make dependencies' to get an update
	   "Algorithm::Diff"   => 1.11,
	   "HTML::TreeBuilder" => 3.13,
	   "HTTP::Request"     => 1.40,
	   "HTTP::Response"    => 1.52,
	   "LWP::UserAgent"    => 2.033,
	   "Log::Log4perl"     => 0.51,
	   "POE"               => 0.29,
	   "Parse::RecDescent" => 1.94,
	   "Test::More"        => 0.47,
	   "URI"               => 1.30,
       },
);


package MY;

sub depend {
    return <<MAKE

dependencies:
	egrep -e '(^use | use ).*;' `find t -iname '*.t'; find lib -iname '*.pm'; find bin -iname '*'` | perl -ne '/^.+?:\\s*use ([A-Za-z0-9:]+)/; print "\$\$1\\n"' | egrep -v '(base|Carp|POSIX|vars|strict|constant|warnings|Class::Struct|Fcntl|Data::Dumper|Storable|lib|UNIVERSAL|Digest::MD5|IO::File|File::Temp|File::stat|Getopt::Long)' | egrep -v '^TM' | grep -v '^XTM' | sort -u | perl -ne 's/;//; chomp; next unless \$\$_; print "\\"\$\$_\\"    => "; eval "use \$\$_; print (\\\$\$\$\${_}::VERSION || \\"undef\\")"; print ",\\n"'

MAKE
}
