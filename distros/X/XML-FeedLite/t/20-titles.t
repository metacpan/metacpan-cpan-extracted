use Test::More tests => 1;
use XML::FeedLite::File;

my $xfl  = XML::FeedLite::File->new([qw(t/example-rss-1.0
					t/example-rss-2.0
					t/example-1-atom-1.0
					t/example-2-atom-1.0
					t/example-3-atom-1.0)]);
my $data = $xfl->meta();
is_deeply($data, {
		  't/example-3-atom-1.0' => {
					     'title' => 'dive into mark'
					    },
		  't/example-rss-2.0'    => {
					     'title' => 'Liftoff News'
					    },
		  't/example-2-atom-1.0' => {
					     'title' => 'Example Feed'
					    },
		  't/example-1-atom-1.0' => {
					     'title' => 'Example Feed'
					    },
		  't/example-rss-1.0'    => {
					     'title' => 'XML.com'
					    }
		 }, "titles processed correctly");
