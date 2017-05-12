
# Run this program to generate a makefile.  See "perldoc perlmodinstall"
#
# Time-stamp: "2004-01-15 00:19:40 AST"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	    => 'XML::RSS::Timing',
    'VERSION_FROM'  => 'lib/XML/RSS/Timing.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/XML/RSS/Timing.pm',
    'PREREQ_PM'     => {
        'Carp'        => 0,  # a core module anyway
        'Time::Local' => 0,  # a core module anyway
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
