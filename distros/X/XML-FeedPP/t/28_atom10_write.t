# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 58;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
	my $Ftitle = 'Kawa.net_XP';
	my $Fdescription = 'this_is_a_test.';
	my $FpubDate = '2007-08-19T05:33:00+09:00';
	my $Fcopyright = 'Yusuke_Kawasaki';
	my $Flink = 'http://www.kawa.net/';
	my $Flanguage = 'ja';
	my $Fimage = 'http://www.kawa.net/xp/images/xp-title-128x32.gif';
	my $Ititle = 'XML::FeedPP';
	my $Idescription = 'testing_this_module!';
	my $IpubDate = '2007-08-19T05:36+09:00';
	my $Icategory1 = 'Apple';
	my $Icategory2 = 'Orange';
	my $Icategory3 = 'Melon';
	my $Iauthor = 'Kawasaki_Yusuke';
	my $Iguid = 'urn:uuid:4744168A-4DCB-11DC-B682-AF437E717A71';
	my $Ilink = 'http://www.kawa.net/works/perl/feedpp/feedpp-e.html';
# ----------------------------------------------------------------
{
	my $atom = XML::FeedPP::Atom::Atom03->new();
	ok( ref $atom, 'XML::FeedPP::Atom::Atom03' );
	&roundtrip( $atom );

	my $xml = $atom->to_string();
    like( $xml, qr{ <title[^>]*>        $Ftitle     </title>    }sx, 'xml feed title' );
    like( $xml, qr{ <tagline[^>]*>  $Fdescription   </tagline>  }sx, 'xml feed tagline' );
    like( $xml, qr{ <modified>        \Q$FpubDate\E </modified> }sx, 'xml feed modified' );
    like( $xml, qr{ <copyright>         $Fcopyright </copyright>}sx, 'xml feed copyright' );
    like( $xml, qr{ <link[^>]*href="    $Flink      "           }sx, 'xml feed link alternative' );
    like( $xml, qr{ <feed[^>]*xml:lang="$Flanguage  "           }sx, 'xml feed lang' );
    like( $xml, qr{ <link[^>]*href="    $Fimage     "           }sx, 'xml feed link icon' );
    
    my $entry = ( $xml =~ m{ <entry>(.*)</entry> }xs )[0];
    like( $entry, qr{ <link[^>]*href="      $Ilink      "           }sx, 'xml item link alternative' );
    like( $entry, qr{ <title[^>]*>          $Ititle     </title>    }sx, 'xml item title' );
    like( $entry, qr{ <content[^>]*>        $Idescription   </content>  }sx, 'xml item content' );
    like( $entry, qr{ <modified>          \Q$IpubDate\E </modified> }sx, 'xml item modified' );
    like( $entry, qr{ <author>\s*<name>     $Iauthor    </name>     }sx, 'xml item author name' );
    like( $entry, qr{ <id>                  $Iguid      </id>       }sx, 'xml item id' );
}
# ----------------------------------------------------------------
{
	my $atom = XML::FeedPP::Atom::Atom10->new();
	ok( ref $atom, 'XML::FeedPP::Atom::Atom10' );
	&roundtrip( $atom );

	my $xml = $atom->to_string();

    like( $xml, qr{ <title[^>]*>        $Ftitle     </title>    }sx, 'xml feed title' );
    like( $xml, qr{ <content[^>]*>    $Fdescription </content>  }sx, 'xml feed content' );
    like( $xml, qr{ <updated>         \Q$FpubDate\E </updated>  }sx, 'xml feed updated' );
    like( $xml, qr{ <rights>            $Fcopyright </rights>   }sx, 'xml feed rights' );
    like( $xml, qr{ <link[^>]*href="    $Flink      "           }sx, 'xml feed link alternative' );
    like( $xml, qr{ <feed[^>]*xml:lang="$Flanguage  "           }sx, 'xml feed lang' );
    like( $xml, qr{ <link[^>]*href="    $Fimage     "           }sx, 'xml feed link icon' );
    
    my $entry = ( $xml =~ m{ <entry>(.*)</entry> }xs )[0];
    like( $entry, qr{ <link[^>]*href="      $Ilink      "           }sx, 'xml item link alternative' );
    like( $entry, qr{ <title[^>]*>          $Ititle     </title>    }sx, 'xml item title' );
    like( $entry, qr{ <content[^>]*>        $Idescription   </content>  }sx, 'xml item content' );
    like( $entry, qr{ <updated>           \Q$IpubDate\E </updated>  }sx, 'xml item updated' );
    like( $entry, qr{ <author>\s*<name>     $Iauthor    </name>     }sx, 'xml item author name' );
    like( $entry, qr{ <id>                  $Iguid      </id>       }sx, 'xml item id' );

	my $cat = $atom->get_item(0)->category;
	is( $cat->[0], $Icategory1, 'category 1' );
	is( $cat->[1], $Icategory2, 'category 2' );
	is( $cat->[2], $Icategory3, 'category 3' );
}
# ----------------------------------------------------------------
sub roundtrip {
	my $atom = shift;
	$atom->title( $Ftitle );
	$atom->description( $Fdescription );
	$atom->pubDate( $FpubDate );
	$atom->copyright( $Fcopyright );
	$atom->link( $Flink );
	$atom->language( $Flanguage );
	$atom->image( $Fimage );
	is( $atom->title, 		$Ftitle, 		'roundtrip feed title' );
	is( $atom->description, $Fdescription, 	'roundtrip feed description' );
	is( $atom->pubDate, 	$FpubDate, 		'roundtrip feed pubDate' );
	is( $atom->copyright, 	$Fcopyright, 	'roundtrip feed copyright' );
	is( $atom->link, 		$Flink, 		'roundtrip feed link' );
	is( $atom->language, 	$Flanguage, 	'roundtrip feed language' );
	is( $atom->image, 		$Fimage, 		'roundtrip feed image' );

	my $item = $atom->add_item( $Ilink );
	$item->title( $Ititle );
	$item->description( $Idescription );
	$item->pubDate( $IpubDate );
	$item->category( $Icategory1, $Icategory2, $Icategory3 );
	$item->author( $Iauthor );
	$item->guid( $Iguid );

	is( $item->link, 		$Ilink, 		'roundtrip item link' );
	is( $item->title, 		$Ititle, 		'roundtrip item title' );
	is( $item->description, $Idescription, 	'roundtrip item description' );
	is( $item->pubDate, 	$IpubDate, 		'roundtrip item pubDate' );
#	is( $item->category, 	$Icategory, 	'roundtrip item category' );
	is( $item->author, 		$Iauthor, 		'roundtrip item author' );
	is( $item->guid, 		$Iguid, 		'roundtrip item guid' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
