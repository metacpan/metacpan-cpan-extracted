# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Temp qw(tempfile);
	1;
    }) {
	print "1..0 # skip: no Test::More and/or File::Temp module\n";
	exit;
    }
}

use Fcntl qw(SEEK_SET);
use SelectSaver ();

use XTerm::Conf;

plan 'no_plan';

ok defined &xterm_conf, 'xterm_conf is exported';

is run_xterm_conf(), '', 'no operation';
{
    local $ENV{TERM} = 'xterm';
    is run_xterm_conf(-title => 'Hello'), "\033]2;Hello\a", 'set -title for xterm';
}
{
    local $ENV{TERM} = 'dumb';
    is run_xterm_conf(-title => 'Hello'), '', 'set -title for non-xterm';
}
{
    local $ENV{TERM};
    is run_xterm_conf(-title => 'Hello'), '', 'set -title without TERM variable';
}

sub run_xterm_conf {
    my(@opts) = @_;
    my($tmpfh,$tmpfile) = tempfile(UNLINK => 1);
    my $saver = SelectSaver->new($tmpfh);
    xterm_conf(@opts);
    seek $tmpfh, SEEK_SET, 0 or die "Can't seek: $!";
    my $buf = do {
	local $/;
	scalar <$tmpfh>;
    };
    close $tmpfh;
    unlink $tmpfile;
    $buf;
}

__END__
