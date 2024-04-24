package # hide from Pause
    Treex::PML::Resource::URI;

=head1 NAME

Treex::PML::Resource::URI

=head1 DESCRIPTION

Referenced files coming from a resource path are blessed to this class
so Treex::PML knows where they came from and correctly saves their
names without relative paths.

=head1 Methods

=over 4

=item new

The constructor, see L<URI::file>.

=back

=cut

use parent 'URI::file';

# URI::file can't be inherited from, its constructor always creates
# URI::file objects.
sub new {
    my ($class, @params) = @_;
    my $o = 'URI::file'->new(@params);
    bless $o, $class
}

1
