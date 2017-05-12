package XML::Atom::Syndication::Test::Util;
use strict;
use warnings;

use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( get_feed );

use base qw( Exporter );

sub get_feed {
    my $file = shift;
    $file = File::Spec->catfile('x', $file);
    my $fh;
    open $fh, $file or die "couldn't open $file";
    require XML::Atom::Syndication::Feed;
    my $feed = XML::Atom::Syndication::Feed->new($fh)
      or die XML::Atom::Syndication::Feed->errstr;
    close $fh;
    $feed;
}

1;
