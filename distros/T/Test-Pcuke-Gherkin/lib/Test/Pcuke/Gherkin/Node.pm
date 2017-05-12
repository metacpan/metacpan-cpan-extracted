package Test::Pcuke::Gherkin::Node;

use warnings;
use strict;

use Scalar::Util qw(refaddr);
use Carp;

=head1 NAME

Test::Pcuke::Gherkin::Node - Base class for Gherkin nodes

=head1 SYNOPSIS

	package MyClass;
    use base 'Test::Pcuke::Gherkin::Node';
    
    sub new {
		my ($class, %args) = @_;
	
		my @properties = qw{property1 property2};
		my @immutable_properties = qw{immutable1 immutable2};
	
		return $class->SUPER::new(
			immutable_properties	=> [ @immutable_properties ],
			properties				=> [ @properties ],
			args					=> {%args}
		);
    }
    
    sub set_property1 {
    	my ($self, $value) = @_;
    	$self->_set_property('property1', $value);
    }
    
    sub property1 { $_[0]->_get_property('property1'); }
    
    #... etc.

=head1 METHODS

=cut

{
	
	my %properties = ();
	my %immutables  = ();
	
=head2 new

=cut

	sub new {
		my ($class, %conf) = @_;
		
		my $self = bless \do { my $anonymous_scalar }, $class;

		return $self
			unless %conf;
		
		my $args = $conf{args};
		return $self
			unless $args;
				
		if ( ref $conf{properties} eq 'ARRAY' ) {
			foreach my $name ( @{ $conf{properties} } ) {
				$self->_set_property( $name, $args->{$name} )
					if defined $args->{$name};
			}
		}
		
		if ( ref $conf{immutables} eq 'ARRAY' ) {
			foreach my $name ( @{ $conf{immutables} } ) {
				$self->_set_immutable($name, $args->{$name})
					if defined $args->{$name};
			} 
		}
		
		return $self;
	}

	sub DESTROY {
		my $key = refaddr shift;
		delete $properties{$key};
		delete $immutables{$key};
	}	
	
	sub _set_property {
		my ($self, $name, $value) = @_;
		my $key = refaddr $self;
		$properties{$key}->{$name} = $value;
	}
	
	sub _set_immutable {
		my ($self, $name, $value) = @_;
		
		my $key = refaddr $self;
		
		if ( defined $immutables{$key}->{$name} ) {
			confess ref($self) . "::$name is an immutable property and can not be changed";
		}
		else {
			$immutables{$key}->{$name} = $value || q{};
		}		
	}
	
	sub _get_property {
		my ($self, $name) = @_;
		my $key = refaddr $self;
		$properties{$key}->{$name};
	}
	
	sub _get_immutable {
		my ($self, $name) = @_;
		my $key = refaddr  $self;
		$immutables{$key}->{$name};
	}
	
}

sub _add_property {
	my ($self, $name, $value) = @_;
	
	confess "scenario must be defined"
		unless $value;
	
	my $values = $self->_get_property($name);
	push @$values, $value;
	$self->_set_property($name, $values);
	
}

1; # End of Test::Pcuke::Gherkin::Node
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pcuke-Gherkin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pcuke-Gherkin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pcuke-Gherkin>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pcuke-Gherkin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


