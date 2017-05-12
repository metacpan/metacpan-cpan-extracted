#!/usr/bin/perl -w
#
# $Id: Build.PL,v 1.1.1.1 2008-09-02 23:55:12 cvscore Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(
 module_name	=> 'WebService::Eulerian::Analytics',
 license	=> 'perl',
 requires	=> {
  'perl'	=> '>= 5.10.0',
  'SOAP::Lite'	=> '>= 0.710.08'
 }
);
$build->create_build_script;

1;
__END__
