package Test::Pcuke::Expectation;
use warnings;
use strict;

use Carp;

=head1 NAME

Test::Pcuke::Expectation - expectation on an object

Takes an object, checks if some expectation about is correct

    use Test::Pcuke::Expectation;

    my $foo = Test::Pcuke::Expectation->new($object);
    $foo->equals(5);
    ...

=cut

my %descriptions = (
	equals	=> '%OBJECT% is %NOT%equal to %VALUE%',
);

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class, $object, $options) = @_;
	
	my %instance_data = (
		_object => $object,
		_throw	=> $options->{throw}
	);
	
	return bless \%instance_data, $class;
}

=head2 is_defined

Checks if the object is defined

=cut

sub is_defined {
	my ($self) = @_;
	return $self->_result( defined $self->_object ); 
}

=head2 is_a $class

Checks if the object isa $class

=cut

sub is_a { 
	my ($self, $class) = @_;
	my $result = eval { $self->_object->isa($class) };
	return $self->_result($result, $class);
}

=head2 equals $subject

Checks if the object eq $subject

=cut

sub equals {
	my ($self, $value) = @_; 
	$self->_result($self->_object eq $value, $value);
};


sub _message {
	my ($self, $result, $value) = @_;
	my ($message, $var);
	
	my ($package, $filename, $line,
		$subroutine, $hasargs, $wantarray,
		$evaltext, $is_require, $hints,
		$bitmask, $hinthash) = caller 2;
	
	$subroutine =~ s/^.*?::(\w+)$/$1/;
	
	$message = ($descriptions{$subroutine} || "TODO: description for $subroutine"); 
	
	$var = ref $self->_object || $self->_object || 'undef';
	$message =~ s/%OBJECT%/$var/g;
	
	$var = $result ? q{} : 'not ';
	$message =~ s/%NOT%/$var/g;
	 
	$var = ref $value || $value || q{};
	$message =~ s/%VALUE%/$var/g;
	
	return $message;
}

sub _result {
	my ($self, $result, $value) = @_;
	my $message = $self->_message($result, $value);
		
	if ( my $exception = $self->_exception ) {
		die $exception->new($message)
			unless $result;
	}
	
	return $result;
}

sub _object { return $_[0]->{_object} }

sub _exception {
	my ($self) = @_;
	return $self->{_throw};
}

#--------------------------------------
1; # End of Test::Pcuke::Expectation
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Expectation


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is released under the following license: artistic


=cut
