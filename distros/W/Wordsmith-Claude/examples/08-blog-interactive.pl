#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use lib 'lib';
use lib 'Wordsmith-Claude/lib';

use Wordsmith::Claude::Blog::Interactive;
use Claude::Agent::CLI qw(prompt header status);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

header("Interactive Blog Builder");

# Get topic from user
my $topic = prompt("What would you like to write about?",
    "Building AI-Powered Tools with Claude Code and the Perl SDK");

print "\n";

# Build with full interactive workflow
my $interactive = Wordsmith::Claude::Blog::Interactive->new(
    topic => $topic,
    style => 'technical',
    tone  => 'enthusiastic',
    loop  => $loop,
);

status('info', "Starting interactive blog building process...");
status('info', "(You'll have choices at each step)");
print "\n";

my $result = $interactive->run->get;

if ($result->is_success) {
    header("FINAL BLOG POST");
    print $result->as_markdown;
    print "\n";
    print "-" x 60, "\n";
    print "Stats:\n";
    print "  Title:        ", $result->title, "\n";
    print "  Style:        ", $result->style, "\n";
    print "  Tone:         ", $result->tone, "\n";
    print "  Word count:   ", $result->word_count, "\n";
    print "  Reading time: ", $result->reading_time, " minutes\n";
    print "  Sections:     ", $result->section_count, "\n";
} else {
    status('error', "Error: " . $result->error);
}

__END__

=head1 NAME

08-blog-interactive.pl - Interactive blog builder using Wordsmith modules

=head1 SYNOPSIS

    perl examples/08-blog-interactive.pl

    # Or with lib paths:
    perl -Ilib -IWordsmith-Claude/lib examples/08-blog-interactive.pl

=head1 DESCRIPTION

This example demonstrates the L<Wordsmith::Claude::Blog::Interactive> module,
which provides a colorful terminal UI for the blog building process.

Features:

=over 4

=item * Colored headers and status messages

=item * Interactive menus with keyboard navigation

=item * Spinners during AI processing

=item * Step-by-step workflow with user choices at each stage

=back

=head1 SEE ALSO

L<Wordsmith::Claude::Blog::Interactive>, L<Wordsmith::Claude::Blog::Builder>,
L<Claude::Agent::CLI>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
