package WebService::FogBugz::XML::Event;

use Moose;
use v5.10;

use namespace::autoclean;
use Data::Dumper;

has type => (is => 'rw', isa => 'Int');
has text => (is => 'rw', isa => 'Str');

sub from_xml {
    my ($class, $dom) = @_;

    my $self = $class->new(
        type    => $dom->findvalue('evt'),
        text    => $dom->findvalue('s'),
        );
    return $self;
    }

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

WebService::FogBugz::XML::Event

=head1 ATTRIBUTES

=head2 type

Type of the event.

=head2 text

Text of the event.

=head1 TODO

 Event type enumeration.

=head1 AUTHORS, COPYRIGHT & LICENSE

See L<WebService::FogBugz::XML>.

=cut
