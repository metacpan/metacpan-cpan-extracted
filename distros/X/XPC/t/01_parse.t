#!/usr/bin/perl -w
#
# 01_parse.t
#
# Copyright (C) 2001 Gregor N. Purdy.
# All rights reserved.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#


use strict;

BEGIN {
  print "1..1\n";
};

###############################################################################

use XPC;

my $xpc_xml = <<END_XPC;
<xpc>
  <call procedure='localtime'/>
</xpc>
END_XPC


print "$0: Attempting to parse this string:\n$xpc_xml\n";

my $xpc = XPC->new($xpc_xml);

print "not " unless defined $xpc;

###############################################################################

END {
  print "ok 1\n";
};

exit 0;


#
# End of file.
#
