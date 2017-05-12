# $Source: /home/keck2/editors/vim/perl/makemaker/RCS/test.pl,v $
# $Revision: 1.1 $$Date: 2004/01/28 04:33:00 $

use Test;

BEGIN { plan tests => 1 }

chop(my $pwd = `pwd`);

eval { @help = `$pwd/blib/script/varp -help` };
ok(@help > 150);

