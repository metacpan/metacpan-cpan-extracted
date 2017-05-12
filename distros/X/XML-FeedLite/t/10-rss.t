use Test::More tests => 1;
use XML::FeedLite::File;

my $file = "t/example-rss-1.0";
my $xfl  = XML::FeedLite::File->new($file);
my $data = $xfl->entries();

is_deeply($data, {
		  $file => [
					  {
					   'link' => [
						      {
						       'content' => 'http://xml.com/pub/2000/08/09/xslt/xslt.html'
						      }
						     ],
					   'title' => [
						       {
							'content' => 'Processing Inclusions with XSLT'
						       }
						      ],
					   'description' => [
                                                        {
							 'content' => '
    Processing document inclusions with general XML tools can be 
    problematic. This article proposes a way of preserving inclusion 
    information through SAX-based processing.
   '
                                                        }
							    ]
					  },
					  {
					   'link' => [
						      {
						       'content' => 'http://xml.com/pub/2000/08/09/rdfdb/index.html'
						      }
						     ],
					   'title' => [
						       {
							'content' => 'Putting RDF to Work'
						       }
						      ],
					   'description' => [
							     {
							      'content' => '
    Tool and API support for the Resource Description Framework 
    is slowly coming of age. Edd Dumbill takes a look at RDFDB, 
    one of the most exciting new RDF toolkits.
   '
							     }
							    ]
					  }
					 ]
		 }, "data structures match");
