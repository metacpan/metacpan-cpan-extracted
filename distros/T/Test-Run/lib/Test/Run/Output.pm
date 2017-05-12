package Test::Run::Output;

use strict;
use warnings;

use Moose;

extends('Test::Run::Base');

has 'NoTty' => (is => "rw", isa => "Bool");
has 'Verbose' => (is => "rw", isa => "Bool");
has 'last_test_print' => (is => "rw", isa => "Num");
has 'ml' => (is => "rw", isa => "Str");

=head1 NAME

Test::Run::Output - Base class for outputting messages to the user in a test
harmess.

=head1 METHODS

=cut

=head2 BUILD

For Moose.

=cut

sub BUILD
{
    my ($self, $args) = @_;

    $self->Verbose($args->{Verbose});
    $self->NoTty($args->{NoTty});

    return 0;
}

sub _print_message_raw
{
    my ($self, $msg) = @_;
    print $msg;
}


=head2 $self->print_message($msg)

Emits $msg followed by a newline.

=cut

sub print_message
{
    my ($self, $msg) = @_;

    $self->_print_message_raw($msg);
    $self->_newline();

    return;
}

sub _newline
{
    my $self = shift;
    $self->_print_message_raw("\n");
}

=head2 $self->print_ml($msg)

If ml() is defined, print it and $msg. If not - do nothing.

=cut

sub print_ml
{
    my ($self, $msg) = @_;

    if ($self->ml())
    {
        $self->_print_message_raw($self->ml . $msg);
    }

    return;
}

=head2 $self->print_leader({filename => $filename, width => $width})

Prints the file leader for $filename and $width.

=cut

sub print_leader
{
    my ($self, $args) = @_;

    $self->_print_message_raw(
        $self->_mk_leader(
            $args->{filename},
            $args->{width}
        )
    );
}

=head2 $self->print_ml_less($msg)

Calls print_ml() with $msg every second or less.

=cut

# Print updates only once per second.
sub print_ml_less
{
    my ($self, @args) = @_;

    my $now = CORE::time();

    if ($self->last_test_print() != $now)
    {
        $self->print_ml(@args);

        $self->last_test_print($now);
    }
}

sub _mk_leader__calc_te
{
    my ($self, $te) = @_;

    chomp($te);

    $te =~ s{\.\w+$}{};

    if ($^O eq "VMS")
    {
        $te =~ s{^.*\.t\.}{\[.t.}s;
    }

    return $te;
}

sub _is_terminal
{
    my $self = shift;

    return ((-t STDOUT) && (! $self->NoTty()) && (! $self->Verbose()));
}

sub _mk_leader__calc_leader
{
    my ($self, $args) = @_;

    my $te = $self->_mk_leader__calc_te($args->{te});
    return ("$te" . ' ' . ('.' x ($args->{width} - length($te) - 2 )) . ' ');
}

sub _mk_leader__calc_ml
{
    my ($self, $args) = @_;

    if (! $self->_is_terminal())
    {
        return "";
    }
    else
    {
        return "\r" . (' ' x 77) . "\r" . $args->{leader};
    }
}

=head2 B<_mk_leader>

  my($leader, $ml) = $self->_mk_leader($test_file, $width);

Generates the 't/foo........' leader for the given C<$test_file> as well
as a similar version which will overwrite the current line (by use of
\r and such).  C<$ml> may be empty if Test::Run doesn't think
you're on TTY.

The C<$width> is the width of the "yada/blah.." string.

=cut

sub _mk_leader
{
    my ($self, $_pre_te, $width) = @_;

    my $leader = $self->_mk_leader__calc_leader(
        +{ te => $_pre_te, width => $width, }
    );

    $self->ml(
        $self->_mk_leader__calc_ml(
            { leader => $leader, width => $width, },
        )
    );

    return $leader;
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 SEE ALSO

L<Test::Run::Obj>, L<Test::Run::Core>, L<Test::Run::Plugin::CmdLine::Output>.

=cut

1;
