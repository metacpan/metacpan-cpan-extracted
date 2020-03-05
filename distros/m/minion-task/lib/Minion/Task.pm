package Minion::Task;
use Mojo::Base -base;

use Mojo::Loader qw(load_class);
use Mojo::Server;

our $VERSION = '0.0.2';

has [qw/id guard parent_id user/];

has 'app' => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') }, weak => 1;

has 'args' => sub { {} };

has 'chain' => sub { shift->args->{ chain } || [] };

has 'children' => sub {
    my $self = shift;

    my @children = @{ $self->subtasks };
    push(@children, @{ $self->chain });

    return \@children;
};

has 'error' => 'Failed.';

has 'failed' => sub { 0 };

has 'finish' => 'Action complete.';

has 'name' => sub { ref(shift) };

has 'options' => sub {
    my $self = shift;
    my $options = {
        queue   => 'default',
    };

    if ($self->parent_id) {
        $options->{ parents } = [$self->parent_id];
    }

    return $options;
};

has 'subtasks' => sub { [] };

has 'tags' => sub {
    my $self = shift;

    my @tags = $self->tagify($self->args);

    return \@tags;
};


=head2 dispatch

Dispatch the task

=cut

sub dispatch {
    my $self = shift;

    return $self->start;
}

=head2 processChain

Process the chain of tasks

=cut

sub processChain {
    my $self = shift;

    my @children = @{ $self->children };
    my $task = shift(@children);

    my $e = load_class($task);

    $self->app->fatal("Loading '$task' failed: $e") if ($e);

    $task->new(app => $self->app, args => $self->args, parent_id => $self->id)
        ->withChain(\@children)
        ->dispatch;
}

=head2 start

Start the task

=cut

sub start {
    my $self = shift;

    my $ok = $self->run(@_);

    # When current task was successful,
    # and there are children tasks defined,
    # try to process them 
    if ($ok && scalar(@{ $self->children })) {
        $self->processChain;
    }

    return $ok;
}

=head2 tag

Convert name and value to a tag

=cut

sub tag {
    my ($self, $name, $value) = @_;

    return sprintf("%s %s", $name, $value);
}

=head2 tagify

Convert a hash to an array of tags

=cut

sub tagify {
    my ($self, $args, $prefix) = @_;
    $prefix ||= '';

    my @tags;

    for my $key (sort(keys(%{ $args }))) {
        if (ref($args->{ $key }) eq 'HASH') {
            push(@tags, $self->tagify($args->{ $key }, $prefix . $key . ' '));
        } elsif (ref($args->{ $key }) eq 'ARRAY') {
            push(@tags, $self->tag($prefix . $key, join(', ', @{ $args->{ $key } })));
        } else {
            push(@tags, $self->tag($prefix . $key, $args->{ $key }));
        }
    }

    return @tags;
}

1;

=encoding utf8

=head1 NAME

Minion::Task - A task boilerplate for Minion

=head1 SYNOPSIS

    package MyApp::Tasks::HelloWorld;
    use Mojo::Base 'Minion::Task';

    ... defined your own logic here ...

=head1 DESCRIPTION

L<Minion::Task> is a package that provides a way of handling minion tasks

=head1 ATTRIBUTES

L<Minion::Task> inherits all attributes from L<Mojo::Base>.

=head1 METHODS

L<Minion::Task> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 dispatch

    $task->dispatch;

Is basically a link to start method.

=head2 processChain

    $task->processChain;

If current task has subtasks or if there's something defined in the args->{ chain },
those tasks will be dispatched.

=head2 start

    $task->start;

Start processing the task.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin::Minion::Overview>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
