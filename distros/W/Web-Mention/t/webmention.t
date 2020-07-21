use warnings; use strict;
use Test::More;
use Test::Exception;
use FindBin;
use Path::Class::File;

use_ok ("Web::Mention");

my $valid_source = 'file://' . "$FindBin::Bin/sources/valid.html";
my $escaped_source = 'file://' . "$FindBin::Bin/sources/escaped.html";
my $invalid_source = 'file://' . "$FindBin::Bin/sources/invalid.html";
my $nonexistent_source = 'file://' . "$FindBin::Bin/sources/nothing-here.html";
my $authored_source = 'file://' . "$FindBin::Bin/authorship_test_cases/h-entry_with_p-author_h-card.html";

my $target = "http://example.com/webmention-target";

my $mock_request = bless({ source => $valid_source, target=>$target}, 'MockRequest');

my $valid_wm = Web::Mention->new(
    source => $valid_source,
    target => $target,
);
ok ($valid_wm->is_verified, "Valid webmention got verified.");

my $valid_wm_from_request = Web::Mention->new_from_request( $mock_request );
ok ($valid_wm_from_request->is_verified, "Another valid webmention got verified.");

my $escaped_wm = Web::Mention->new(
    source => $escaped_source,
    target => $target,
);
ok ($escaped_wm->is_verified, "Valid (URI-escaped) webmention got verified.");

my $invalid_wm = Web::Mention->new(
    source => $invalid_source,
    target => $target,
);
ok (not($invalid_wm->is_verified), "Invalid webmention did not get verified.");

my $nonexistent_wm = Web::Mention->new(
    source => $nonexistent_source,
    target => $target,
);
ok (not($nonexistent_wm->is_verified), "Nonexistent webmention did not get verified.");

throws_ok {
    my $bad_wm = Web::Mention->new(
	source => $valid_source,
	target => $valid_source,
	);
}
qr/same URL/,
    'Caught identical-URL error.'
    ;

throws_ok {
    my $bad_wm = Web::Mention->new(
	source => $valid_source,
	target => $valid_source . '#foobar'
	);
}
qr/same URL/,
    'Caught identical-URL error (with extra fragment).'
    ;

my $source = "http://example.com/webmention-source";
my $valid_html = Path::Class::File->new( "$FindBin::Bin/sources/valid.html")->slurp;
my @webmentions = Web::Mention->new_from_html(
    source => $source,
    html => $valid_html,
);
is ( scalar @webmentions, 2, "Extracted correct number of outgoing webmentions from HTML.");
is ( $webmentions[0]->source, $source, "Source looks good.");
is ( $webmentions[0]->target, $target, "First target looks good.");
is ( $webmentions[1]->target, 'http://example.com/some-other-target', "Second target looks good.");

my $authored_wm = Web::Mention->new(
    source => $authored_source,
    target => $target,
);

ok ($authored_wm->author, 'Authored webmention has an author object.');
is ($authored_wm->author->name, 'John Doe',
    'Authored webmention has correct author name.'
);

is ($valid_wm->author->name, undef,
    'Webmention with no author info has no author name.'
);

is ($nonexistent_wm->author->name, undef,
    'Webmention with no source document has no author name.'
);

done_testing();

package MockRequest;

sub param {
    my ( $self, $param ) = @_;
    return $self->{ $param };
}
