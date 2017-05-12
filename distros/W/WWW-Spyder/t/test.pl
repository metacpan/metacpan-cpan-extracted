# Before "make install" is performed this script should be runnable with
# "make test." After "make install" it should work as "perl test.pl."
#=====================================================================
use WWW::Spyder;
BEGIN { $| = 1 }
my $loaded = 1;
END { print "NOT OK\n" unless $loaded }
#=====================================================================
use Test::Simple tests => 20;
#------------------------------------------------------------------
# we'll only use one, selected randomly
my @test_domains = qw(
                      http://www.yahoo.com
                      http://www.msn.com
                      http://www.drudgereport.com
                      http://w3.org
                      http://www.perl.org
                      );
#------------------------------------------------------------------
my $spyder = WWW::Spyder->new(exit_on => { pages => 4 });
# we need > 1 to make sure it's bailing out correctly sometimes
# plus, spyders share same exit and we have two in here
ok( $spyder->isa('WWW::Spyder'), 'WWW::Spyder->new' );
#------------------------------------------------------------------
ok( $spyder->UA->timeout('5'), 'Resting timeout on UserAgent' );
#------------------------------------------------------------------
ok( $spyder->verbosity(5), 'Setting VERBOSITY to 5' );
#------------------------------------------------------------------
my @attr = $spyder->show_attributes;
ok( @attr > 1, "Intial attributes: " . serial(@attr).'.' );
#------------------------------------------------------------------
my $url = 'http://sedition.com/hit_cpan_for_spyder.html';
$spyder->seed($url);
ok( $page = $spyder->crawl, 'Spyder->crawl' );
#------------------------------------------------------------------
ok( ($page and $page->isa(WWW::Spyder::Page)),
    'Spyder->crawl returned a WWW::Spyder::Page' );
#------------------------------------------------------------------
ok( ($page and $page->title), 'Title of page: ' . $page->title );
#------------------------------------------------------------------
ok( ($page and $page->url), 'URL of page: ' . $page->url );
#------------------------------------------------------------------
ok( defined($spyder->spyder_data), 
    'Kbs: ' . $spyder->spyder_data );
#------------------------------------------------------------------
my @attr = $spyder->show_attributes;
ok( @attr > 1, "Initial attributes: " . serial(@attr).'.' );
#------------------------------------------------------------------
my $spyder2 = WWW::Spyder->new(exit_on => { pages => 10 });
my $domain = $test_domains[rand(@test_domains)] ;
ok( $spyder2->seed( $domain ), 'Seeding: ' . $domain );
#------------------------------------------------------------------
ok($spyder2->verbosity(2), 'Setting VERBOSITY to 2' );
#------------------------------------------------------------------
ok( $spyder2->bell(1), 'Turning on \a (bell)' );
#------------------------------------------------------------------
print "Trying to crawl 4 pages on $domain\n";
my $count = 0;
while ( my $page = $spyder2->crawl ) {
    next unless $page->title;
    ok( $page->title,  ++$count . '/4-->> ' 
        . $page->title );
    last if $count >= 4; 
}
#------------------------------------------------------------------
my @attr = $spyder2->show_attributes;
ok( @attr > 1, "Attributes: " . serial(@attr).'.' );
#------------------------------------------------------------------
ok( $spyder2->spyder_time, 'Time: ' . $spyder2->spyder_time(1) );
#------------------------------------------------------------------
ok( defined($spyder2->spyder_data),
    "Kbs: ".$spyder2->spyder_data );
#------------------------------------------------------------------

#=====================================================================
sub serial {
    join(', ', @_[0..$#_-1]) .
        (@_>2 ? ',':'' ) .
            (@_>1 ? (' and ' . $_[-1]) : $_[-1]);
}
