package WebService::Mattermost::Helper::Table;

use Moo;
use Types::Standard qw(ArrayRef Enum Str);

################################################################################

has alignment => (is => 'ro', isa => ArrayRef[Enum[ qw(l r c) ]], required => 0);
has values    => (is => 'ro', isa => ArrayRef,                    required => 1);
has headers   => (is => 'ro', isa => ArrayRef,                    required => 1);

has _headers => (is => 'ro', isa => Str, lazy => 1, builder => '_build__headers');
has table    => (is => 'ro', isa => Str, lazy => 1, builder => '_build_table');

has divider => (is => 'ro', isa => Str, default => '|');
has align_l => (is => 'ro', isa => Str, default => ':----|');
has align_r => (is => 'ro', isa => Str, default => '----:|');
has align_c => (is => 'ro', isa => Str, default => ':---:|');

################################################################################

sub _build__headers {
    my $self = shift;

    my $headers = '';

    foreach my $h (@{$self->headers}) {
        $headers .= sprintf('%s %s', $self->divider, $h);
    }

    $headers .= $self->divider."\n".$self->divider;

    for (my $i = 0; $i < scalar @{$self->headers}; $i++) {
        my $al   = $self->alignment && $self->alignment->[$i] || 'l';
        my $attr = "align_${al}";

        $headers .= $self->$attr;
    }

    return $headers;
}

sub _build_table {
    my $self = shift;

    my $table = $self->_headers."\n";

    foreach my $v (@{$self->values}) {
        $table .= $self->divider;
        $table .= join($self->divider, join($self->divider, @{$v}));
        $table .= $self->divider."\n";
    }

    return $table;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::Helper::Table

=head1 DESCRIPTION

Format text as tables for Mattermost.

=head2 USAGE

    use WebService::Mattermost::Helper::Table;

    my $helper = WebService::Mattermost::Helper::Table->new({
        alignment => [ qw(r l l) ],
        headers   => [ 'ID', 'Title', 'Date Created' ],
        values    => [
            [ 1, 'First row',  '2018-09-16' ],
            [ 2, 'Second row', '2018-09-17' ],
            [ 3, 'Third row',  '2018-09-17' ],
        ],
    });

    print $helper->table;

=head1 SEE ALSO

=over 4

=item L<Mattermost Markdown|https://docs.mattermost.com/help/messaging/formatting-text.html#tables>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

