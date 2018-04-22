use warnings; use strict;
use Test::More;
use FindBin;

use_ok ("Web::Mention");

my $valid_source = 'file://' . "$FindBin::Bin/sources/valid.html";
my $invalid_source = 'file://' . "$FindBin::Bin/sources/invalid.html";
my $nonexistent_source = 'file://' . "$FindBin::Bin/sources/nothing-here.html";

my $target = "http://example.com/webmention-target";

my $mock_request = bless({ source => $valid_source, target=>$target}, 'MockRequest');

my $valid_wm = Web::Mention->new(
    source => $valid_source,
    target => $target,
);
ok ($valid_wm->is_verified, "Valid webmention got verified.");

my $valid_wm_from_request = Web::Mention->new_from_request( $mock_request );
ok ($valid_wm_from_request->is_verified, "Another valid webmention got verified.");

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

done_testing();

package MockRequest;

sub param {
    my ( $self, $param ) = @_;
    return $self->{ $param };
}
