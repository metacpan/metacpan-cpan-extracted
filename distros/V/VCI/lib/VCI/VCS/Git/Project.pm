package VCI::VCS::Git::Project;
use Moose;

use Cwd qw(abs_path);
use Git ();

extends 'VCI::Abstract::Project';

has 'x_git' => (is => 'ro', isa => 'Git', lazy_build => 1);

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
    $self->_name_never_starts_with_slash();
}

sub _build_x_git {
    my $self = shift;
    my $repo = Git->repository(abs_path($self->repository->root) . '/'
                               . $self->name);
    if ($self->vci->debug) {
        print STDERR "Connected to Git, Version: " . $repo->version . "\n";
    }
    return $repo;
}

sub x_do {
    my ($self, $command, $args, $as_string) = @_;
    $args ||= [];
    my $git = $self->x_git;
    if ($self->vci->debug) {
        print STDERR "Calling [" . $git->exec_path . "/git $command "
            . join(' ', @$args) . "] on [" . $git->repo_path . "]\n";
    }
    if ($as_string) {
        return scalar $git->command($command, @$args);
    }
    return [$git->command($command, @$args)];
}

# Because git is so fast with individual operations, we don't pull in
# every log detail for the whole history with this, like we do for other
# drivers. We just get the list of revision IDs and then the commits can
# populate themselves.
sub _build_history {
    my $self = shift;
    my $lines = $self->x_do('log',
        ['--pretty=format:%H%n%cD%n%cn <%ce>%n%an <%ae>%n', '--reverse', '-m'],
        1);
    my @messages = split("\n\n", $lines);
    my @commits;
    foreach my $message (@messages) {
        my ($id, $time, $committer, $author) = split("\n", $message);
        # Times start with "Wed" or "Thu", etc., which Date::Parse can't handle.
        $time =~ s/^\w{3}, //;
        push(@commits, $self->commit_class->new(revision => $id,
            time => $time, committer => $committer, author => $author,
            project => $self));
    }
    return $self->history_class->new(commits => \@commits, project => $self);
}

__PACKAGE__->meta->make_immutable;

1;
