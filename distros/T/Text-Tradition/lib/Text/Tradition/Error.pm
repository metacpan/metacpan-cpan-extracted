package Text::Tradition::Error;

use strict;
use warnings;
use Moose;
use overload '""' => \&_stringify, 'fallback' => 1;

with qw/ Throwable::X StackTrace::Auto /;
use Throwable::X -all;

around 'throw' => sub {
	my $orig = shift;
	my $self = shift;
	my %args = @_;
	my $msg = exists $args{message} ? $args{message} : undef;
	if( $msg && UNIVERSAL::can( $msg, 'message' ) ) {
		$args{message} = $msg->message;
	}
	$self->$orig( %args );
};

sub _stringify {
	my $self = shift;
	return "Error: " . $self->ident . " // " . $self->message
		. "\n" . $self->stack_trace->as_string;
}

no Moose;
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

=head1 NAME

Text::Tradition::Error - throwable error class for Tradition package

=head1 DESCRIPTION

A basic exception class to throw around, as it were.

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
