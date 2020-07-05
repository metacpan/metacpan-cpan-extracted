package Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
use strict;
use warnings;
use feature qw(state);

use Encode qw(encode_utf8);
use Test2::API qw(
    test2_add_callback_post_load
    test2_stack
    test2_stderr
);
use URI::Escape qw(uri_escape);

our $VERSION = "0.04";

sub import {
    my ($class) = @_;

    return unless $ENV{GITHUB_ACTIONS};
    state $loaded = 0; # avoid multiple callback addition
    return if $loaded;
    $loaded++;

    test2_add_callback_post_load(sub {
        my $hub = test2_stack()->top;
        $hub->listen(\&listener, inherit => 1);
    });
}

sub listener {
    my ($hub, $event) = @_;

    return unless $event->causes_fail;

    my $trace = $event->trace;
    my $summary = _extract_summary_from_event($event);
    my $file = $trace->file // '<no name>';
    my $line = $trace->line // 0;
    my $details = _extract_details_from_event($event);
    my $message = encode_utf8(join "\n", grep { defined } ($summary, $details)); # avoid Wide character in print warning

    _issue_error($file, $line, $message);
}

sub _extract_summary_from_event {
    my ($event) = @_;

    my $name_or_summary = $event->isa('Test2::Event::Fail') ? $event->name : $event->summary;
    # avoid uninitialized warning for regexp matching
    $name_or_summary //= '';
    if ($name_or_summary =~ /Nameless Assertion/ || ! length $name_or_summary) {
        return 'Test failed';
    } else {
        return $name_or_summary;
    }
}

sub _extract_details_from_event {
    my ($event) = @_;

    return undef unless exists $event->{info};
    return join "\n", map { $_->{details} } @{$event->{info}};
}

sub _issue_error {
    my ($file, $line, $detail) = @_;

    my $stderr = test2_stderr();

    $stderr->printf("::error file=%s,line=%d::%s\n", $file, $line, _escape_data($detail));
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

Test2::Plugin::GitHub::Actions::AnnotateFailedTest - Annotate failed tests with GitHub Actions workflow command

=head1 DESCRIPTION

This plugin provides annotations to the line of falied tests for GitHub Actions workflow.

=head1 SYNOPSIS

Just use this module and run tests. Note that this plugin is enabled only in a GitHub Actions workflow.

    use Test2::Plugin::GitHub::Actions::AnnotateFailedTest;

=head1 LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

utgwkk E<lt>utagawakiki@gmail.comE<gt>

=cut

