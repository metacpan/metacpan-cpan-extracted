package VCI::VCS::Cvs::Diff;
use Moose;

extends 'VCI::Abstract::Diff';

our $_header_part;
BEGIN {
    # This matches the "wrong" cvsps diff headers.
    $_header_part =
        '([^:]+?)\t\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+ [\-+]\d{4}';
}
use constant DIFF_HEADER => qr/^(--- $_header_part\n\+\+\+ $_header_part)$/mso;

sub _transform_filename {
    my ($self, $name) = @_;
    my $project = $self->project->name;
    $name =~ s|^\Q$project\E/||;
    # cvsps adds :revision to the end of file names.
    $name =~ s/:[\d+\.]+$//;
    return $name;
}

# We have to add "diff -u" headers that cvsps misses.
override _build__parsed => sub {
    my $self = shift;
    my $raw = $self->raw;
    my $old_raw = $raw;
    my $diff_re = DIFF_HEADER;
    $raw =~ s/$diff_re/diff -u $2 $3\n$1/g;
    $self->{raw} = $raw;
    my $parsed = super;
    $self->{raw} = $old_raw;
    return $parsed;
};

__PACKAGE__->meta->make_immutable;

1;
