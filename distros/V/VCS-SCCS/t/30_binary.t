#!/pro/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::NoWarnings;

BEGIN {
    use_ok ("VCS::SCCS");
    }

ok (my $sccs = VCS::SCCS->new ("files/SCCS/s.binary.dta"), "Read binary uuencoded SCCS");

my $body = join "" => <DATA>;

is        ($sccs->checksum (),	23800,		"Checksum");
is_deeply ($sccs->flags (),	{ e => 1 },	"Binary flag is set");
is        ($sccs->body (),	$body,		"Body");

__END__
To be created with sccs create -b to avoid sccs keyword replacement
Just some text to
show a binaru sccs
Text file !!!

Some various caracters:
azertyuiopqsdfghjklmwxcvbn
%i%
%w%
%I%
%W%
&"#'{(-`_\^@
