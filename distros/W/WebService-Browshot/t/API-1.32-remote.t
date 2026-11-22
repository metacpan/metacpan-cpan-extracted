use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use WebService::Browshot;

plan skip_all => 'Set BROWSHOT_REMOTE_TESTS and BROWSHOT_KEY to enable API tests'
	if (! $ENV{BROWSHOT_REMOTE_TESTS} || ! $ENV{BROWSHOT_KEY});

my %args = (key => $ENV{BROWSHOT_KEY});
$args{base} = $ENV{BROWSHOT_BASE} if ($ENV{BROWSHOT_BASE});
my $browshot = WebService::Browshot->new(%args);
my $account = $browshot->account_info();
ok(exists $account->{balance}, 'Authenticated account has a balance');
ok($account->{active}, 'Authenticated account is active');

my $instances = $browshot->instance_list();
ok(ref($instances->{shared}) eq 'ARRAY', 'Shared instance catalog is available');
if (ref($instances->{shared}) eq 'ARRAY' && @{$instances->{shared}}) {
	my $instance = $instances->{shared}->[0];
	my $info = $browshot->instance_info(id => $instance->{id});
	is($info->{id}, $instance->{id}, 'Instance details use the existing response format');
	is($info->{screenshot_cost}, 1, 'Paid instance costs one credit');
}

my $browsers = $browshot->browser_list();
ok(ref($browsers) eq 'HASH' && scalar(keys %$browsers) > 0, 'Browser catalog is available');
my ($browser_id) = keys %$browsers;
if (defined $browser_id) {
	my $browser = $browshot->browser_info(id => $browser_id);
	is($browser->{name}, $browsers->{$browser_id}->{name}, 'Browser details use the existing response format');
}

SKIP: {
	skip 'Set BROWSHOT_SCREENSHOT_ID to an owned, finished test capture', 3 if (! $ENV{BROWSHOT_SCREENSHOT_ID});
	my $screenshot = $browshot->screenshot_info(id => $ENV{BROWSHOT_SCREENSHOT_ID});
	is($screenshot->{status}, 'finished', 'Owned test screenshot is finished');
	my $png = $browshot->screenshot_thumbnail(id => $ENV{BROWSHOT_SCREENSHOT_ID}, width => 64);
	ok(length($png) > 0, 'Existing thumbnail endpoint succeeds');
	is(substr($png, 0, 8), "\211PNG\r\n\032\n", 'Existing thumbnail returns PNG bytes');
}

# Read-only checks. Only supply IDs of test captures belonging to this account.
# No captures, shares, hosting jobs, or batch/crawl jobs are created by this test.
my $directory = tempdir(CLEANUP => 1);
foreach my $artifact (
	['pdf', 'BROWSHOT_PDF_ID', '%PDF-'],
	['webm', 'BROWSHOT_WEBM_ID', "\032\105\337\243"],
	['mp4', 'BROWSHOT_MP4_ID', 'ftyp'],
	['gif', 'BROWSHOT_GIF_ID', 'GIF8'],
) {
	my ($format, $variable, $signature) = @$artifact;
	SKIP: {
		skip "Set $variable to an owned, finished test capture", 4 if (! $ENV{$variable});
		my $method = $format eq 'pdf' ? 'screenshot_pdf' : 'screenshot_video';
		my $file_method = $method . '_file';
		my $bytes = $browshot->$method(id => $ENV{$variable});
		ok(length($bytes) > 0, "$format download succeeds");
		is(substr($bytes, $format eq 'mp4' ? 4 : 0, length($signature)), $signature, "$format has the correct file signature");
		my $file = File::Spec->catfile($directory, "capture.$format");
		is($browshot->$file_method(id => $ENV{$variable}, file => $file), $file, "$format saves to a file");
		ok(-s $file, "$format file is not empty");
	}
}

foreach my $method ('screenshot_pdf', 'screenshot_video') {
	is($browshot->$method(id => -1), '', "$method handles a rejected API request");
	like($browshot->{last_error}, qr/Server sent back an error: (?:400|404)/, "$method records the API error");
}

done_testing;
