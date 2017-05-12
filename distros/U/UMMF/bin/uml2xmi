#!/usr/local/bin/perl
# $Id: uml2xmi.pl,v 1.1 2003/10/13 22:30:52 kstephens Exp $

package UML2XMI;

use strict;
use warnings;

use File::Basename;
use IO::File;

my $_0dir = dirname($0);
require "$_0dir/argo2xmi.pl";

my $errors = 0;

while ( @ARGV ) {
  local $_ = shift;

  if ( /\.xmi$/i ) {
    my $fh = IO::File->new;
    $fh->open("< $_") || die("$0: Cannot read '$_': $!");
    while ( defined(my $line = <$fh>) ) {
      print $line;
    }
    $fh->close;
  }
  elsif ( /\.zargo$|.zuml$/i ) {
    Argo2XMI::main($_);
  }
  else {
    print STDERR "$0: Unknown UML file type: '$_'\n";
    ++ $errors;
  }
}

exit($errors);

1;
