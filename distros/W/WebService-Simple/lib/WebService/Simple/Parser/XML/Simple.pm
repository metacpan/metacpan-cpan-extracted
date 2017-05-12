# $Id$

package WebService::Simple::Parser::XML::Simple;
use strict;
use warnings;
use base qw(WebService::Simple::Parser);
use XML::Simple;

sub new {
    my $class = shift;
    my %args  = @_;
    my $xs    = delete $args{xs} || XML::Simple->new;
    my $self  = $class->SUPER::new(%args);
    $self->{xs} = $xs;
    return $self;
}

sub parse_response {
    my $self = shift;
    $self->{xs}->XMLin( $_[0]->decoded_content );
}

1;

__END__

=head1 NAME 

WebService::Simple::Parser::XML::Simple - XML::Simple Adaptor For WebService::Simple::Parser

=head1 METHODS

=head2 new

=head2 parse_response

=cut
