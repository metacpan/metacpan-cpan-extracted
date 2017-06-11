use Test::More;
use Modern::Perl '2010';
use lib 'lib';

BEGIN
{
	use_ok('Moo');
	use_ok('Function::Parameters');
	use_ok('WebService::Pixabay');
	use_ok('LWP::Online', 'online');
	use_ok('Modern::Perl', '2009');
	use_ok('WebService::Client');
	use_ok('Data::Dumper', 'Dumper');
}

my $true = 1;
my $false = 0;

# change $false to $true if you want to do advanced test
my $AUTHOR_TESTING = $false;

SKIP:
{
	skip "installation testing", 1 unless $AUTHOR_TESTING == $true;

	ok(my $pix =
		WebService::Pixabay->new(
			api_key => $ENV{PIXABAY_KEY}
		));

	SKIP:
	{	skip "No internet connection", 1 unless online();

		ok(my $img1 = $pix->image_search, " image_search method");
		ok(my $vid1 = $pix->video_search, "video_search method");
		ok($pix->show_data_structure($img1), "image_search data structure presentation");
		ok($pix->show_data_structure($vid1), "video_search data structure presentation");
		ok($pix->show_data_structure($pix->image_search(q => 'water')), "custom image search data presentation");
		ok($pix->video_search(q => 'fire')->{hits}[0]{videos}{medium}{url}, "get a single hash value from video_search json structure");
	}
};

done_testing;
