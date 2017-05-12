
# Run this program to generate a makefile.  See "perldoc perlmodinstall"
# and "perldoc ExtUtils::MakeMaker" for more details.
#
# Time-stamp: "2004-01-17 21:06:22 AST"

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	       => 'XML::RSS::SimpleGen',
    'VERSION_FROM'  => 'lib/XML/RSS/SimpleGen.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/XML/RSS/SimpleGen.pm',
    'PREREQ_PM'     => {
       'strict' => 0,
       'IO::Socket' => 0,
       'Carp' => 0,
       # It's good in LWP::Simple is installed, but not necessary
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
