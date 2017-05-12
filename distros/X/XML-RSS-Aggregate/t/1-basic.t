#!/usr/bin/perl
# $File: //member/autrijus/XML-RSS-Aggregate/t/1-basic.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 2920 $ $DateTime: 2002/12/25 14:43:18 $

use strict;
print "1..1\n";

print "not " unless eval { require XML::RSS::Aggregate };
print "ok 1 # require XML::RSS::Aggregate\n";

__END__
# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
