#!perl -w

use strict;
use Test::More tests => 31;

use XS::Assert;

use XSLoader;
XSLoader::load('XS::Assert');


package
    XS::Assert;

use Test::More;

close STDERR;
open STDERR, '>', \my $s;

# xok

# SvOK

ok !eval{ assert_sv_ok(undef); 1 };
diag $@ if -d 'inc/.author';

ok eval{ assert_sv_ok(0); 1 };

ok eval{ assert_sv_ok("foo"); 1 };

ok eval{ assert_sv_ok(3.14); 1 };

ok eval{ assert_sv_ok({}); 1 };

ok eval{ assert_sv_ok(\*ok); 1 };

# SvPOKp

ok !eval{ assert_sv_pok(undef); 1 };

ok !eval{ assert_sv_pok(0); 1 };

ok eval{ assert_sv_pok("foo"); 1 };

ok !eval{ assert_sv_pok(3.14); 1 };

ok !eval{ assert_sv_pok({}); 1 };

ok !eval{ assert_sv_pok(*ok); 1 };

# SvIOKp

ok !eval{ assert_sv_iok(undef); 1 };

ok eval{ assert_sv_iok(0); 1 };

ok !eval{ assert_sv_iok("foo"); 1 };

ok !eval{ assert_sv_iok(3.14); 1 };

ok !eval{ assert_sv_iok({}); 1 };

ok !eval{ assert_sv_iok(*ok); 1 };

# SvNOKp

ok !eval{ assert_sv_nok(undef); 1 };

ok !eval{ assert_sv_nok(0); 1 };

ok !eval{ assert_sv_nok("foo"); 1 };

ok eval{ assert_sv_nok(3.14); 1 };

ok !eval{ assert_sv_nok({}); 1 };

ok !eval{ assert_sv_nok(*ok); 1 };

# SvROK

ok !eval{ assert_sv_rok(undef); 1 };

ok !eval{ assert_sv_rok(0); 1 };

ok !eval{ assert_sv_rok("foo"); 1 };

ok !eval{ assert_sv_rok(3.14); 1 };

ok eval{ assert_sv_rok({}); 1 };

ok !eval{ assert_sv_rok(*ok); 1 };


isnt $s, '', 'output something to stderr';

