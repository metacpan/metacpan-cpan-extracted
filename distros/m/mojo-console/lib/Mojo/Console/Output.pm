package Mojo::Console::Output;
use Mojo::Base -base;

use Term::ANSIColor;

has 'sameline' => 1;

sub error {
    shift->wrap(@_, 'bright_red', 1);
}

sub info {
    shift->wrap(@_, 'bright_cyan');
}

sub line {
    shift->wrap(@_);
}

sub newline {
    my $self = shift;

    my $sameline = $self->sameline;
    $self->sameline(0);

    $self->wrap(@_);

    $self->sameline($sameline);
}

sub success {
    shift->wrap(@_, 'bright_green');
}

sub warn {
    shift->wrap(@_, 'bright_yellow');
}

sub wrap {
    my ($self, $message, $color, $error) = @_;

    $error ||= 0;

    if ($error) {
        print STDERR color($color) if ($color);
        print STDERR $message;
        print STDERR color('reset') if ($color);

        exit;
    } else {
        print STDOUT color($color) if ($color);
        print STDOUT sprintf("%s%s", $message, ($self->sameline ? '' : "\n"));
        print STDOUT color('reset') if ($color);
    }
}

1;

=encoding utf8

=head1 NAME

Mojo::Console::Output - write things to STDOUT / STDERR

=head1 METHODS

L<Mojo::Console::Output> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 error

    $self->error("The program will stop here");

=head2 info

    $self->info("This is just an info message");

=head2 line

    $self->line("This message will not have a new line at the end");

=head2 newline

    $self->line("This message will have a new line at the end");

=head2 success

    $self->success("This is just a success message");

=head2 warn

    $self->success("This is just a warning message");

=head2 wrap

    $self->wrap("Message", "color", 1/0);

=cut
