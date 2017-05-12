package WebDAO::Lexer::regclass;
=head1 NAME

WebDAO::Lexer::regclass - Process regclass tag

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Lexer::regclass - Process regclass tag

=cut

our $VERSION = '0.01';
use strict;
use warnings;
use base 'WebDAO::Lexer::base';

sub value {
    my $self = shift;
    my $eng  = shift;
    my $par  = $self->attr;
    my ( $class, $alias ) = @$par{qw/class alias/};
    unless ( $class && $alias ) {

        #_log1 $self
        warn "Syntax error: regclass - not initialized class or alias";
        return;
    }
    if ( my $error_str = $eng->register_class( $class => $alias ) ) {

        #_log1 $self
        warn $error_str;
    }

    #    warn "regcalss";
    #    return "1";
    return undef;
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

