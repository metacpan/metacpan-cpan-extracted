package Touchscreen::Any;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-01'; # DATE
our $DIST = 'Touchscreen-Any'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter::Rinci qw(import);
use File::Which qw(which);
use IPC::System::Options 'system', 'readpipe', -log=>1;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Common interface to touchscreen',
};

our %argopt_method = (
    method => {
        schema => 'str*',
    },
);

our %argopt_quiet = (
    quiet => {
        summary => "Don't output anything on command-line, ".
            "just return appropriate exit code",
        schema => 'true*',
        cmdline_aliases => {q=>{}, silent=>{}},
    },
);

sub _find_touchscreen_xinput_ids {
    my @ids;
    for my $line (split /^/m, `xinput`) {
        if ($line =~ /(\w\S+?)\s+id=(\d+)/) {
            my ($name, $id) = ($1, $2);
            if ($name =~ /touch\s*screen/i) {
                log_trace "Found xinput touchscreen device: name=$name, id=$id";
                push @ids, $id;
            }
        }
    }
    @ids;
}

sub _disable_or_enable_touchscreen {
    my ($which, %args) = @_;

    my $method = $args{method};
    my $resmeta = {};

  METHOD_XINPUT: {
        last if $method && $method ne 'xinput';
        unless (which "xinput") {
            log_trace "xinput not in PATH, skipping xinput method";
            last;
        }
        $resmeta->{'func.method'} = 'xinput';
        my @ids = _find_touchscreen_xinput_ids()
            or return [412, "Cannot find any xinput touchscreen device"];
        system "xinput ".($which eq 'disable' ? 'disable' : 'enable')." $_" for @ids;
        $resmeta->{'func.device_ids'} = \@ids;
        return [200, "OK", undef, $resmeta];
    }

    [412, "Cannot find any method to disable/enable touchscreen"];
}

$SPEC{disable_touchscreen} = {
    v => 1.1,
    summary => 'Disable touchscreen',
    args => {
        %argopt_method,
    },
};
sub disable_touchscreen {
    _disable_or_enable_touchscreen('disable', @_);
}

$SPEC{enable_touchscreen} = {
    v => 1.1,
    summary => 'Enable touchscreen',
    args => {
        %argopt_method,
    },
};
sub enable_touchscreen {
    _disable_or_enable_touchscreen('enable', @_);
}

$SPEC{touchscreen_is_enabled} = {
    v => 1.1,
    summary => 'Check whether touchscreen is enabled',
    args => {
        %argopt_quiet,
        %argopt_method,
    },
};
sub touchscreen_is_enabled {
    my %args = @_;

    my $method = $args{method};
    my $resmeta = {};

  METHOD_XINPUT: {
        last if $method && $method ne 'xinput';
        unless (which "xinput") {
            log_trace "xinput not in PATH, skipping xinput method";
            last;
        }
        $resmeta->{'func.method'} = 'xinput';
        my @ids = _find_touchscreen_xinput_ids()
            or return [412, "Cannot find any xinput touchscreen device"];
        $resmeta->{'func.device_ids'} = \@ids;
        my $num_enabled = 0;
        for my $id (@ids) {
            my $output = readpipe("xinput list --long $id");
            if ($output =~ /This device is disabled/) {
            } else {
                $num_enabled++;
            }
        }
        my $enabled = $num_enabled == @ids ? 1:0;
        my $msg = $enabled ? "Touchscreen is enabled" :
            "Some/all touchscreens are NOT enabled";
        return [200, "OK", $enabled, {
            'cmdline.exit_code' => $enabled ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : $msg,
            %$resmeta,
        }];
    } # METHOD_XINPUT

    [412, "Cannot find any method to check whether touchscreen is enabled"];
}

$SPEC{has_touchscreen} = {
    v => 1.1,
    summary => 'Check whether system has touchscreen device',
    args => {
        %argopt_quiet,
        %argopt_method,
    },
};
sub has_touchscreen {
    my %args = @_;

    my $method = $args{method};
    my $resmeta = {};

  METHOD_XINPUT: {
        last if $method && $method ne 'xinput';
        unless (which "xinput") {
            log_trace "xinput not in PATH, skipping xinput method";
            last;
        }
        $resmeta->{'func.method'} = 'xinput';
        my @ids = _find_touchscreen_xinput_ids();
        $resmeta->{'func.device_ids'} = \@ids;
        my $msg = @ids ? "System has one or more touchscreens" :
            "System does NOT have any touchscreen";
        return [200, "OK", @ids ? 1:0, {
            'cmdline.exit_code' => @ids ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : $msg,
            %$resmeta,
        }];
    } # METHOD_XINPUT

    [412, "Cannot find any method to disable/enable touchscreen"];
}

1;
# ABSTRACT: Common interface to touchscreen

__END__

=pod

=encoding UTF-8

=head1 NAME

Touchscreen::Any - Common interface to touchscreen

=head1 VERSION

This document describes version 0.002 of Touchscreen::Any (from Perl distribution Touchscreen-Any), released on 2019-12-01.

=head1 FUNCTIONS


=head2 disable_touchscreen

Usage:

 disable_touchscreen(%args) -> [status, msg, payload, meta]

Disable touchscreen.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<method> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 enable_touchscreen

Usage:

 enable_touchscreen(%args) -> [status, msg, payload, meta]

Enable touchscreen.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<method> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 has_touchscreen

Usage:

 has_touchscreen(%args) -> [status, msg, payload, meta]

Check whether system has touchscreen device.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<method> => I<str>

=item * B<quiet> => I<true>

Don't output anything on command-line, just return appropriate exit code.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 touchscreen_is_enabled

Usage:

 touchscreen_is_enabled(%args) -> [status, msg, payload, meta]

Check whether touchscreen is enabled.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<method> => I<str>

=item * B<quiet> => I<true>

Don't output anything on command-line, just return appropriate exit code.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Touchscreen-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Touchscreen-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Touchscreen-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::TouchscreenUtils> for CLIs.

L<Touchpad::Any>, L<Bluetooth::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
