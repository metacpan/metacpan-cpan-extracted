package Time::Progress::Stored::Storage::Redis;
$Time::Progress::Stored::Storage::Redis::VERSION = '1.002';
use Moo;
use true;
extends "Time::Progress::Stored::Storage";

=head1 NAME

Time::Progress::Stored::Storage::Redis - Store the reports in Redis

=cut

use JSON::Tiny qw/ encode_json decode_json /;



=head1 PROPERTIES

=cut

has redis => (
    is       => "ro",
    isa      => sub { shift->isa("Redis") },
    required => 1,
);



=head1 METHODS

=head2 store($id, $content) : Bool

Store the current report $content (a data structure) under the $id
key.

=cut

sub store {
    my $self = shift;
    my ($id, $content) = @_;
    $self->redis->set( $id , encode_json($content) );
}

=head2 retrieve($id) : $content | undef

Retrieve the current report $content under the $id key, or undef if
none was found.

=cut

sub retrieve {
    my $self = shift;
    my ($id) = @_;
    my $report_json = $self->redis->get($id) // return undef;
    return decode_json( $report_json );
}
