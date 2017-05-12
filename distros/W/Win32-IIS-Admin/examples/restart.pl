
# $Id: restart.pl,v 1.2 2008/11/07 00:47:28 Martin Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Win32::IIS::Admin;

Win32::IIS::Admin::restart_iis();

__END__

