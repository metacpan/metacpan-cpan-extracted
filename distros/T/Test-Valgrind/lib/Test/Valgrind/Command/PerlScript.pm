package Test::Valgrind::Command::PerlScript;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Command::PerlScript - A Test::Valgrind command that invokes a perl script.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This command is meant to abstract the argument list handling of a C<perl> script.

=cut

use base qw<Test::Valgrind::Command::Perl Test::Valgrind::Carp>;

=head1 METHODS

This class inherits L<Test::Valgrind::Command::Perl>.

=head2 C<new>

    my $tvcps = Test::Valgrind::Command::PerlScript->new(
     file       => $file,
     taint_mode => $taint_mode,
     %extra_args,
    );

The package constructor, which takes several options :

=over 4

=item *

C<$file> is the path to the C<perl> script you want to run.

This option is mandatory.

=item *

C<$taint_mode> is actually handled by the parent class L<Test::Valgrind::Command::Perl>, but it gets special handling in this subclass : if C<undef> is passed (which is the default), the constructor will try to infer its right value from the shebang line of the script.

=back

Other arguments are passed straight to C<< Test::Valgrind::Command::Perl->new >>.

=cut

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;

 my $file = delete $args{file};
 $class->_croak('Invalid script file') unless $file and -e $file;

 my $taint_mode = delete $args{taint_mode};
 if (not defined $taint_mode and open my $fh, '<', $file) {
  my $first = <$fh>;
  close $fh;
  if ($first and my ($args) = $first =~ /^\s*#\s*!\s*perl\s*(.*)/) {
   $taint_mode = 1 if $args =~ /(?:^|\s)-T(?:$|\s)/;
  }
  $taint_mode = 0 unless defined $taint_mode;
 }

 my $self = bless $class->SUPER::new(
  taint_mode => $taint_mode,
  %args,
 ), $class;

 $self->{file} = $file;

 return $self;
}

sub new_trainer { Test::Valgrind::Command::Perl->new_trainer }

=head2 C<file>

    my $file = $tvcps->file;

Read-only accessor for the C<file> option.

=cut

sub file { $_[0]->{file} }

sub args {
 my $self = shift;

 return $self->SUPER::args(@_),
        $self->file
}

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Command::Perl>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Command::PerlScript

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Command::PerlScript
