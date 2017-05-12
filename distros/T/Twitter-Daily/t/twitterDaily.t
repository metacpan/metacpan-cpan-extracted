
use strict;
use warnings;

use Test::More tests => 27;
use Twitter::Daily;

my $twitter = Test::Mock::Twitter->new();
my $blog = Test::Mock::Blog->new();
my $entry = Test::Mock::EntryBuilder->new();

ok ( defined $twitter, "Test::Mock::Twitter object construction");    
ok ( defined $blog, "Test::Mock::Blog object construction");    
ok ( defined $entry, "Test::Mock::EntryBuilder object construction");    

my $daily = Twitter::Daily->new( 'TWuser' => 'user',                                                                               
					 'twitter' => $twitter,
                     'blog' => $blog,
                     'entry' => $entry,
                     'silent' => 1 );
$twitter->reset();
$blog->reset();
$entry->reset();

ok ( defined $daily, "Twitter::Daily object construction");    
is ( $twitter->{'user_timeline'}, 0, "Twitter: No call to user_timeline" );
is ( $blog->{'publish'}, 0, "Blog: No call to publish" );
is ( $blog->{'quit'}, 0, "Blog: No call to close" );
is ( $entry->{'getEntry'}, 0, "Entry builder: No call to getEntry" );
is ( $entry->{'setBody'}, 0, "Entry builder: No call to setBody" );
is ( $entry->{'setTitle'}, 0, "Entry builder: No call to setTitle" );
is ( $entry->{'addLine'}, 0, "Entry builder: No call to addLine" );


my @timeline = (
	{ 'created_at' => 'Sun, Feb 13 11:11:11 ART 2011', 'text' => 'This line should be accepted'  },
	{ 'created_at' => 'Sat, Feb 12 11:11:11 ART 2011', 'text' => 'This line should NOT be accepted'  },
);

$twitter->setUserTimeline( \@timeline );

my $date = 'Sun, Feb 13 00:00:01 ART 2011';
my $title = 'My Title';

my $result = $daily->postNews($date, $title);

is ($result, 1, "Daily postNews: checking result");

is ( $twitter->{'user_timeline'}, 1, "Twitter: No call to user_timeline" );
is ( $blog->{'publish'}, 1, "Blog: Ccall to publish" );
is ( $blog->{'quit'}, 0, "Blog: Call to close" );
is ( $entry->{'getEntry'}, 1, "Entry builder: Call to getEntry" );
is ( $entry->{'setBody'}, 0, "Entry builder: Call to setBody" );
is ( $entry->{'setTitle'}, 1, "Entry builder: Call to setTitle" );
is ( $entry->{'addLine'}, 1, "Entry builder: Call to addLine" );

$twitter->reset();
$blog->reset();
$entry->reset();

$result = $daily->close();

is ($result, 1, "Daily postNews: checking result");

is ( $twitter->{'user_timeline'}, 0, "Twitter: No call to user_timeline" );
is ( $blog->{'publish'}, 0, "Blog: No call to publish" );
is ( $blog->{'quit'}, 1, "Blog: No call to close" );
is ( $entry->{'getEntry'}, 0, "Entry builder: No call to getEntry" );
is ( $entry->{'setBody'}, 0, "Entry builder: No call to setBody" );
is ( $entry->{'setTitle'}, 0, "Entry builder: No call to setTitle" );
is ( $entry->{'addLine'}, 0, "Entry builder: No call to addLine" );

package Test::Mock::Twitter;

sub new () {
    my $class = shift;
    my $this;
    my @timeline;
    
    $this->{'user_timeline'} = 0;
    $this->{'timeline'} = \@timeline;
    
    bless $this, $class;
};

sub user_timeline {
	my $this = shift;
	$this->{'user_timeline'}++;
	
	return $this->{'timeline'};
};

sub setUserTimeline {
	my $this = shift;
	my $timeline = shift; ## array ref
	
	$this->{'timeline'} = $timeline;
}

sub reset() {
	my $this = shift;
	$this->{'user_timeline'} = 0;
};


package Test::Mock::Blog;

use Twitter::Daily::Blog::Base;
use Exporter();
our @ISA;
@ISA = qw(Exporter Twitter::Daily::Blog::Base);

sub new () {
    my $class = shift;
    my $this;
    
    $this->{'publish'} = 0;
    $this->{'quit'} = 0;
    
    bless $this, $class;
};

sub publish {
    my $this = shift;
    
    $this->{'publish'}++;
    return 1;
};


sub quit {
    my $this = shift;
    
    $this->{'quit'}++;
};
    
    
sub reset {
    my $this = shift;
    
    $this->{'publish'} = 0;
    $this->{'close'} = 0;
}

package Test::Mock::EntryBuilder;

sub new () {
    my $class = shift;
    my $this;
    
    $this->{'setTitle'} = 0;
    $this->{'setBody'} = 0;
    $this->{'getEntry'} = 0;
    $this->{'addLine'} = 0;
    
    bless $this, $class;
	
};

sub setTitle {
	my $this = shift;
	
	$this->{'setTitle'}++;
};


sub setBody {
	my $this = shift;
	
    $this->{'setBody'}++;
}

sub getEntry {
	my $this = shift;
	
    $this->{'getEntry'}++;
}

sub addLine {
	my $this = shift;
	
    $this->{'addLine'}++;
}

sub reset {
	my $this = shift;
	
    $this->{'setTitle'} = 0;
    $this->{'setBody'} = 0;
    $this->{'getEntry'} = 0;
    $this->{'addLine'} = 0;
}

1;
