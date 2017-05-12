use Test::More tests => 1;
use XML::FeedLite::File;

my $file = "t/example-rss-2.0";
my $xfl  = XML::FeedLite::File->new($file);
my $data = $xfl->entries();

is_deeply($data, {
		  $file => [
			    {
			     'link' => [
					{
					 'content' => 'http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp'
					}
				       ],
			     'guid' => [
					{
					 'content' => 'http://liftoff.msfc.nasa.gov/2003/06/03.html#item573'
					}
				       ],
			     'title' => [
					 {
					  'content' => 'Star City'
					 }
					],
			     'pubDate' => [
					   {
					    'content' => 'Tue, 03 Jun 2003 09:39:21 GMT'
					   }
					  ],
			     'description' => [
					       {
						'content' => 'How do Americans get ready to work with Russians aboard the
        International Space Station? They take a crash course in culture, language
        and protocol at Russia\'s Star City.'
					       }
					      ]
			    },
			    {
			     'link' => [
					{
					 'content' => 'http://liftoff.msfc.nasa.gov/'
					}
				       ],
			     'guid' => [
					{
					 'content' => 'http://liftoff.msfc.nasa.gov/2003/05/30.html#item572'
					}
				       ],
			     'title' => [
					 {
					  'content' => 'Space Exploration'
					 }
					],
			     'pubDate' => [
					   {
					    'content' => 'Fri, 30 May 2003 11:06:42 GMT'
					   }
					  ],
			     'description' => [
					       {
						'content' => 'Sky watchers in Europe, Asia, and parts of Alaska and Canada
        will experience a partial eclipse of the Sun on Saturday, May 31st.'
					       }
					      ]
			    },
			    {
			     'link' => [
					{
					 'content' => 'http://liftoff.msfc.nasa.gov/news/2003/news-VASIMR.asp'
					}
				       ],
			     'guid' => [
					{
					 'content' => 'http://liftoff.msfc.nasa.gov/2003/05/27.html#item571'
					}
				       ],
			     'title' => [
					 {
					  'content' => 'The Engine That Does More'
					 }
					],
			     'pubDate' => [
					   {
					    'content' => 'Tue, 27 May 2003 08:37:32 GMT'
					   }
					  ],
			     'description' => [
					       {
						'content' => 'Before man travels to Mars, NASA hopes to design new engines
        that will let us fly through the Solar System more quickly.  The proposed
        VASIMR engine would do that.'
					       }
					      ]
			    },
			    {
			     'link' => [
					{
					 'content' => 'http://liftoff.msfc.nasa.gov/news/2003/news-laundry.asp'
					}
				       ],
			     'guid' => [
					{
					 'content' => 'http://liftoff.msfc.nasa.gov/2003/05/20.html#item570'
					}
				       ],
			     'title' => [
					 {
					  'content' => 'Astronauts\' Dirty Laundry'
					 }
					],
			     'pubDate' => [
					   {
					    'content' => 'Tue, 20 May 2003 08:56:02 GMT'
					   }
					  ],
			     'description' => [
					       {
						'content' => 'Compared to earlier spacecraft, the International Space
        Station has many luxuries, but laundry facilities are not one of them.
        Instead, astronauts have other options.'
					       }
					      ]
			    }
			   ]
		 }, "data structures match");
