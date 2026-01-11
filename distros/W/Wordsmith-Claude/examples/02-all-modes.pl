#!/usr/bin/env perl
#
# Demo all available modes
#
use strict;
use warnings;
use lib 'lib', '../lib';

use Wordsmith::Claude qw(rewrite);
use Wordsmith::Claude::Mode;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $text = shift // "The meeting has been rescheduled to next Tuesday at 3pm. Please update your calendars accordingly.";

print "Original: $text\n";
print "=" x 70, "\n\n";

# Show modes by category
for my $category (Wordsmith::Claude::Mode->all_categories) {
    print "=== " . uc($category) . " ===\n\n";

    for my $mode (Wordsmith::Claude::Mode->modes_in_category($category)) {
        my $desc = Wordsmith::Claude::Mode->get_description($mode);
        print "[$mode] $desc\n";

        my $result = rewrite(
            text => $text,
            mode => $mode,
            loop => $loop,
        )->get;

        if ($result->is_success) {
            print "  -> ", $result->text, "\n\n";
        } else {
            print "  ERROR: ", $result->error, "\n\n";
        }
    }
}
