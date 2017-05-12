package                                # Hide from PAUSE
  WiX3::Util::Error;

use 5.008003;
use strict;
use warnings;
use Readonly qw (Readonly);
use WiX3::Exceptions;
use parent 'Moose::Error::Default';

our $VERSION = '0.011';

Readonly my %TYPES => ( 'Maybe[Int]' => 'an integer' );

sub new {
	my ( $self, @args ) = @_;
	return $self->create_error_croak(@args);
}

sub create_error_croak {
	my ( $self, @args ) = @_;
	return $self->_create_error_carpmess(@args);
}

sub create_error_confess {
	my ( $self, @args ) = @_;
	return $self->_create_error_carpmess( @args, longmess => 1 );
}

sub _create_error_carpmess {
	my ( $self, %args ) = @_;

	## no critic(ProhibitMagicNumbers)
	my $carp_level = 3 + ( $args{depth} || 1 );

	my @args = exists $args{message} ? $args{message} : ();
	my $info = join q{}, @args;

	my $longmess = exists $args{longmess} ? !!$args{longmess} : 0;

	## no critic(ProhibitComplexRegexes)
	if ($info =~ m{\A
	               Attribute [ ] [(] (.*) [)]  # $1 = attribute name
				   [ ] does [ ] not [ ] pass [ ] the 
				   [ ] type [ ] constraint [ ] because: 
				   [ ] Validation [ ] failed [ ] for [ ] '(.*)' # $2 = type
				   (?:[ ] failed)? [ ] with [ ] value [ ] (.*) # $3 = bad value
				   \z}msx
	  )
	{
		my ( $attr_name, $attr_type, $value ) = ( $1, $2, $3 );
		my $type =
		  exists $TYPES{$attr_type} ? $TYPES{$attr_type} : $attr_type;

		WiX3::Exception::Parameter::Validation->throw(
			attribute    => $attr_name,
			type         => $type,
			value        => $value,
			ignore_class => [qw(WiX3::Util::Error Moose::Meta::Class)],
		);
	} else {
		WiX3::Exception::Caught->throw(
			message      => 'Moose',
			info         => $info,
			longmess     => $longmess,
			ignore_class => [qw(WiX3::Util::Error Moose::Meta::Class)],
		);
	}
	return;
} ## end sub _create_error_carpmess

1;

__END__

=pod

=head1 NAME

WiX3::Util::Error - L<Exception::Class|Exception::Class> based error generation for Moose.

=head1 DESCRIPTION

This class implements L<Exception::Class|Exception::Class> based error generation.

=head1 METHODS

=over 4

=item new @args

Create a new error. Delegates to C<create_error_croak>.

=item create_error_confess @args

=item create_error_croak @args

Creates a new error of the specified style.

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2009, 2010 Curtis Jewell C<< <csjewell@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.1 itself. See L<perlartistic|perlartistic>.



