# $Id: RunningTime.pm 7373 2012-04-09 18:00:33Z chris $

package WebService::Flixster::RunningTime;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;
our @CARP_NOT = qw(WebService::Movie WebService::Flixster::Movie);

use DateTime::Format::Duration;


sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    return DateTime::Format::Duration->new('pattern' => "%H hr. %M min.")->parse_duration($data);

}

1;
