package URL::Transform::using::Remove;

=head1 NAME

URL::Transform::using::Remove - no url transformation just remove the content

=head1 SYNOPSIS

    my $urlt = URL::Transform::using::Remove->new(
        'output_function'    => sub { $output .= "@_" },
    );
    $urlt->parse_string("window.location='http://perl.org';");

    print "and this is the output: ", $output;


=head1 DESCRIPTION

Using module you can performs an url transformation by removing everything!
It's quite safe! ;-)

This module is used by L<URL::Transform> to remove all JavaScript from
the HTML documents as it is nearly impossible to update urls inside the
JavaScript using generic way.

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use Carp::Clan 'croak';

use base 'Class::Accessor::Fast';


=head1 PROPERTIES

    output_function
    transform_function

=cut

__PACKAGE__->mk_accessors(qw{
    output_function
    transform_function
});

=head1 METHODS

=head2 new

Object constructor.

Requires:

    output_function

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new({ @_ });

    my $output_function    = $self->output_function;
#    my $transform_function = $self->transform_function;
    
    croak 'pass print function'
        if not (ref $output_function eq 'CODE');
    
#    croak 'pass transform url function'
#        if not (ref $transform_function eq 'CODE');
    
    return $self;
}


=head2 parse_string($string)

Pass empty string to output_function.

=cut

sub parse_string {
    my $self   = shift;
    my $string = shift;
    
    $self->output_function->('');
}


=head2 parse_chunk($string)

Pass empty string to output_function.

=cut

sub parse_chunk {
    my $self = shift;
    
    $self->output_function->('');
}


=head2 parse_file($file_name)

Pass empty string to output_function.

=cut

sub parse_file {
    my $self = shift;
    
    $self->output_function->('');
}


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
