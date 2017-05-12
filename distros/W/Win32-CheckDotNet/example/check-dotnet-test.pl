#!perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib $Bin . '/../lib';
use Win32::CheckDotNet;
use Data::Dumper qw/Dumper/;
use Log::Log4perl qw/:easy/;

# -- PerlApp explicit uses
use Log::Log4perl::Appender::Screen;
use Log::Log4perl::Appender::File;
# -- /PerlApp explicit uses

Log::Log4perl->easy_init({
    level   => $TRACE,
    layout  => '%d{ISO8601} %m%n',
});

my $check = Win32::CheckDotNet->new;
printf ".NET 4.5 full -> %s\n", $check->check_dotnet_4_5;
printf ".NET 4.0 full -> %s\n", $check->check_dotnet_4_0_full;
printf ".NET 4.0 client -> %s\n", $check->check_dotnet_4_0_client;
printf ".NET 3.5 -> %s\n", $check->check_dotnet_3_5;
printf ".NET 3.0 -> %s\n", $check->check_dotnet_3_0;
printf ".NET 2.0 -> %s\n", $check->check_dotnet_2_0;
printf ".NET 1.1 -> %s\n", $check->check_dotnet_1_1;
printf ".NET 1.0 -> %s\n", $check->check_dotnet_1_0;

exit(0);