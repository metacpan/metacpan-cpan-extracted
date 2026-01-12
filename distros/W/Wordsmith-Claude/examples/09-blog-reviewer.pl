#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use lib 'lib';
use lib 'Wordsmith-Claude/lib';

use Wordsmith::Claude::Blog::Reviewer::Interactive;
use Claude::Agent::CLI qw(prompt header status);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

header("Interactive Blog Reviewer");

# Get blog file or text from user
my $input = prompt("Enter path to blog file (or press Enter to paste text)", "");

my $interactive;

if ($input && -f $input) {
    # Load from file
    status('info', "Loading blog from: $input");
    $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        file => $input,
        loop => $loop,
    );
} elsif ($input) {
    # New file path provided - will create it
    status('info', "Will save progress to: $input");
    print "\nPaste your blog text below (end with a line containing only '---END---'):\n";
    my @lines;
    while (my $line = <STDIN>) {
        last if $line =~ /^---END---$/;
        push @lines, $line;
    }
    my $text = join('', @lines);

    $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        text => $text,
        file => $input,  # Will save progress here
        loop => $loop,
    );
} else {
    # No file - paste mode only
    print "\nPaste your blog text below (end with a line containing only '---END---'):\n";
    my @lines;
    while (my $line = <STDIN>) {
        last if $line =~ /^---END---$/;
        push @lines, $line;
    }
    my $text = join('', @lines);

    unless ($text && $text =~ /\S/) {
        status('error', "No blog text provided.");
        exit 1;
    }

    $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        text => $text,
        loop => $loop,
    );
}

print "\n";

my $result = $interactive->run->get;

if ($result->is_success) {
    print "\n";
    header("REVIEW COMPLETE");

    my $meta = $result->metadata // {};
    status('success', sprintf("Reviewed %d of %d paragraphs",
        $meta->{paragraph_count} // 0,
        $meta->{original_count} // 0));

    print "\nWould you like to display the final blog? [Y/n] ";
    my $show = <STDIN>;
    chomp $show;

    if ($show !~ /^n/i) {
        print "\n", "-" x 60, "\n";
        print "FINAL BLOG:\n";
        print "-" x 60, "\n\n";
        print $result->text, "\n";
    }

    print "\nWould you like to save to a file? [y/N] ";
    my $save = <STDIN>;
    chomp $save;

    if ($save =~ /^y/i) {
        my $outfile = prompt("Enter output filename", "reviewed-blog.md");
        if ($outfile) {
            if (open my $fh, '>:encoding(UTF-8)', $outfile) {
                print $fh $result->text;
                close $fh;
                status('success', "Saved to: $outfile");
            } else {
                status('error', "Cannot write to $outfile: $!");
            }
        }
    }
} else {
    status('error', "Review failed");
}

print "\nDone!\n";

__END__

=head1 NAME

09-blog-reviewer.pl - Interactive blog review tool using Wordsmith modules

=head1 SYNOPSIS

    perl examples/09-blog-reviewer.pl

    # Or with lib paths:
    perl -Ilib -IWordsmith-Claude/lib examples/09-blog-reviewer.pl

=head1 DESCRIPTION

This example demonstrates the L<Wordsmith::Claude::Blog::Reviewer::Interactive>
module, which provides an interactive terminal UI for reviewing and revising
blog posts paragraph by paragraph.

Features:

=over 4

=item * AI-powered content and grammar analysis

=item * Multiple revision options (grammar, clarity, conciseness, etc.)

=item * Manual editing with external editor ($EDITOR)

=item * Code block detection with specialized analysis

=item * Live progress saving to file

=item * Colored terminal UI with menus

=back

=head1 WORKFLOW

1. Load a blog from file or paste text
2. For each paragraph:
   - View the paragraph and AI analysis
   - Choose: approve, revise with AI, edit manually, or skip
   - Progress saved automatically after each paragraph
3. Review final output and optionally save

=head1 SEE ALSO

L<Wordsmith::Claude::Blog::Reviewer::Interactive>,
L<Wordsmith::Claude::Blog::Reviewer>, L<Claude::Agent::CLI>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
