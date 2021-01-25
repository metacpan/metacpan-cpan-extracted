package Wireguard::WGmeta::Cli::TerminalHelpers;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';
use base 'Exporter';
our @EXPORT = qw(prettify_message BOLD RESET GREEN RED YELLOW);

use constant BOLD => (!defined($ENV{'WG_NO_COLOR'})) ? "\e[1m" : "";
use constant RESET => (!defined($ENV{'WG_NO_COLOR'})) ? "\e[0m" : "";
use constant GREEN => (!defined($ENV{'WG_NO_COLOR'})) ? "\e[32m" : "";
use constant RED => (!defined($ENV{'WG_NO_COLOR'})) ? "\e[31m" : "";
use constant YELLOW => (!defined($ENV{'WG_NO_COLOR'})) ? "\e[33m" : "";

sub prettify_message($error, $is_warning) {
    $error =~ s/at.*$//g unless (defined $ENV{IS_TESTING});
    if ($is_warning == 1) {
        print BOLD . YELLOW . "Warning: " . RESET . $error;
        return;
    }
    print BOLD . RED . "Error: " . RESET . $error;
}

1;