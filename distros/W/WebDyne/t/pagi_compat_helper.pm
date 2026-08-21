package pagi_compat_helper;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK=qw(pagi_skip_reason);
our $MIN_PAGI_VERSION='0.002000';

sub pagi_skip_reason {
    my @module=@_ ? @_ : qw(PAGI::Request PAGI::Response PAGI::Test::Client Future::AsyncAwait);

    for my $module (@module) {
        eval "require $module; 1"
            or return "missing $module: $@";

        next unless $module =~ /^PAGI::/;
        my $version=eval { $module->VERSION($MIN_PAGI_VERSION); 1 };
        return "$module must be $MIN_PAGI_VERSION or newer"
            unless $version;
    }

    if (grep { $_ eq 'PAGI::Request' } @module) {
        return 'PAGI::Request must support form_params'
            unless PAGI::Request->can('form_params');
        return 'PAGI::Request must support query_params'
            unless PAGI::Request->can('query_params');
    }

    if (grep { $_ eq 'PAGI::Response' } @module) {
        return 'PAGI::Response must support detached responses via respond'
            unless PAGI::Response->can('respond');
        return 'PAGI::Response must support new($scope) without send'
            unless eval { PAGI::Response->new({}); 1 };
    }

    return;
}

1;
