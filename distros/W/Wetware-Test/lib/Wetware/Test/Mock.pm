#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test::Mock;

use warnings;
use strict;

our $VERSION = 0.01; 
our $AUTOLOAD;  # it's a package global

#-------------------------------------------------------------------------------
# the Plain Vanilla form
sub new {
	my ($class, %params) = @_;	    # Normalize the keys of the attributes hash to ALL_CAPS.
    my %uppercase_params = map { ( uc $_ => $params{$_} ) } keys %params;
    my $self = bless \%uppercase_params, $class;
    return $self;
}

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion	
	return $self->{ uc $name };
}  
#-------------------------------------------------------------------------------

1; 

__END__

=pod

=head1 NAME

Wetware::Test::Mock - a simple mock object

=head1 SYNOPSIS

  use  Wetware::Test::Mock;
  my $mock = Wetware::Test::Mock->new(%params);


=head1 DESCRIPTION

The Parameters you pass in will be the only things
that can be accessed with the AUTOLOAD method.



=head1 AUTHOR

"drieux", C<< <"drieux [AT]  at wetware.com"> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 "drieux", all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Wetware::Test
