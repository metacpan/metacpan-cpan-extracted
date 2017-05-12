# -*- mode: perl; coding: utf-8 -*-
package YATT::Toplevel::FCGI;
use strict;
use warnings qw(FATAL all NONFATAL misc);

BEGIN {require Exporter; *import = \&Exporter::import}

use base qw(YATT::Toplevel::CGI);
use YATT::Toplevel::CGI;
use YATT::Exception;

use FCGI;
use YATT::Util;

#========================================

sub run {
  my ($pack, $request) = splice @_, 0, 2;
  my $config = $pack->new_config(@_);
  my $age = -M $0;
  $request = FCGI::Request() unless defined $request;
  while ($request->Accept >= 0) {
    my $rc = catch {
      $pack->SUPER::run('cgi', undef, $config);
    } \ my $error;
    if ($rc and my ($file, $newcgi) = can_retry($error)) {
      $pack->run_retry_max(3, $config, $file, $newcgi);
    }
    $request->Finish;
    last if -e $0 and -M $0 < $age;
  }
}

sub plain_exit { shift->bye }

1;
