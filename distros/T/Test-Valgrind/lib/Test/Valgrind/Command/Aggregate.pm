package Test::Valgrind::Command::Aggregate;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Command::Aggregate - A Test::Valgrind command that aggregates several other commands.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This command groups several commands together, which the session will run under the same action.

=cut

use Scalar::Util ();

use base qw<Test::Valgrind::Command Test::Valgrind::Carp>;

=head1 METHODS

This class inherits L<Test::Valgrind::Command>.

=head2 C<new>

    my $tvca = Test::Valgrind::Command::Aggregate->new(
     commands => \@commands,
     %extra_args,
    );

=cut

my $all_cmds = sub {
 for (@{$_[0]}) {
  return 0 unless Scalar::Util::blessed($_)
                                         and $_->isa('Test::Valgrind::Command');
 }
 return 1;
};

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;

 my $cmds = delete $args{commands};
 $class->_croak('Invalid commands list')
                   unless $cmds and ref $cmds eq 'ARRAY' and $all_cmds->($cmds);

 my $self = bless $class->SUPER::new(), $class;

 $self->{commands} = [ @$cmds ];

 $self;
}

=head2 C<commands>

    my @commands = $tvca->commands;

Read-only accessor for the C<commands> option.

=cut

sub commands { @{$_[0]->{commands} || []} }

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Command>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Command::Aggregate

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Command::Aggregate
