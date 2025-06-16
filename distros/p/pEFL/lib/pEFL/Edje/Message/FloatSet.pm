package pEFL::Edje::Message::FloatSet;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EdjeMessageFloatSetPtr);

require XSLoader;
XSLoader::load('pEFL::Edje::Message::FloatSet');

sub new {
	my ($class, @vals) = @_;
	my $count = $#vals;
	my $message = _new($class,$count,\@vals);
	return $message;
}

package EdjeMessageFloatSetPtr;



# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Edje::Message::FloatSet

=head1 DESCRIPTION

This module is a perl binding to the Edje_Message_Float_Set struct.

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
