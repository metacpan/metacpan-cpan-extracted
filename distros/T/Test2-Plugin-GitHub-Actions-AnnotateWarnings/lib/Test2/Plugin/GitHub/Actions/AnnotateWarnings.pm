package Test2::Plugin::GitHub::Actions::AnnotateWarnings;
use 5.008001;
use strict;
use warnings;

use Test2::API qw(test2_stderr);
use URI::Escape qw(uri_escape);

our $VERSION = "0.01";

sub __ignore_no_warnings {
    my ($message, $filename, $line) = @_;
    return 0;
}

# By default, no warning is ignored.
my $ignore_if = \&__ignore_no_warnings;

my $_orig_warn_handler;

sub import {
    my ($class, %args) = @_;

    return unless $ENV{GITHUB_ACTIONS};

    $ignore_if = $args{ignore_if} if exists $args{ignore_if};

    $_orig_warn_handler = $SIG{__WARN__};

    $SIG{__WARN__} = sub {
        my (undef, $file, $line) = caller;
        my $message = $_[0] // "Warning: Something's wrong";
        chomp $message;
        $message = _escape_data($message);

        my $stderr = test2_stderr();
        _issue_warning($file, $line, $message) unless $ignore_if->($message, $file, $line);

        # from Test::Warnings
        # TODO: this doesn't handle blessed coderefs... does anyone care?
        if ($_orig_warn_handler and ((ref $_orig_warn_handler eq 'CODE') or ($_orig_warn_handler ne 'DEFAULT' and $_orig_warn_handler ne 'IGNORE' and defined &$_orig_warn_handler))) {
            goto &$_orig_warn_handler;
        }
    };
}

sub unimport {
    my ($class) = @_;

    $ignore_if = \&__ignore_no_warnings;
    $SIG{__WARN__} = $_orig_warn_handler;
}

sub _issue_warning {
    my ($file, $line, $detail) = @_;

    my $stderr = test2_stderr();

    if (length $detail) {
        $stderr->printf("::warning file=%s,line=%d::%s\n", $file, $line, _escape_data($detail));
    } else {
        $stderr->printf("::warning file=%s,line=%d\n", $file, $line);
    }
}

# escape a message of workflow command.
# see also: https://github.com/actions/toolkit/blob/30e0a77337213de5d4e158b05d1019c6615f69fd/packages/core/src/command.ts#L92-L97
sub _escape_data {
    my ($msg) = @_;
    return uri_escape($msg, "%\r\n");
}

1;
__END__

=encoding utf-8

=head1 NAME

Test2::Plugin::GitHub::Actions::AnnotateWarnings - Annotate warnings with GitHub Actions workflow command

=head1 SYNOPSIS

Just use this module and run tests. Note that this plugin is enabled only in a GitHub Actions workflow.

    use Test2::Plugin::GitHub::Actions::AnnotateWarnings;

You can also specify a condition whether to annotate a warning or not.

    use Test2::Plugin::GitHub::Actions::AnnotateWarnings ignore_if => sub {
        my ($message, $file, $line) = @_;
        return $message =~ /ignore/;
    };

=head1 DESCRIPTION

This plugin provides annotations to the line of warnings for GitHub Actions workflow.

=head1 LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

utgwkk E<lt>utagawakiki@gmail.comE<gt>

=cut

