#
# $Id: 0-useme.t,v 0.2 2007/03/25 21:39:11 dankogai Exp $
#

use strict;
use Test::More tests => 2;

use_ok('Unicode::Unihan', 'use');
is(ref(Unicode::Unihan->new) => 'Unicode::Unihan', 'class');

__END__
