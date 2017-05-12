# $Id: SearchResult.pm,v 1.3 2003/09/16 09:08:53 cvspub Exp $
package WWW::Google::Groups::SearchResult;

use strict;
use Storable qw(dclone);

sub new {
    my ($pkg, $arg, $threads) = @_;
    my $hash = dclone $arg;
    $hash->{_threads} = $threads;
    $hash->{_thread_no} = 0;
    bless $hash, $pkg;
}

use WWW::Mechanize;
sub next_thread {
    my $self = shift;
    new WWW::Google::Groups::Thread($self, shift @{$self->{_threads}});
}



1;
__END__
