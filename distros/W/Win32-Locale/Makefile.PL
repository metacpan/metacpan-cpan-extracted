# This -*- perl -*- script writes the Makefile for Win32::Locale
# Time-stamp: "2003-07-16 02:27:00 AHDT"
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Win32::Locale',
    'VERSION_FROM' => 'Locale.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'Locale.pm', # 
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
