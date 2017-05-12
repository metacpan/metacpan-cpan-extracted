# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

use XTerm::Conf;

plan 'no_plan';

ok !defined &xterm_conf_string, 'xterm_conf_string is not exported';

is XTerm::Conf::xterm_conf_string(), '', 'no operation';
is XTerm::Conf::xterm_conf_string(-title => 'Hello'), "\033]2;Hello\a", 'set -title';
ok !eval { XTerm::Conf::xterm_conf_string('-invalid-option' => 42); 1 };
#like $@, qr{^Unknown option: invalid-option}, 'error option'; XXX appears at stderr
like $@, qr{^usage:.*\Q$0}, 'usage';

__END__
