#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 18;

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

  module_boilerplate_ok('lib/Validator/Lazy.pm');
  module_boilerplate_ok('lib/Validator/Lazy/TestRole/ExtRoleExample.pm');
  module_boilerplate_ok('lib/Validator/Lazy/TestRole/FieldDep.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Composer.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Notifications.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/Required.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/Test.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/Email.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/Phone.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/MinMax.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/IP.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/Trim.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/RegExp.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/Form.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/IsIn.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/Case.pm');
  module_boilerplate_ok('lib/Validator/Lazy/Role/Check/CountryCode.pm');


}

