# Print out all constants from the Microsoft Excel type library

use strict;
use Win32::OLE;
use Win32::OLE::Const;

my $xl = Win32::OLE::Const->Load("Microsoft Excel 8.0");
printf "Excel type library contains %d constants:\n", scalar keys %$xl;
foreach my $Key (sort keys %$xl) {
    print "$Key = $xl->{$Key}\n";
}
