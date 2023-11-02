package Test::Smoke::Util::Execute;
use warnings;
use strict;

our $VERSION = '0.002';

use Cwd;

use Test::Smoke::LogMixin;

=head1 NAME

Test::Smoke::Util::Execute - Run a command and return its output.

=head1 SYNOPSIS

    use Test::Smoke::Util::Execute;

    my $ex = Test::Smoke::Execute->new(
        verbose   => $level,
        command   => $command,
        arguments => [@arguments],
    );
    my $output = eval { $ex->run() };
    if (my $error = $@) {
        croak("Error running $command: $error");
    }

=head1 DESCRIPTION

=head2 Test::Smoke::Util::Execute->new(%arguments)

Instantiate an object of this class

=head3 Arguments

=over

=item * verbose => [0, 1, 2]

=item * command => $command_to_pass_to_qx

=back

=head3 Returns

The instantiated object.

=cut

sub new {
    my $class = shift;

    my %args = @_;

    my $self = {
        verbose  => $args{verbose} || 0,
        command  => $args{command},
        exitcode => undef,
    };
    return bless $self, $class;
}

=head2 $executer->full_command()

Create the full command as pass to C<qx()>.

=head3 Arguments

None

=head3 Returns

A string with quotes around the elements/arguments that need them.

=cut

sub full_command {
    my $self = shift;

    my $command = join(
        " ",
        map {
            /^(["'])(.*)\1$/
                ? qq/"$2"/
                : /\s/
                    ? qq/"$_"/
                    : $_
        } $self->{command}, $self->arguments(@_)
    );
    return $command;
}

=head2 $executer->run()

Run the command with backticks.

=head3 Arguments

None

=head3 Returns

Context aware list or scalar.

If any error occured, C<< $self->exitcode >> is set.

=cut

sub run {
    my $self = shift;

    my $command = $self->full_command(@_);
    $self->log_debug("In pwd(%s) running:", cwd());
    $self->log_info("qx[%s]\n", $command);

    my @output = qx/$command/;
    $self->{exitcode} = $? >> 8;

    return wantarray ? @output : join("", @output);
}

=head2 $executer->exitcode

Getter that returns the exitcode.

=cut

sub exitcode { return $_[0]->{exitcode} }

=head2 $executer->verbose

Accessor that returns the verbose.

=cut

sub verbose {
    my $self = shift;
    if (@_) { $self->{verbose} = shift; }

    return $self->{verbose}
}

=head2 $executer->arguments

Accessor that returns the arguments.

=cut

sub arguments {
    my $self = shift;
    if (@_) { $self->{arguments} = [@_]; }

    return $self->{arguments} ? @{ $self->{arguments} } : ()
}

1;

=head1 STUFF

(c) MMXIII - Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * http://www.perl.com/perl/misc/Artistic.html

=item * http://www.gnu.org/copyleft/gpl.html

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
