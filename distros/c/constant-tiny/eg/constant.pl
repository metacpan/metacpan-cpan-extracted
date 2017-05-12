use strict;
use constant::tiny;

use constant pi => 4 * atan2(1, 1);

use constant ponies => qw<
    Twilight_Sparkle Fluttershy Pinkie_Pie AppleJack Rainbow_Dash Rarity
>;

use constant {
    host => "mail.whatever.com",
    port => 25,
    user => "maddingue",
    pass => "s3Kret",
};

print "pi = ", pi, $/;
print "host = ", host, $/;
print "ponies: ", join(", ", ponies), $/;

