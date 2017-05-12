package Devel::AssertOS::Android;

use Devel::CheckOS;

$VERSION = '1.2';

sub os_is { $^O =~ /^android$/i ? 1 : 0; }

Devel::CheckOS::die_unsupported() unless(os_is());

1;
