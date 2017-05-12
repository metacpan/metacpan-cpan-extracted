package Test::Valgrind::Version;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Version - Object class for valgrind versions.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This class is used to parse, store and compare C<valgrind> versions.

=cut

use base 'Test::Valgrind::Carp';

use Scalar::Util ();

my $instanceof = sub {
 Scalar::Util::blessed($_[0]) && $_[0]->isa($_[1]);
};

=head1 METHODS

=head2 C<new>

    my $vg_version = Test::Valgrind::Version->new(
     command_output => qx{valgrind --version},
    );

    my $vg_version = Test::Valgrind::Version->new(
     string => '1.2.3',
    );

Creates a new L<Test::Valgrind::Version> object representing a C<valgrind> version from one of these two sources :

=over 4

=item *

if the C<command_output> option is specified, then C<new> will try to parse it as the output of C<valgrind --version>.

=item *

otherwise the C<string> option must be passed, and its value will be parsed as a 'dotted-integer' version number.

=back

An exception is raised if the version number cannot be inferred from the supplied data.

=cut

sub new {
 my ($class, %args) = @_;

 my $output = $args{command_output};
 my $string;
 if (defined $output) {
  ($string) = $output =~ /^valgrind-([0-9]+(?:\.[0-9]+)*)/;
 } else {
  $string = $args{string};
  return $string if $string->$instanceof(__PACKAGE__);
  if (defined $string and $string =~ /^([0-9]+(?:\.[0-9]+)*)/) {
   $string = $1;
  } else {
   $string = undef;
  }
 }
 $class->_croak('Invalid argument') unless defined $string;

 my @digits = map int, split /\./, $string;
 my $last   = $#digits;
 for my $i (reverse 0 .. $#digits) {
  last if $digits[$i];
  --$last;
 }

 bless {
  _digits => [ @digits[0 .. $last] ],
  _last   => $last,
 }, $class;
}

BEGIN {
 local $@;
 eval "sub $_ { \$_[0]->{$_} }" for qw<_digits _last>;
 die $@ if $@;
}

=head1 OVERLOADING

This class overloads numeric comparison operators (C<< <=> >>, C<< < >>, C<< <= >>, C< == >, C<< => >> and C<< > >>), as well as stringification.

=cut

sub _spaceship {
 my ($left, $right, $swap) = @_;

 unless ($right->$instanceof(__PACKAGE__)) {
  $right = __PACKAGE__->new(string => $right);
 }
 ($right, $left) = ($left, $right) if $swap;

 my $left_digits  = $left->_digits;
 my $right_digits = $right->_digits;

 my $last_cmp = $left->_last <=> $right->_last;
 my $last     = ($last_cmp < 0) ? $left->_last : $right->_last;

 for my $i (0 .. $last) {
  my $cmp = $left_digits->[$i] <=> $right_digits->[$i];
  return $cmp if $cmp;
 }

 return $last_cmp;
}

sub _stringify {
 my $self   = shift;
 my @digits = @{ $self->_digits };
 push @digits, 0 until @digits >= 3;
 join '.', @digits;
}

use overload (
 '<=>'    => \&_spaceship,
 '""'     => \&_stringify,
 fallback => 1,
);

=head1 SEE ALSO

L<Test::Valgrind>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Component

=head1 COPYRIGHT & LICENSE

Copyright 2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Version
