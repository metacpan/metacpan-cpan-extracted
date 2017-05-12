package Time::Strptime::TimeZone;
use strict;
use warnings;
use utf8;

use DateTime::TimeZone;
use Scalar::Util qw/blessed/;

use constant UNIX_EPOCH => 62135683200;

our $DEFAULT = 'local';

sub new {
    my ($class, $name) = @_;
    $name ||= $DEFAULT;
    my $tz = blessed $name && $name->isa('DateTime::TimeZone') ? $name : DateTime::TimeZone->new(name => $name);
    return bless [$tz, 0] => $class;
}

sub name { $_[0]->[0]->name }

sub local_rd_as_seconds { $_[0]->[1] + UNIX_EPOCH }

sub set_timezone { $_[0]->[0] = DateTime::TimeZone->new(name => $_[1]) }

sub offset {
    $_[0]->[1] = $_[1];
    $_[0]->[0]->offset_for_local_datetime($_[0]);
}

1;
__END__
