package macro::filter;

use strict;
use warnings;

BEGIN{
	require macro;
	our @ISA = qw(macro);
	*VERSION = \$macro::VERSION;
}

use Filter::Util::Call ();

sub import{
	my $class = shift;

	return unless @_;

	my $self  = $class->new();

	$self->defmacro(@_);

	
	Filter::Util::Call::filter_add($self);
	return;
}

sub filter :method{
	my($self) = @_;

	Filter::Util::Call::filter_del();

	1 while Filter::Util::Call::filter_read();

	$_ = $self->process( $_, [caller]);

	return 1;
}


1;
__END__

=head1 NAME

macro::filter - macro.pm source filter backend

=head1 SYNOPSIS

	use macro::filter add => sub{ $_[0] + $_[1] };

=head1 SEE ALSO

L<macro>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

