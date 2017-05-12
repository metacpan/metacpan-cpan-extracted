#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

use KIF::Bootloader ;
use KIF::Bootloader::aboot ;
use KIF::Bootloader::grub ;
use KIF::Bootloader::lilo ;
use KIF::Build ;
use KIF::Build::alpha ;
use KIF::Build::ix86 ;
use KIF::Build::ppc ;

ok(1);

exit;
__END__
