package Time::Progress::Stored::Storage::Memory;
$Time::Progress::Stored::Storage::Memory::VERSION = '1.002';
use Moo;
use true;
extends "Time::Progress::Stored::Storage";

=head1 NAME

Time::Progress::Stored::Storage::Memory - Store the reports in-memory

=head1 DESCRIPTION

This is mostly for testing.

Store the reports in serialized JSON, to emulate storing them in an
external server, which is better than just keeping the hashref around
would be.

=cut

use JSON::Tiny qw/ encode_json decode_json /;



=head1 PROPERTIES

=cut

has id__report => ( is => "lazy" );
sub _build_id__report { +{} }



=head1 METHODS

=head2 store($id, $content) : Bool

Store the current report $content (a data structure) under the $id
key.

=cut

sub store {
    my $self = shift;
    my ($id, $content) = @_;
    $self->id__report->{ $id } = encode_json( $content );
}

=head2 retrieve($id) : $content | undef

Retrieve the current report $content under the $id key, or undef if
none was found.

=cut

sub retrieve {
    my $self = shift;
    my ($id) = @_;
    my $report_json = $self->id__report->{ $id } // return undef;
    return decode_json( $report_json );
}
