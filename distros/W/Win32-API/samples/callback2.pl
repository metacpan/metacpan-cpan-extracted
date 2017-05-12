$| = 1;

use blib;
use Win32::API;
use Win32::API::Callback;

my $sub = sub {
    my ($locale) = @_;
    printf "EnumSystemLocales callback got: '%s'\n", $locale;
    return 1;
};

my $Callback = Win32::API::Callback->new($sub, "P", "N");

Win32::API->Import("kernel32", "EnumSystemLocales", "KN", "N");

print "Calling EnumSystemLocales...\n";
$rc = EnumSystemLocales($Callback, 1);
print "EnumSystemLocales returned $rc\n";

