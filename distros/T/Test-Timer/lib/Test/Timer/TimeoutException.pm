package Test::Timer::TimeoutException;

use strict;
use warnings;
use vars qw($VERSION);

use base 'Error';
use overload ( '""' => 'stringify' );

$VERSION = '2.01';

sub new {
    my $self = shift;
    my $text = '' . shift;
    my @args = ();

    local $Error::Depth = $Error::Depth + 1;

    $self = $self->SUPER::new( -text => $text, @args );

    return $self;
}

1;

__END__

=pod

=head1 NAME

Test::Timer::TimeoutException - exception class for Test::Timer

=head1 VERSION

This documentation describes 2.01 of Test::Timer::TimeoutException

=head1 SYNOPSIS

    use Test::Timer::TimeoutException;

    throw Test::Timer::TimeoutException(" ... ");

=head1 DESCRIPTION

This is an exception class for Test::Timer. It is used in conjunction with the
alarm signal and is thrown if the alarm is set of.

=head1 SUBROUTINES/METHODS

=head2 new

This is the constructor, this is called using throw, please refer to
the documentation for L<Error>, see also the SYNOPSIS.

=head1 DIAGNOSTICS

This is an exception class, it holds not special diagnostics apart from what is
described above in the general description.

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no special configuration or environment.

=head1 DEPENDENCIES

=over

=item * L<Error>

=back

=head1 INCOMPATIBILITIES

This class holds no known incompatibilities.

=head1 BUGS AND LIMITATIONS

This class holds no known bugs or limitations.

=head1 TEST AND QUALITY

This class is tested as part of L<Test::Timer>

=head1 SEE ALSO

=over

=item * L<Test::Timer>

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen (jonasbn) C<< <jonasbn at cpan.org> >>

=back

=head1 LICENSE AND COPYRIGHT

Test::Timer and related modules are (C) by Jonas B. Nielsen,
(jonasbn) 2007-2017

Test::Timer and related modules are released under the Artistic
License 2.0

Used distributions are under copyright of there respective authors and designated licenses

Image used on L<website|https://jonasbn.github.io/perl-test-timer/> is under copyright by L<Veri Ivanova|https://unsplash.com/@veri_ivanova?photo=p3Pj7jOYvnM>

=cut
