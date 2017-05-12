#
#   Configuration diagnostics idea taken from XML::Simple
#

#   $Id: 01-config.t 67 2008-06-29 14:17:37Z adam $

use strict;
use Test::More;
use Config;

my $test_warn;
BEGIN {
    eval ' require Test::NoWarnings; ';
    if ( $@ ) {
        plan( tests => 1 );
        undef $test_warn;
    }
    else {
        plan( tests => 2 );
        $test_warn = 1;
    }
}

my @module_list = qw(
    XML::Parser
    XML::RSS
    XML::LibXML
    XML::LibXSLT
    URI
    LWP
    HTTP::GHTTP
    HTTP::Lite
    WWW::Curl::Easy
    Test::More
    Test::Warn
    Test::NoWarnings
    Test::Perl::Critic
    Test::Pod
    Test::Pod::Coverage
    Pod::Coverage
    IO::Capture);

my ( %version );
foreach my $module ( @module_list ) {
    eval " require $module; ";
    unless ( $@ ) {
        no strict 'refs';
        $version{$module} = ${ $module . '::VERSION' } || "Unknown";
    } else {
        $version{module} = "Not Installed"
    }
}

$version{perl}                 = $Config{version};
$version{'Operating System'}   = $Config{osname};

unshift @module_list, 'Operating System', 'perl';

diag( sprintf( "\r# %-30s %s\n", 'Package', 'Version' ) );
foreach my $module ( @module_list ) {
    $version{$module} = "Not Installed" unless ( defined( $version{$module} ) );
    diag( sprintf( " %-30s %s\n", $module, $version{$module} ) );
}

ok( 1, "Dumped Configuration data" );
if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}
