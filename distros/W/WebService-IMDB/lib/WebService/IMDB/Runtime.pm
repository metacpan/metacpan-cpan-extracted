# $Id: Runtime.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Runtime

=cut

package WebService::IMDB::Runtime;

use strict;
use warnings;

our $VERSION = '0.05';

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

use DateTime::Duration;


sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift or die;

    if (exists $data->{'time'}) {
	return DateTime::Duration->new('seconds' => $data->{'time'});

    } else {
	croak "Unable to parse runtime";
    }
}

1;
