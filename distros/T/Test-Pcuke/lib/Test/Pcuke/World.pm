package Test::Pcuke::World;

use warnings;
use strict;

use Carp;

our $AUTOLOAD; 

=head1 NAME

Test::Pcuke::World - World object for pcuke steps

=head1 SYNOPSIS

Quick summary of what the module does.

    use Test::Pcuke::World;
    ...

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class) = @_;
	my $self = {
		public	=> {},
		private => {},
	};
	
	bless $self, $class;
	
	$self->{private}->{ok} = 1;
	
	return $self;
}


=head2 set $name, $value

Sets an instance variable named $name to $value

=cut

sub set { 
	my ($self, $name, $value) = @_;
	croak "$name is reserved in the world"
		if grep { $name eq $_ } qw{set new get ok assert};
	$self->{public}->{$name} = $value;
}

=head2 get $name

Returns a value of the instance variable named $name

=cut

sub get { $_[0]->{public}->{$_[1]} }

sub AUTOLOAD {
	return if $AUTOLOAD =~ /::DESTROY$/;
	
	my $self = shift;
	
	if ( $AUTOLOAD =~ /::([^:]+)$/ ) {
		if ( defined $self->{public}->{$1} ) {
			return $self->get($1);
		}
		else {
			croak "$1: method is not defined in the world";
		}
	}
}

=head2 ok

Returns true if everything is ok

=cut

1; # End of Test::Pcuke::World
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::World


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pcuke>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pcuke>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pcuke>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pcuke/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


