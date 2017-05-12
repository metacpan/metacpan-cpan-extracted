package Time::Progress::Stored::Storage;
$Time::Progress::Stored::Storage::VERSION = '1.002';
use Moo;
use true;

=head1 NAME

Time::Progress::Stored::Storage - Base class for storing and retrieving report data structures

=head1 METHODS

=head2 store($id, $content) : Bool

Store the current report $content (a data structure) under the $id
key.

=cut

sub store {
    my $self = shift;
    my ($id, $content) = @_;
    croak("Abstract");
}

=head2 retrieve($id) : $content | undef

Retrieve the current report $content under the $id key, or undef if
none was found.

=cut

sub retrieve {
    my $self = shift;
    my ($id) = @_;
    croak("Abstract");
}
