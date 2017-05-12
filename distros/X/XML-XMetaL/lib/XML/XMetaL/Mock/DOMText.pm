package XML::XMetaL::Mock::DOMText::Tie;

use Tie::Hash;
use base 'Tie::StdHash';

sub TIEHASH {
    my ($class, $object) = @_;
    my $self = bless $object, $class;
    return $self;
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->{$key} = $value;
    $self->{length} = length $value if $key eq 'data';
}

package XML::XMetaL::Mock::DOMText;

use 5.008;
use strict;
use warnings;

use Carp;
use Hash::Util qw(lock_keys);
use Tie::Hash;

use base ('Tie::StdHash', 'XML::XMetaL::Mock::DOMNode');

use constant TRUE  => 1;
use constant FALSE => 0;

our @keys = qw(
    data
    length
);


sub new {
    my ($class, %args) = @_;
    #my $self;
    my %self;
    my $self;
    eval {
        my %properties;
        @properties{@keys} = @args{@keys};
        my $super_class = $class->SUPER::new(%args);
        %properties = (
            %$super_class,
            %properties,
        );
        tie %self, 'XML::XMetaL::Mock::DOMText::Tie', \%properties;
        $self = bless \%self, ref($class) || $class;
        lock_keys(%$self, keys %$self);
        
    };
    croak $@ if $@;
    return $self;
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::XMetaL::Mock::DOMText - Mock XMetaL DOMText class

=head1 SYNOPSIS

 use base qw(XML::XMetaL::Base);

=head1 DESCRIPTION


=head2 Class Methods

None.

=head2 Public Methods


=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

A lot, I am sure.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.


=head1 SEE ALSO

See L<XML::XMetaL>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
