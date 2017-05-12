# This -*- perl -*- script writes the Makefile for strict::ModuleName
# Time-stamp: "2002-08-27 20:18:13 MDT"
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'strict::ModuleName',
    'VERSION_FROM' => 'ModuleName.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'ModuleName.pm',
    'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__
