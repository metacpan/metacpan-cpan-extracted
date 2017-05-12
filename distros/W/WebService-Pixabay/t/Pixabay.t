use Test::More;
use lib 'lib';
use v5.10;

BEGIN
{
	use_ok('Moo');
	use_ok('Data::Printer');
	use_ok('Function::Parameters');
	use_ok('WebService::Pixabay');
	use_ok('LWP::Online', "online");
}

my $true = 1;
my $false = 0;
my $AUTHOR_TESTING = $false;

SKIP:
{
	skip "installation testing", 1 unless $AUTHOR_TESTING == $true;

	ok(my $pix =
		WebService::Pixabay->new(api_key => $ENV{PIXABAY_KEY}),
		"instantiating \$pix object"
	);
	
	done_testing(6);
	
	SKIP:
	{	skip "No internet connection", 1 unless online();

		ok(my $img_search = $pix->image_search(), " image_search method");
		
		ok(my $vid_search = $pix->video_search(), "video_search method");
	
		ok($pix->show_data_structure($img_search), "show_data_structure for image_search method");
		
		ok($pix->show_data_structure($vid_search), "show_data_structure for video_search method");
		
		done_testing(10);
	}
};

done_testing;
