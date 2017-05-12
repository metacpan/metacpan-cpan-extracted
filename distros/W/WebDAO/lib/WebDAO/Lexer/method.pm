package WebDAO::Lexer::method;
=head1 NAME

WebDAO::Lexer::method - Process method tag

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Lexer::method - Process method tag

=cut

our $VERSION = '0.01';

use base 'WebDAO::Lexer::base';
use strict;
use warnings;
sub value {
    my $self = shift;
    my $eng = shift || return undef;
    my $attr= $self->attr;
    my $object =
      $eng->_create_( "none", "_method_call", $attr->{path} );
    return $object;
}
1;

__DATA__

=head1 SEE ALSO

http://sourceforge.net/projects/webdao

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

