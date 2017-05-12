#!/pro/bin/perl

use strict;
use warnings;

use Test::More tests => 44;
use Test::NoWarnings;

use_ok "Text::OutputFilter";

my $lm = 4;
@ARGV and $ARGV[0] =~ m/^\d+$/ && ! -f $ARGV[0] and $lm = 0 + shift;

my $buf = "";
my $expect;

my $tof = "Text::OutputFilter";
tie *STDOUT, $tof, undef, \$buf;
like (tied (*STDOUT), qr{^$tof=HASH},			"lm = undef - tied");
untie *STDOUT;
is   (tied (*STDOUT), undef,				"lm = undef - untied");

tie *STDOUT, $tof, 0, \$buf;
like (tied (*STDOUT), qr{^$tof=HASH},			"lm = 0 - tied");
untie *STDOUT;
is   (tied (*STDOUT), undef,				"lm = 0 - untied");

eval { tie *STDOUT, $tof, undef, *STDERR };
like (tied (*STDOUT), qr{^$tof=HASH},			"lm = 0 - tied");
untie *STDOUT;
is   (tied (*STDOUT), undef,				"lm = 0 - untied");

# test errors
eval { tie *STDOUT, $tof, "x", \$buf };
is   (tied (*STDOUT), undef,				"lm = 'x' - fail");
like ($@, qr{1st arg must be numeric},			"lm must be numeric");

eval { tie *STDOUT, $tof, [ ], \$buf };
is   (tied (*STDOUT), undef,				"lm = [] - fail");
like ($@, qr{1st arg must be numeric},			"lm must be numeric");

eval { tie *STDOUT, $tof, { }, \$buf };
is   (tied (*STDOUT), undef,				"lm = {} - fail");
like ($@, qr{1st arg must be numeric},			"lm must be numeric");

eval { tie *STDOUT, $tof, undef, [ ] };
is   (tied (*STDOUT), undef,				"io = [] - fail");
like ($@, qr{2nd arg must be the output handle},	"io must be handle");

eval { tie *STDOUT, $tof, undef, { } };
is   (tied (*STDOUT), undef,				"io = {} - fail");
like ($@, qr{2nd arg must be the output handle},	"io must be handle");

eval { local *FOO; tie *STDOUT, $tof, undef, *FOO };
is   (tied (*STDOUT), undef,				"io = *FOO undef - fail");
like ($@, qr{2nd arg must be the output handle},	"io must be handle");

eval { local *FOO; tie *STDOUT, $tof, undef, \*FOO };
is   (tied (*STDOUT), undef,				"io = \\*FOO undef - fail");
like ($@, qr{2nd arg must be the output handle},	"io must be handle");

eval { my $foo; local *FOO; open FOO, ">", \$foo; tie *STDOUT, $tof, undef, *FOO };
is   (tied (*STDOUT), undef,				"io = *FOO -> \\\$foo - fail");
like ($@, qr{2nd arg must be the output handle},	"io must be handle");

eval { tie *STDOUT, $tof, undef, undef, 0 };
is   (tied (*STDOUT), undef,				"sub = 0 - fail");
like ($@, qr{3rd arg must be CODE-ref},			"sub must be CODE");

eval { tie *STDOUT, $tof, undef, undef, "x" };
is   (tied (*STDOUT), undef,				"sub = 'x' - fail");
like ($@, qr{3rd arg must be CODE-ref},			"sub must be CODE");

eval { tie *STDOUT, $tof, undef, undef, [ ] };
is   (tied (*STDOUT), undef,				"sub = [] - fail");
like ($@, qr{3rd arg must be CODE-ref},			"sub must be CODE");

eval { tie *STDOUT, $tof, undef, undef, { } };
is   (tied (*STDOUT), undef,				"sub = {} - fail");
like ($@, qr{3rd arg must be CODE-ref},			"sub must be CODE");

eval { local *FOO; tie *STDOUT, $tof, undef, undef, *FOO };
is   (tied (*STDOUT), undef,				"sub = *FOO - fail");
like ($@, qr{3rd arg must be CODE-ref},			"sub must be CODE");

tie *STDOUT, $tof, undef, \$buf;
like (tied   (*STDOUT), qr{^$tof=HASH},			"methods on closed handle");
is   (close    STDOUT, 1,				"close ()");
is   (eof      STDOUT, 1,				"closed");
is   (close    STDOUT, 1,				"close () again");

eval { binmode STDOUT };
like ($@, qr{Cannot set binmode on closed},		"binmode on closed");
eval { print   STDOUT "\n" };
like ($@, qr{Cannot print to closed},			"print   to closed");
eval { printf  STDOUT "\n" };
like ($@, qr{Cannot print to closed},			"printf  to closed");
eval { my $pos = tell STDOUT };
like ($@, qr{Cannot tell from a closed},		"tell  from closed");
untie *STDOUT;

tie *STDOUT, $tof, undef, \$buf;
like (tied (*STDOUT), qr{^$tof=HASH},			"undef the FH");
undef *STDOUT;
is   (tied (*STDOUT), undef,				"untied");
