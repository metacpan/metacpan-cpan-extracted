package VCI::VCS::Git::Committable;
use Moose::Role;

has 'x_one_of' => (is => 'ro', isa => 'ArrayRef[Str]',
                   predicate => 'has_x_one_of');

sub _build_revision {
    my $self = shift;
    
    # When we have a moved or copied file in a "whatchanged", it can
    # have more than one parent rev. If it does, then we have to figure
    # out which revision the copied/moved file actually came from.
    if ($self->has_x_one_of) {
        my $one_of = $self->x_one_of;
        return $one_of->[0] if @$one_of == 1;
        my $path = $self->path->stringify;
        foreach my $rev (@$one_of) {
            my $result = eval {
                $self->project->x_do('rev-parse', ["$rev:$path"])
            };
            return $rev if defined $result;
        }
    }
    
    my $head_rev = $self->project->x_do('rev-list',
        ['--all', '--max-count=1', '--', $self->path->stringify], 1);
    chomp($head_rev);
    return $head_rev;
}

sub _build_time {
    my $self = shift;
    my $time = $self->project->x_do('log', ['-1', '--pretty=format:%cD', '--',
                                            $self->path->stringify], 1);
    chomp($time);
    $time =~ s/^\w{3}, //;
    return $time;
}

1;
