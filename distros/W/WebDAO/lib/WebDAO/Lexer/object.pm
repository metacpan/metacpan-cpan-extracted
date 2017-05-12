package WebDAO::Lexer::object;

=head1 NAME

WebDAO::Lexer::object - Process object tag

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::Lexer::object - Process object tag

=cut

our $VERSION = '0.01';
use base 'WebDAO::Lexer::base';
use strict;
use warnings;
use Data::Dumper;

sub value {
    my $self = shift;
    my $eng  = shift;
    my @args = ();

    #skip not any
    foreach my $c ( $self->childs ) {
        unless ( UNIVERSAL::isa( $c, 'WebDAO::Lexer::base' ) ) {
            print "Bad element at " . ref($c);

            #     next;
        }

        #get values
        push @args, $c->value($eng);
    }

    #warn "Result: " . Dumper([@args]). Dumper($self->attr);
    if ($eng) {
        my $error;
        my $attr = $self->attr;

        #check if alias
        unless ( $eng->_pack4name( $attr->{class} ) ) {

            #try class as perl modulename
            $error = $eng->register_class( $attr->{class} );

        }
        if ($error) {

            #            _log1 $self
            warn "use module $attr->{class}  id: $attr->{id} fail. $error";
            return;
        }
        else {
            my $object = $eng->_create_( $attr->{id}, $attr->{class}, @args );

            #            _log1 $self
            warn "create_obj fail for class: "
              . $attr->{class}
              . " ,id: "
              . $attr->{id}
              unless $object;

            return $object;
        }
    }
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

