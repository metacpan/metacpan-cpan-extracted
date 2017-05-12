package WebDAO::SessionSH;

=head1 NAME

WebDAO::SessionSH - Session class used from shell 

=head1 DESCRIPTION

WebDAO::SessionSH - Session class used from shell 

=cut

our $VERSION = '0.01';
use strict;
use warnings;
use WebDAO;
use WebDAO::Session;
use Data::Dumper;
use base qw( WebDAO::Session );

#Need to be forever called from over classes;
sub _init {
    my $self = shift;
    my %args = @_;
    $self->SUPER::_init(@_);
    delete $args{cv};
    $self->U_id( rand(100) );
    #setup default method 
    $ENV{REQUEST_METHOD} ||="GET";
    Params $self ( $self->_get_params() );
}

sub print_header() {
    return ''
}

1;
__DATA__

=head1 SEE ALSO

http://webdao.sourceforge.net

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

