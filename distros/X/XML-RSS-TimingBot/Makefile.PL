
# Run this program to generate a makefile.  See "perldoc perlmodinstall"
#
# Time-stamp: "2004-04-24 01:34:35 ADT"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	    => 'XML::RSS::TimingBot',
    'VERSION_FROM'  => 'lib/XML/RSS/TimingBot.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/XML/RSS/TimingBot.pod',
    'PREREQ_PM'     => {
        'XML::RSS::Timing'    => 0,
        'File::Spec'          => 0,
        'LWP::UserAgent::Determined' => 0,
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
