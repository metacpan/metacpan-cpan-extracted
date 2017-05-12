# This -*- perl -*- script writes the Makefile for Time::Duration::sv
# Time-stamp: "2002-08-27 20:19:26 MDT"
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Time::Duration::sv',
    'AUTHOR'    => 'Arthur Bergman (arthur at contiller.se)',
    'PREREQ_PM'   => {
      'Time::Duration' => '1.02',
    },
    'VERSION_FROM' => 'sv.pm', # finds $VERSION
    'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__
