# this is a stub package, used to create new commands

# you can assume the existence of a %CONFIG variable with everything
# you need for ldap connections
#

use Net::LDAP::Shell::Util qw(debug error);
use Getopt::Long;

use Exporter;
use vars qw($VERSION @ISA);
$VERSION = 1.00;
@ISA = qw(Exporter);

sub main {

	my ($usage,$results,$entry,@attrs,$optresult,$help,$helptext);

	$usage = "help [--help]\n";
	$optresult = GetOptions(
		'help'		=> \$help,
	);

	$helptext =
"Help on the help command.  Right.\n";

	unless ($optresult) {
		warn $usage;
		return 1;
	}

	unless ($optresult) {
		print $usage,$helptext;
		return;
	}

print qq(Generally, this shell behaves as much as possible like a real shell,
and thus its commands behave as much as possible like a real shell.  This
means that if you want help on a command, just run <command> --help and
it should give you that help.

There is, unfortunately, not currently a good way to list all of the commands
available to you.  There is a command, 'builtins', which will tell you
all of the built-in commands (as they are not compiled dynamically), but
until I come up with an elegant way to list all available commands,
here is the current list, as of 11/04:

builtins
cat
cd
clone
config
debugging
edit
exit
export
help
ls
newrm
pwd
quit
search
set

Again, if you want help on these commands, run '<command> --help'.  It's a bug
if any of them don't provide a help page; please report it as such.

);

}

1;
