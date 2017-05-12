#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
} else {
    plan tests => 18;
}

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

TODO: {

  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/XAS/Collector.pm');
  module_boilerplate_ok('lib/XAS/Apps/Collector/Process.pm');
  module_boilerplate_ok('lib/XAS/Collector/Input/Stomp.pm');
  module_boilerplate_ok('lib/XAS/Collector/Formatter/Base.pm');
  module_boilerplate_ok('lib/XAS/Collector/Formatter/Alerts.pm');
  module_boilerplate_ok('lib/XAS/Collector/Formatter/Logs.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Console/Base.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Console/Alerts.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Console/Logs.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Database/Base.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Database/Alerts.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Database/Logs.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Socket/Base.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Socket/Logstash.pm');
  module_boilerplate_ok('lib/XAS/Collector/Output/Socket/OpenTSDB.pm');
  module_boilerplate_ok('lib/XAS/Docs/Collector/Installation.pm');
  module_boilerplate_ok('lib/XAS/Model/Database/Messaging/Result/Alert.pm');
  module_boilerplate_ok('lib/XAS/Model/Database/Messaging/Result/Log.pm');

}

