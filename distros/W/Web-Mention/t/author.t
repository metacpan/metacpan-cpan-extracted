use warnings;
use strict;
use Test::More;
use Path::Class::Dir;
use List::Util qw(first);
use FindBin;

use_ok ("Web::Mention::Author");

# @TODO_TESTS: List of tests that the parser should support someday, but
#              that day is not today.
my @TODO_TESTS =
qw(
h-entry_with_u-author.html no_h-card.html h-entry_with_rel-author.html h-card_with_u-url_equal_to_u-uid_equal_to_self.html h-card_with_u-url_equal_to_self.html h-feed_with_u-author.html h-card_with_u-url_that_is_also_rel-me.html
);

my $test_dir = Path::Class::Dir->new( "$FindBin::Bin/authorship_test_cases");

foreach ( $test_dir->children ) {
    handle_file($_) if /html$/;
}

sub handle_file {
    my $file = shift;

    my $html = $file->slurp;

    my $author = Web::Mention::Author->new_from_html( $html );

    if ( first { $_ eq $file->basename } @TODO_TESTS ) {
        local $TODO = "We don't support the "
                      . $file->basename
                      . ' test yet.';

        TODO: { ok( $author && $author->name eq 'John Doe' ) }
    }
    else {
        ok( $author && $author->name eq 'John Doe' );
    }
}

done_testing();
