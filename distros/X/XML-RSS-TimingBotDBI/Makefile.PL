
# Run this program to generate a makefile.  See "perldoc perlmodinstall"
#
# Time-stamp: "2004-04-24 00:32:43 ADT"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	    => 'XML::RSS::TimingBotDBI',
    'VERSION_FROM'  => 'lib/XML/RSS/TimingBotDBI.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/XML/RSS/TimingBotDBI.pm',
    'PREREQ_PM'     => {
        'XML::RSS::TimingBot' => 2.00,
        'DBI' => 0,
    },
    'dist'         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__
