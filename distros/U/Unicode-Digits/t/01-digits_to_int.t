use strict;
use warnings;

use Test::More tests => 37;

my $warn = '';
$SIG{__WARN__} = sub { $warn = join '', @_ };

sub warn_is {
	my ($x, $y, $warning) = @_;
	is $x, $y;
	is $warn, $warning;
	$warn = '';
}

use Unicode::Digits qw/digits_to_int/;

warn_is digits_to_int("42"),                    42,        '';
warn_is digits_to_int("\x{1814}\x{1812}"),      42,        '';
warn_is digits_to_int("4\x{1812}"),             42,        '';
warn_is digits_to_int("a is \x{06f4}\x{06f2}"), "a is 42", '';

warn_is digits_to_int("42",                    "loosest"), 42,        '';
warn_is digits_to_int("\x{1814}\x{1812}",      "loosest"), 42,        '';
warn_is digits_to_int("4\x{1812}",             "loosest"), 42,        '';
warn_is digits_to_int("a is \x{06f4}\x{06f2}", "loosest"), "a is 42", '';

warn_is digits_to_int("42",                    "looser"), 42,        '';
warn_is digits_to_int("\x{1814}\x{1812}",      "looser"), 42,        '';
warn_is digits_to_int("4\x{1812}",             "looser"), 42,        "string '4\x{1812}' contains digits from different ranges at t/01-digits_to_int.t line 30\n";
warn_is digits_to_int("a is \x{06f4}\x{06f2}", "looser"), "a is 42", "string 'a is \x{06f4}\x{06f2}' contains non-digit characters at t/01-digits_to_int.t line 31\n";

warn_is digits_to_int("42",                    "loose"), 42,        '';
warn_is digits_to_int("\x{1814}\x{1812}",      "loose"), 42,        '';
warn_is digits_to_int("4\x{1812}",             "loose"), 42,        "string '4\x{1812}' contains digits from different ranges at t/01-digits_to_int.t line 35\n";
eval { digits_to_int("a is \x{06f4}\x{06f2}", "loose") };
is $@, "string 'a is \x{06f4}\x{06f2}' contains non-digit characters at t/01-digits_to_int.t line 36\n";

warn_is digits_to_int("42", 'strict'), 42, '';
warn_is digits_to_int("\x{07c4}\x{07c2}", 'strict'), 42, '';
eval { digits_to_int("4\x{1812}", "strict") };
is $@, "string '4\x{1812}' contains digits from different ranges at t/01-digits_to_int.t line 41\n";
eval { digits_to_int("a is \x{06f4}\x{06f2}", "strict") };
is $@, "string 'a is \x{06f4}\x{06f2}' contains non-digit characters at t/01-digits_to_int.t line 43\n";
