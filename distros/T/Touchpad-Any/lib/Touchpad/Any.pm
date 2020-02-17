package Touchpad::Any;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-01'; # DATE
our $DIST = 'Touchpad-Any'; # DIST
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
    summary => 'Common interface to touchpad',
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

sub _find_touchpad_xinput_ids {
    my @ids;
    for my $line (split /^/m, `xinput`) {
        if ($line =~ /(\w\S+?)\s+id=(\d+)/) {
            my ($name, $id) = ($1, $2);
            if ($name =~ /touch\s*pad/i) {
                log_trace "Found xinput touchpad device: name=$name, id=$id";
                push @ids, $id;
            }
        }
    }
    @ids;
}

sub _disable_or_enable_touchpad {
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
        my @ids = _find_touchpad_xinput_ids()
            or return [412, "Cannot find any xinput touchpad device"];
        system "xinput ".($which eq 'disable' ? 'disable' : 'enable')." $_" for @ids;
        $resmeta->{'func.device_ids'} = \@ids;
        return [200, "OK", undef, $resmeta];
    }

    [412, "Cannot find any method to disable/enable touchpad"];
}

$SPEC{disable_touchpad} = {
    v => 1.1,
    summary => 'Disable touchpad',
    args => {
        %argopt_method,
    },
};
sub disable_touchpad {
    _disable_or_enable_touchpad('disable', @_);
}

$SPEC{enable_touchpad} = {
    v => 1.1,
    summary => 'Enable touchpad',
    args => {
        %argopt_method,
    },
};
sub enable_touchpad {
    _disable_or_enable_touchpad('enable', @_);
}

$SPEC{touchpad_is_enabled} = {
    v => 1.1,
    summary => 'Check whether touchpad is enabled',
    args => {
        %argopt_quiet,
        %argopt_method,
    },
};
sub touchpad_is_enabled {
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
        my @ids = _find_touchpad_xinput_ids()
            or return [412, "Cannot find any xinput touchpad device"];
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
        my $msg = $enabled ? "Touchpad is enabled" :
            "Some/all touchpads are NOT enabled";
        return [200, "OK", $enabled, {
            'cmdline.exit_code' => $enabled ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : $msg,
            %$resmeta,
        }];
    } # METHOD_XINPUT

    [412, "Cannot find any method to check whether touchpad is enabled"];
}

$SPEC{has_touchpad} = {
    v => 1.1,
    summary => 'Check whether system has touchpad device',
    args => {
        %argopt_quiet,
        %argopt_method,
    },
};
sub has_touchpad {
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
        my @ids = _find_touchpad_xinput_ids();
        $resmeta->{'func.device_ids'} = \@ids;
        my $msg = @ids ? "System has one or more touchpads" :
            "System does NOT have any touchpad";
        return [200, "OK", @ids ? 1:0, {
            'cmdline.exit_code' => @ids ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : $msg,
            %$resmeta,
        }];
    } # METHOD_XINPUT

    [412, "Cannot find any method to disable/enable touchpad"];
}

1;
# ABSTRACT: Common interface to touchpad

__END__

=pod

=encoding UTF-8

=head1 NAME

Touchpad::Any - Common interface to touchpad

=head1 VERSION

This document describes version 0.002 of Touchpad::Any (from Perl distribution Touchpad-Any), released on 2019-12-01.

=head1 FUNCTIONS


=head2 disable_touchpad

Usage:

 disable_touchpad(%args) -> [status, msg, payload, meta]

Disable touchpad.

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



=head2 enable_touchpad

Usage:

 enable_touchpad(%args) -> [status, msg, payload, meta]

Enable touchpad.

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



=head2 has_touchpad

Usage:

 has_touchpad(%args) -> [status, msg, payload, meta]

Check whether system has touchpad device.

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



=head2 touchpad_is_enabled

Usage:

 touchpad_is_enabled(%args) -> [status, msg, payload, meta]

Check whether touchpad is enabled.

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

Please visit the project's homepage at L<https://metacpan.org/release/Touchpad-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Touchpad-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Touchpad-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::TouchpadUtils> for CLIs.

L<Touchscreen::Any>, L<Bluetooth::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
