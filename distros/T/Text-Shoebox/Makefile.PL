# This -*- perl -*- script writes the Makefile for Text::Shoebox
# Time-stamp: "2004-03-24 15:45:42 AST"
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Text::Shoebox',
    'VERSION_FROM'  => 'lib/Text/Shoebox.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'lib/Text/Shoebox.pm', # 
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
