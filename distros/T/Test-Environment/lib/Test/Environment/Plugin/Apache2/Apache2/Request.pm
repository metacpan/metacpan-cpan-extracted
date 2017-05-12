package Test::Environment::Plugin::Apache2::Apache2::Request;

our $VERSION = "0.07";

1;

package Apache2::Request;

=head1 NAME

Test::Environment::Plugin::Apache2::Apache2::Request - mock Apache2::Request for Test::Environment

=head1 SYNOPSIS


=head1 DESCRIPTION

Will populate Apache2::Request namespace with fake methods that can be used for
testing.

=cut

use warnings;
use strict;

our $VERSION = "0.07";

use URI;

use base 'Class::Accessor::Fast';


=head1 PROPERTIES

    req_rec

=cut

__PACKAGE__->mk_accessors(qw{
    req_rec
    _params
});


=head1 METHODS

=head2 new()

Object constructor.

=cut

sub new {
    my $class = shift;
    my $req_rec   = shift;
    my $self = $class->SUPER::new({
        'req_rec' => $req_rec,
        @_,
    });
    
    $self->{'_params'} = { URI->new($req_rec->unparsed_uri)->query_form };
    
    return $self;
}

*param = *params;

sub params {
    my $self = shift;
    if (@_) {
        my $param_name = shift;
        return $self->_params->{$param_name};
    }
    return $self->_params;
}

1;

__END__

=head1 AUTHOR

Jozef Kutej

=cut
