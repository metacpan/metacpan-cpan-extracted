package WebDAO::Lexer::base;
use strict;
use warnings;
use Data::Dumper;

=head1 NAME

WebDAO::Lexer::base - Base class 

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Lexer::base - Base class 

=cut

our $VERSION = '0.01';

sub new {
    my $class = shift;
    bless( $#_ == 0 ? {shift} : {@_}, ref($class) || $class );
}

sub childs {
    my $self = shift;
    return ()
      unless ( exists $self->{childs} );
    @{ $self->{childs} };
}

sub name {
    my $self = shift;
    $self->{name};
}

sub attr {
    my $self       = shift;
    $self->{attr}
}

sub value {
    my $self = shift;
    my @res  = ();

    #allow anly objects
    foreach my $c ( $self->childs ) {
        unless ( UNIVERSAL::isa( $c, 'WebDAO::Lexer::object' ) ) {
            print "Bad element at " . Dumper($c);
            next;
        }
        push @res, $c->value(@_);
    }
    return ( $self->name => scalar(@res) > 1 ? \@res : $res[0] );
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


