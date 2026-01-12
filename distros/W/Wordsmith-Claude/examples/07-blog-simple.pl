#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;

use lib 'lib';
use Wordsmith::Claude qw(blog);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# Simple blog post generation
my $result = blog(
    topic  => 'Building AI-Powered Tools with Claude Code and the Perl SDK',
    style  => 'technical',
    tone   => 'enthusiastic',
    length => 'medium',
    sections => [
        'Introduction - Why Perl + Claude?',
        'The Claude::Agent SDK',
        'Code Review with Claude::Agent::Code::Review',
        'Auto-Refactoring with Claude::Agent::Code::Refactor',
        'Text Transformation with Wordsmith::Claude',
        'Conclusion - The Future of Perl AI Tools',
    ],
    loop   => $loop,
)->get;

if ($result->is_success) {
    print $result->as_markdown;
    print "\n", "=" x 60, "\n";
    print "Title: ", $result->title, "\n";
    print "Word count: ", $result->word_count, "\n";
    print "Reading time: ", $result->reading_time, " minutes\n";
    print "Sections: ", $result->section_count, "\n";
} else {
    print "Error: ", $result->error, "\n";
}
