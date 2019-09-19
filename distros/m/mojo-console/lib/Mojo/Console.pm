package Mojo::Console;
use Mojo::Base 'Mojolicious::Command';

use List::Util qw(any none);

use Mojo::Console::Input;
use Mojo::Console::Output;

our $VERSION = '0.0.7';

has 'input' => sub { Mojo::Console::Input->new };
has 'max_attempts' => 10;
has 'output' => sub { Mojo::Console::Output->new };
has '_required' => 0;

sub ask {
    my ($self, $message, $default) = @_;

    my $attempts = $self->max_attempts;
    my $answer = '';

    while ((($self->_required || $attempts == 10) && !$answer) && $attempts--) {
        $self->line($message . ' ');
        
        if ($default) {
            $self->warn(sprintf('[default=%s] ', $default));
        }

        $answer = $self->input->ask || (!$self->_required && $default);
    }

    if ($attempts < 0) {
        $self->error("Please answer the question.\n");
    }

    $self->required(0);

    return $answer;
}

sub confirm {
    my ($self, $message, $default) = @_;

    my $default_yes = (any { lc($default || '') eq $_ } qw/y yes/);
    my $default_no = (any { lc($default || '') eq $_ } qw/n no/);

    my $attempts = $self->max_attempts;
    my $answer = '';

    while ((none { lc($answer) eq $_ } qw/y yes n no/) && $attempts--) {
        $self->line($message);

        $self->success(' [yes/no] ');

        if ($default) {
            $self->warn(sprintf('[default=%s] ', $default));
        }

        $answer = $self->input->ask || $default;
    }

    if ($attempts < 0) {
        $self->error("Please answer with [yes/no]\n");
    }

    return (any { lc($answer) eq $_ } qw/y yes/) ? 1 : 0;
}

sub choice {
    my ($self, $message, $choices, $default) = @_;

    my $attempts = $self->max_attempts;
    my $answer = '';

    while ((none { $answer eq $_ } @$choices) && $attempts--) {
        $self->line($message);
        $self->success(sprintf(' [%s] ', join(', ', @$choices)));

        if ($default) {
            $self->warn(sprintf('[default=%s] ', $default));
        }

        $answer = $self->input->ask || $default;
    }

    if ($attempts < 0) {
        $self->error(sprintf("Please chose one of the following options: [%s] \n", join(', ', @$choices)));
    }

    return $answer;
}

sub error {
    return shift->output->error(@_);
}

sub info {
    return shift->output->info(@_);
}

sub line {
    return shift->output->line(@_);
}

sub newline {
    return shift->output->newline(@_);
}

sub required {
    my $self = shift;

    $self->_required(shift // 1);

    return $self;
}

sub success {
    return shift->output->success(@_);
}

sub warn {
    return shift->output->warn(@_);
}

1;

=encoding utf8

=head1 NAME

Mojo::Console - Extend Mojolicious::Command to be able to ask for things from command line

=head1 SYNOPSIS

    package MyApp::Command::helloworld;
    use Mojo::Base 'Mojo::Console';

    sub run {
        my $self = shift;

        my $name = $self->ask('What is your name?');
        my $gender = $self->choice('Are you a male or a female?', ['male', 'female']);
        my $bool = $self->confirm("Do you have a cat?");

        $self->line("Hi $name\n");
        $self->line("We found out that you are a $gender ");

        if ($bool) {
            $self->line("and you have a cat");
        } else {
            $self->line("and you don't have a cat");
        }

        if ($self->confirm("Would you like an icecream?")) {
            $self->success("Thanks");
        } else {
            $self->error("Oh no!");
        }

        $self->info("You got here because you took an icecream");
    }

    1;

=head1 DESCRIPTION

L<Mojo::Console> is an extension of L<Mojolicious::Command>

=head1 ATTRIBUTES

L<Mojo::Console> inherits all attributes from L<Mojolicious::Command>.

=head1 METHODS

L<Mojo::Console> inherits all methods from L<Mojolicious::Command> and implements
the following new ones.

=head2 ask

    my $answer = $self->ask('What is your name?');
    my $required_answer = $self->required->ask('What is your name?'); # this will ask for an answer maximum 10 times and will exit in case the answer is empty

=head2 confirm

    my $bool = $self->confirm("Are you sure?");
    my $bool_with_default_answer = $self->confirm("Are you sure?", 'yes');

=head2 choice

    my $choice = $self->choice('Are you a male or a female?', ['male', 'female']);
    my $choice_with_default_answer = $self->choice('Are you a male or a female?', ['male', 'female'], 'male');

=head2 error

    $self->error("The program will stop here");

=head2 info

    $self->info("This is just an info message");

=head2 line

    $self->line("This message will not have a new line at the end");

=head2 newline

    $self->line("This message will have a new line at the end");

=head2 required

    $self->required->ask('What is your name?');

=head2 success

    $self->success("This is just a success message");

=head2 warn

    $self->success("This is just a warning message");

=head1 SEE ALSO

L<Mojolicious::Command>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
