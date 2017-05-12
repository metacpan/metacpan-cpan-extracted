use strict;
use Wiki::Toolkit::TestLib;
use Test::More;
use VCS::Lite;

my $newlite = (VCS::Lite->VERSION >= 0.08);
my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;
plan tests => ( 1 + $iterator->number * 18 );

use_ok( "Wiki::Toolkit::Plugin::Diff" );

while ( my $wiki = $iterator->new_wiki ) {
      print "#\n##### TEST CONFIG: Store: " . (ref $wiki->store) . "\n";

      # Add test data
      $wiki->write_node( "Jerusalem Tavern",
			 "Pub in Clerkenwell with St Peter's beer.",
			 undef,
			 { category => [ "Pubs" ]
			 }
		       );

      my %j1 = $wiki->retrieve_node( "Jerusalem Tavern");

      $wiki->write_node( "Jerusalem Tavern",
                         "Tiny pub in Clerkenwell with St Peter's beer. 
Near Farringdon station",
                         $j1{checksum},
                         { category => [ "Pubs" ]
                         }
                       );

      my %j2 = $wiki->retrieve_node( "Jerusalem Tavern");

      $wiki->write_node( "Jerusalem Tavern",
                         "Tiny pub in Clerkenwell with St Peter's beer. 
Near Farringdon station",
                         $j2{checksum},
                         { category => [ "Pubs", "Real Ale" ],
                           locale => [ "Farringdon" ]
                         }
                       );

      my %j3 = $wiki->retrieve_node( "Jerusalem Tavern");

      $wiki->write_node( "Jerusalem Tavern",
                         "Tiny pub in Clerkenwell with St Peter's beer but no food. 
Near Farringdon station",
                         $j3{checksum},
                         { category => [ "Pubs", "Real Ale" ],
                           locale => [ "Farringdon" ]
                         }
                       );
      
      $wiki->write_node( "IvorW",
      			 "
In real life:  Ivor Williams

Ideas & things to work on:

* Threaded discussion wiki
* Generify diff
* SuperSearch for Wiki::Toolkit
* Authentication module
* Autoindex generation
",
			 undef,
			 { username => 'Foo',
			   metatest => 'Moo' },
			);

      my %i1 = $wiki->retrieve_node( "IvorW");

      $wiki->write_node( "IvorW",
      			 $i1{content}."
[[IvorW's Test Page]]\n",
			 $i1{checksum},
			 { username => 'Bar',
			   metatest => 'Boo' },
			);
			
      my %i2 = $wiki->retrieve_node( "IvorW");

      $wiki->write_node( "IvorW",
      			 $i2{content}."
[[Another Test Page]]\n",
			 $i2{checksum},
			 { username => 'Bar',
			   metatest => 'Quack' },
			);

      my %i3 = $wiki->retrieve_node( "IvorW");
      my $newcont = $i3{content};
      $newcont =~ s/\n/ \n/s;
      $wiki->write_node( "IvorW",
      			 $newcont,
			 $i3{checksum},
			 { username => 'Bar',
			   metatest => 'Quack' },
			);

      $wiki->write_node( "Test",
      			 "a",
			 undef,
			 { },
			);

      %i3 = $wiki->retrieve_node( "Test");
      
      $wiki->write_node( "Test",
      			 "a\n",
			 $i3{checksum},
			 { },
			);

      pass "backend primed with test data";

      # Real tests
      my $differ = eval { Wiki::Toolkit::Plugin::Diff->new; };
      is( $@, "", "'new' doesn't croak" );
      isa_ok( $differ, "Wiki::Toolkit::Plugin::Diff" );
      $wiki->register_plugin( plugin => $differ );

      # Test ->null diff
      my %nulldiff = $differ->differences(
      			node => "Jerusalem Tavern",
      			left_version => 1,
      			right_version => 1);
      ok( !exists($nulldiff{diff}), "Diffing the same version returns empty diff");
      
      # Test ->body diff
      my %bodydiff = $differ->differences(
      			node => "Jerusalem Tavern",
      			left_version => 1,
      			right_version => 2);
      is( @{$bodydiff{diff}}, 2, "Differ returns 2 elements for body diff");
      is_deeply( $bodydiff{diff}[0], {
      			left => "== Line 0 ==\n",
      			right => "== Line 1 ==\n"},
      		"First element is line number on right");
		
      is_deeply( $bodydiff{diff}[1], $newlite ? {
      			left => '<span class="diff1">Pub </span>'.
      				'in Clerkenwell with St Peter\'s beer.'.
      				"<br />",
      			right => '<span class="diff2">Tiny pub </span>'.
      				'in Clerkenwell with St Peter\'s beer.'.
      				'<span class="diff2"><br />'.
      				"\nNear Farringdon station</span>".
      				"<br />",
      				} : {
      			left => '<span class="diff1">Pub </span>'.
      				'in Clerkenwell with St Peter\'s beer.'.
      				"<br />\n",
      			right => '<span class="diff2">Tiny pub </span>'.
      				'in Clerkenwell with St Peter\'s beer.'.
      				'<span class="diff2"><br />'.
      				"\nNear Farringdon station</span>".
      				"<br />\n",
      				},
      		"Differences highlights body diff with span tags");
      		
      # Test ->meta diff
      my %metadiff = $differ->differences(
      			node => "Jerusalem Tavern",
      			left_version => 2,
      			right_version => 3);
      is( @{$metadiff{diff}}, 2, "Differ returns 2 elements for meta diff");
      is_deeply( $metadiff{diff}[0], {
      			left =>  "== Line 2 ==\n",
      			right => "== Line 2 ==\n"},
      		"First element is line number on right");
      is_deeply( $metadiff{diff}[1], $newlite ? {
      			left => "\ncategory='Pubs'\nlocale='Farringdon'",
      			right => "\ncategory='Pubs'\n".
      				'<span class="diff2">category=\'Pubs,Real Ale\'<br />'.
      				"\n</span>locale='Farringdon'",
      				} : {
      			left => "category='Pubs'",
      			right => "category='Pubs".
      				'<span class="diff2">,Real Ale\'<br />'.
      				"\nlocale='Farringdon</span>'",
      				},
      		"Differences highlights metadata diff with span tags");
      		
	# Another body diff with bracketed content
	%bodydiff = $differ->differences(
			node => 'IvorW',
			left_version => 1,
			right_version => 2);
        is_deeply( $bodydiff{diff}[0], {
      			left => "== Line 11 ==\n",
      			right => "== Line 11 ==\n"},
      		"Diff finds the right line number on right");
        is_deeply( $bodydiff{diff}[1], $newlite ? {
        		left => "\nmetatest='Moo'\nmetatest='Boo'",
        		right => "\nmetatest='Moo'\n".
				'<span class="diff2">'.
        			"[[IvorW's Test Page]]<br />\n".
        			"<br />\n</span>".
        			"metatest='Boo'"
        			} : {
        		left => "metatest='".
        			'<span class="diff1">Moo</span>\'',
        		right => '<span class="diff2">'.
        			"[[IvorW's Test Page]]<br />\n".
        			"<br />\n</span>".
        			"metatest='".
        			'<span class="diff2">Boo</span>\'',
        			},
        	"Diff scans words correctly");
        # And now a check for framing
	%bodydiff = $differ->differences(
			node => 'IvorW',
			left_version => 2,
			right_version => 3);
        is_deeply( $bodydiff{diff}[0], {
      			left => "== Line 13 ==\n",
      			right => "== Line 13 ==\n"},
      		"Diff finds the right line number on right");
        is_deeply( $bodydiff{diff}[1], $newlite ? {
        		left => "\nmetatest='Boo'\nmetatest='Quack'",
        		right => "\nmetatest='Boo'\n".
				'<span class="diff2">'.
        			"[[Another Test Page]]<br />\n".
        			"<br />\n</span>".
        			"metatest='Quack'",
        			} : {
        		left => "metatest='".
        			'<span class="diff1">Boo</span>\'',
        		right => '<span class="diff2">'.
        			"[[Another Test Page]]<br />\n".
        			"<br />\n</span>".
        			"metatest='".
        			'<span class="diff2">Quack</span>\'',
        			},
        	"Diff frames correctly");
	# Trailing whitespace test 1
	%bodydiff = $differ->differences(
			node => 'IvorW',
			left_version => 3,
			right_version => 4);
    
    ok(!exists($bodydiff{diff}), 'No change found for trailing whitespace');

	# Trailing whitespace test 2
	%bodydiff = $differ->differences(
			node => 'Jerusalem Tavern',
			left_version => 3,
			right_version => 4);
        is_deeply( $bodydiff{diff}[0], {
      			left => "== Line 0 ==\n",
      			right => "== Line 0 ==\n" },
      		"Diff finds the right line numbers");
        is_deeply( $bodydiff{diff}[1], $newlite ? {
        		left => "Tiny pub in Clerkenwell with St Peter's beer".
        		        ".<br />",
        		right => "Tiny pub in Clerkenwell with St Peter's beer".
        			' <span class="diff2">but no food</span>.'.
        			"<br />",
        			} : {
        		left => "Tiny pub in Clerkenwell with St Peter's beer".
        		        ".<br />\n",
        		right => "Tiny pub in Clerkenwell with St Peter's beer".
        			' <span class="diff2">but no food</span>.'.
        			"<br />\n",
        			},
        	"Diff handles trailing whitespace correctly");
        eval {
               $differ->differences(
                        node => 'Test',
                        left_version => 1,
                        right_version => 2 ) };
        is( $@, "", "differences doesn't die when only difference is a newline");
}
