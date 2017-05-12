package VCI::VCS::Hg::Project;
use Moose;
use MooseX::Method;

use XML::Simple qw(:strict);

use VCI::Util;

extends 'VCI::Abstract::Project';

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
    $self->_name_never_starts_with_slash();
}

method 'get_file' => named (
    path     => { isa => 'VCI::Type::Path', coerce => 1, required => 1 },
    revision => { isa => 'Str' },
) => sub {
    my $self = shift;
    my ($params) = @_;
    
    if (defined $params->{revision} && $params->{revision} eq 'tip') {
        $params->{revision} = $self->head_revision;
    }

    # MooseX::Method always has a hash key for each parameter, even if they
    # weren't passed by the caller.
    delete $params->{$_} foreach (grep(!defined $params->{$_}, keys %$params));
    return $self->SUPER::get_file(@_);
};

sub x_get {
    my ($self, $path) = @_;
    my @path = ref $path eq 'ARRAY' ? @$path : $path;
    return $self->repository->x_get([$self->name, @path]);
};

# Currently, we just get the first items listed in the changelog, and
# just assume that changesets exist from this one back to #1. The
# changesets themselves can easily modify themselves.
sub _build_history {
    my $self = shift;
    return $self->history_class->x_from_rss('', $self);
}

sub _build_head_revision {
    my $self = shift;
    if (exists $self->{history}) {
        my $last_commit = $self->history->commits->[-1];
        return defined $last_commit ? $last_commit->revision : undef;
    }
    
    my $raw_rev = $self->x_get('raw-rev');
    $raw_rev =~ /^# Node ID (\S+)$/ms || return undef;
    return substr($1, 0, 12);
}

__PACKAGE__->meta->make_immutable;

1;
