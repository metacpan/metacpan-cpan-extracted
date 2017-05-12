
package Devel::CheckNet;

use strict;
use warnings;

our $VERSION = '0.001';

use LWP::UserAgent ();

sub can_http {
    my $self = shift;
    my $url  = shift;

    my %ua_options = (
        agent                 => 'devel-checknet/' . $VERSION,
        timeout               => 10,
        requests_redirectable => [],
        parse_head            => 0,
    );
    my $ua = LWP::UserAgent->new();
    my $r  = $ua->head($url);
    return ( !$r->is_error ) ? 1 : 0;
}

1;

__END__

=head1 NAME

Devel::CheckNet - 

=head1 SYNOPSIS

  use Devel::CheckNet ();

  $ok = Devel::CheckNet->can_http( 'http://search.cpan.org/' );

