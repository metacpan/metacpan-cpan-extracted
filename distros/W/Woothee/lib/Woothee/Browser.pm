package Woothee::Browser;

use strict;
use warnings;
use Carp;

use Woothee::Util qw/update_map update_category update_version update_os/;
use Woothee::DataSet qw/dataset/;

our $VERSION = "1.6.0";

sub challenge_msie {
    my ($ua,$result) = @_;

    return 0 if index($ua, "compatible; MSIE") < 0 and index($ua, "Trident/") < 0 and index($ua, "IEMobile");

    my $version;
    if ($ua =~ m{MSIE ([.0-9]+);}o) {
        $version = $1;
    } elsif ($ua =~ m{Trident/([.0-9]+);}o and $ua =~ m{ rv:([.0-9]+)}o) {
        $version = $1;
    } elsif ($ua =~ m{IEMobile/([.0-9]+);}o) {
        $version = $1;
    } else {
        $version = Woothee::DataSet->const('VALUE_UNKNOWN');
    }
    update_map($result, dataset('MSIE'));
    update_version($result, $version);
    return 1;
}

sub challenge_vivaldi {
    my ($ua, $result) = @_;

    return 0 if index($ua, "Vivaldi/") < 0;

    my $version = Woothee::DataSet->const('VALUE_UNKNOWN');

    if ($ua =~ m{Vivaldi/([.0-9]+)}o) {
        $version = $1;
    }
    update_map($result, dataset('Vivaldi'));
    update_version($result, $version);
    return 1;
}

sub challenge_safari_chrome { # and Opera(blink)
    my ($ua,$result) = @_;

    return 0 if index($ua, "Safari/") < 0;

    my $version = Woothee::DataSet->const('VALUE_UNKNOWN');

    if ($ua =~ m{Edge/([.0-9]+)}o) {
        # MS Edge
        $version = $1;
        update_map($result, dataset("Edge"));
        update_version($result, $version);
        return 1;
    }

    if ($ua =~ m{FxiOS/([.0-9]+)}o) {
        # Firefox for iOS
        $version = $1;
        update_map($result, dataset("Firefox"));
        update_version($result, $version);
        return 1;
    }

    if ($ua =~ m{(?:Chrome|CrMo|CriOS)/([.0-9]+)}o) {
        # Opera (blink)
        if ($ua =~ m{OPR/([.0-9]+)}o) {
            $version = $1;
            update_map($result, dataset("Opera"));
            update_version($result, $version);
            return 1;
        }

        #WebView
        if (index($ua, "wv") > -1) {
            return 0;
        }

        # Chrome
        $version = $1;
        update_map($result, dataset("Chrome"));
        update_version($result, $version);
        return 1;
    }

    # Safari
    if ($ua =~ m{Version/([.0-9]+)}o) {
        $version = $1;
    }
    update_map($result, dataset("Safari"));
    update_version($result, $version);
    return 1;
}

sub challenge_firefox {
    my ($ua,$result) = @_;

    return 0 if index($ua, "Firefox/") < 0;

    my $version;
    if ($ua =~ m{Firefox/([.0-9]+)}o) {
        $version = $1;
    }
    else {
        $version = Woothee::DataSet->const('VALUE_UNKNOWN');
    }
    update_map($result, dataset("Firefox"));
    update_version($result, $version);
    return 1;
}

sub challenge_opera {
    my ($ua,$result) = @_;

    return 0 if index($ua, "Opera") < 0;

    my $version;
    if ($ua =~ m{Version/([.0-9]+)}o) {
	$version = $1;
    }
    elsif ($ua =~ m{Opera[/ ]([.0-9]+)}o) {
        $version = $1;
    }
    else {
        $version = Woothee::DataSet->const('VALUE_UNKNOWN');
    }
    update_map($result, dataset("Opera"));
    update_version($result, $version);
    return 1;
}

sub challenge_webview {
    my ($ua,$result) = @_;


    my $version = Woothee::DataSet->const('VALUE_UNKNOWN');

    # iOS
    if ($ua =~ m{iP(hone;|ad;|od) .*like Mac OS X}o) {
        return 0 if index($ua, "Safari/") > -1;

        if ($ua =~ m{Version/([.0-9]+)}o) {
            $version = $1;
        }

        update_version($result, $version);
        update_map($result, dataset("Webview"));
        return 1;
    }
    elsif (index($ua, "wv") > -1) { #WebView
        if ($ua =~ m{Version/([.0-9]+)}o) {
            $version = $1;
        }

        update_version($result, $version);
        update_map($result, dataset("Webview"));
        return 1;
    }

    return 0;
}


sub challenge_sleipnir {
    my ($ua,$result) = @_;

    return 0 if index($ua, "Sleipnir/") < 0;

    my $version;
    if ($ua =~ m{Sleipnir/([.0-9]+)}o) {
        $version = $1;
    }
    else {
        $version = Woothee::DataSet->const('VALUE_UNKNOWN');
    }
    update_map($result, dataset("Sleipnir"));
    update_version($result, $version);

    # Sleipnir's user-agent doesn't contain Windows version, so put 'Windows UNKNOWN Ver'.
    # Sleipnir is IE component browser, so for Windows only.
    my $win = dataset("Win");
    update_category($result, $win->{Woothee::DataSet->const('KEY_CATEGORY')});
    update_os($result, $win->{Woothee::DataSet->const('KEY_NAME')});

    return 1;
}

1;

__END__

=head1 NAME

Woothee::Browser - part of Woothee

For Woothee, see L<https://github.com/woothee/woothee>

=head1 DESCRIPTION

This module doesn't have any public interfaces. To parse user-agent strings, see module 'Woothee'.

=head1 AUTHOR

TAGOMORI Satoshi E<lt>tagomoris {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
