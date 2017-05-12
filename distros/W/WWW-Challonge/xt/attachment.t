#!perl -T
use strict;
use warnings;
use WWW::Challonge;
use Test::More tests => 6;

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge::Match::Attachment") || BAIL_OUT();
}

diag("Testing WWW::Challonge::Participant $WWW::Challonge::Participant::VERSION, Perl $], $^X");

SKIP:
{
	skip "Requires 'key' file with API key to run xt tests", 1
		unless( -f "xt/key");

	open my $file, '<', "xt/key" or die "Error: Cannot open key file: $!";
	chomp(my $key = <$file>);

	# Create a new tournament and two participants:
	my $c = WWW::Challonge->new($key);
	my $url = "";
	my @chars = ("a".."z", "A".."Z", "_");
	$url .= $chars[rand @chars] for(1..20);
	my $t = $c->new_tournament({
		name => "Perl Test",
		url => $url,
		accept_attachments => 1,
	});
	my $p1 = $t->new_participant({ name => "alice" });
	my $p2 = $t->new_participant({ name => "bob" });
	$t->start;
	my $match = $t->matches->[0];

	# Test create works:
	my @attachments;
	subtest "create works" => sub
	{
		push @attachments, $match->new_attachment({
			url => "http://search.cpan.org/~kirby/WWW-Challonge/",
			description => "The module's homepage",
		});
		isa_ok($attachments[0], "WWW::Challonge::Match::Attachment");

		SKIP:
		{
			skip "Missing test file to upload", 1 unless( -f "xt/test_file");
			push @attachments, $match->new_attachment({
				asset => "xt/test_file",
				description => "A test file",
			});
			isa_ok($attachments[1], "WWW::Challonge::Match::Attachment");
		}
	};

	# Test attachments works:
	is(@{$match->attachments}, @attachments, "index is same size");

	# Test attributes work:
	subtest "attributes work" => sub
	{
		like($attachments[0]->attributes->{url}, qr/cpan\.org\/~kirby/,
			"Attachment is correct url");
		like($attachments[0]->attributes->{description}, qr/homepage$/,
			"Description is correct");

		SKIP:
		{
			skip "Did not upload file", 2 unless(defined $attachments[1]);
			like($attachments[1]->attributes->{asset_file_name}, qr/test_file/,
				"Attachment is correct url");
			like($attachments[1]->attributes->{description}, qr/test file$/,
				"Description is correct");
		}
	};

	# Test updating works:
	subtest "update works" => sub
	{
		ok($attachments[0]->update({
			url => "https://metacpan.org/release/KIRBY/WWW-Challonge/",
		}));
		like($attachments[0]->attributes->{url}, qr/metacpan/,
			"Attachment is correct url");

		SKIP:
		{
			skip "Did not upload file or no new file to upload", 2
				unless((defined $attachments[1]) && ( -f "xt/test_file2"));
			ok($attachments[1]->update({
				asset => "xt/test_file2",
			}));
			like($attachments[1]->attributes->{asset_file_name}, qr/test_file2/,
				"Attachment is correct file");
		}
	};

	# Test deleting works:
	subtest "destroy works" => sub
	{
		ok($attachments[0]->destroy, "attachment destroyed");
		eval { $attachments[0]->update({ description => "foo" }); }
			or my $at = $@;
		like($at, qr/Attachment has been destroyed/, "Dies on attempting to
			update destroyed attachment");

		SKIP:
		{
			skip "Did not upload file", 2 unless(defined $attachments[1]);
			ok($attachments[1]->destroy, "attachment destroyed");
			eval { $attachments[1]->update({ description => "foo" }); }
				or $at = $@;
			like($at, qr/Attachment has been destroyed/, "Dies on attempting to
				update destroyed attachment");
		}
	};
}
