use warnings;
use strict;
use Test::More;
use Path::Class;
use FindBin;

use_ok ("Web::Mention");

my $source_path = "$FindBin::Bin/sources/many_types.html";

my $source_url = "file://$source_path";

my %type_urls;
my @types = qw(mention reply like repost quotation);

foreach ( @types ) {
    $type_urls{$_} = target_url_for_type( $_ );
}

my @expected_types = qw(
    reply
    mention
    quotation
    like
    like
    repost
    reply
);

my @expected_targets = qw(
    http://example.com/reply-target
    http://example.com/mention-target
    http://example.com/quotation-target
    http://example.com/like-target
    http://example.com/some-other-target
    http://example.com/repost-target
    http://example.com/another-reply-target
);

my $html = Path::Class::File->new( $source_path )->slurp;


my @wms = Web::Mention->new_from_html(
    source => $source_url,
    html => $html,
);

for my $wm ( @wms ) {
    my $expected_target = shift @expected_targets;
    my $expected_type = shift @expected_types;

    is ($wm->type, $expected_type);
    is ($wm->target, $expected_target);
}

#for my $type ( @expected_types ) {
#    my @type_wms = grep { $_->type eq $type } @wms;
#    my $expected = $type =~ 'like|reply'? 2 : 1;
#    is (scalar @type_wms, $expected, "Found exactly $expected '$type' webmention(s).");
#    is ($type_wms[0]->target, target_url_for_type( $type ), "That webmention has the expected target URL.");
#}

sub target_url_for_type {
    my ( $type ) = @_;

    return "http://example.com/$type-target";
}

done_testing();
