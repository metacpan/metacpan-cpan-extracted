###########################################################################
### Trinket::Directory::FilterParser
###
### Foo
###
### $Id: FilterParser.pm,v 1.1.1.1 2001/02/15 18:47:50 deus_x Exp $
###
### TODO:
###
###########################################################################

package Trinket::Directory::FilterParser;

use strict;
use vars qw($VERSION @ISA @EXPORT $DESCRIPTION $AUTOLOAD);
no warnings qw( uninitialized );

# {{{ Begin POD

=head1 NAME

Trinket::Directory::FilterParser - Base class for Trinket filter parsers

=head1 DESCRIPTION

TODO Need global description of FilterParsers, maybe how to write one.

=cut

# }}}

# {{{ METADATA

BEGIN
  {
    $VERSION      = "0.0";
    @ISA          = qw( Exporter );
    $DESCRIPTION  = 'Base FilterParser class';
  }

# }}}

use Carp qw( cluck croak );

# {{{ EXPORTS

=head1 EXPORTS

TODO

=cut

# }}}

use constant SEARCH_OP      => 0;
use constant SEARCH_OPERAND => 1;

@EXPORT = qw( &SEARCH_OP &SEARCH_OPERAND );

# {{{ METHODS

=head1 METHODS

=over 4

=cut

# }}}

# {{{ new(): Object constructor

=item $parser = new Trinket::Directory::FilterParser();

Object constructor, accepts a hashref of named properties with which to
initialize the object.  In initialization, the object's set methods
are called for each of initializing properties passed.  '

=cut

sub new
  {
    my $class = shift;

    my $self = {};

    bless($self, $class);
    $self->init(@_);
    return $self;
  }

# }}}

# {{{ parse_filter: Parse a search filter into an LoL

=item $parsed = $parser->parse_filter($filter);

TODO

=cut

sub parse_filter
	{
		my ($self, $filter) = @_;

    croak("Call to unimplmeparse_filter() unimplemented in ".ref($self));
	}

# }}}

# {{{ DESTROY

sub DESTROY
  {
    ## no-op to pacify warnings
  }

# }}}

# {{{ End POD

=back

=head1 AUTHOR

Maintained by Leslie Michael Orchard <F<deus_x@pobox.com>>

=head1 COPYRIGHT

Copyright (c) 2000, Leslie Michael Orchard.  All Rights Reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# }}}

1;
__END__

