package Text::Password::Pronounceable::RandomCase;

use strict;
use warnings;
use parent 'Text::Password::Pronounceable';
use Readonly;

our $VERSION = '0.03';

sub generate {
    my ( $self, $min, $max, $prob ) = @_;
    Readonly::Scalar my $DEFAULT_PROBALITITY => 4;
    Readonly::Scalar my $DEFAULT_LENGTH      => 8;

    if (ref $self) {
	$min  ||= $self->{min}; 
	$max  ||= $self->{max};
	$prob ||= $self->{prob};
    }

    $min  ||= $DEFAULT_LENGTH;
    $max  ||= $min;
    $prob ||= $DEFAULT_PROBALITITY;

    my $password = $self->SUPER::generate( $min, $max );

    return join '', map { int rand $prob ? $_ : uc } split //xms, $password;
}

sub new {
    my ( $class, $min, $max, $prob ) = @_;

    return bless { min => $min, max => $max, prob => $prob }, $class;
}

1;

__END__

=head1 NAME

Text::Password::Pronounceable::RandomCase - Generate pronounceable
passwords with random case

=head1 SYNOPSIS

  ## defaults to upper case in a quarter of all cases
  Text::Password::Pronounceable::RandomCase->generate(6, 10);

  ## Explicit
  Text::Password::Pronounceable::RandomCase->generate(6, 10, 4);

  ## Ditto
  my $pp = Text::Password::Pronounceable::RandomCase->new(6, 10, 4);
  $pp->generate;

=head1 DESCRIPTION

L<Text::Password::Pronounceable> produces pronouncable passwords. But
it has the one disadvantage that it only uses lower case characters. This
module tries to solve this shortcoming. The two methods I<new()> and
I<generate()> take a third parameter, which determines the frequency of
upper case characters. Any 1/N'th character will be uppercased on average.

If you do not pass any arguments, I<generate()> will produce passwords
with a length of eight characters and a 1/4 probability for any
character to be uppercased.

=head1 DEPENDENCIES

L<Text::Password::Pronounceable>

=head1 VERSION

0.03

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-password-pronounceable-randomcase
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Password-Pronounceable-RandomCase>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Password::Pronounceable::RandomCase


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Password-Pronounceable-RandomCase>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Password-Pronounceable-RandomCase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Password-Pronounceable-RandomCase>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Password-Pronounceable-RandomCase>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2008-2009 Mario Domgoergen.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
