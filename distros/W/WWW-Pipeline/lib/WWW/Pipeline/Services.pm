package WWW::Pipeline::Services;
$VERSION = '0.1';

#-- pragmas ----------------------------
 use strict;
 use warnings;

=head1 WWW::Pipeline::Services

This package provides basic services for WWW::Pipeline applications,
namely a C<param()> method and a C<response()> method.

=cut

#===============================================================================
sub load {
    my( $class, $pipeline, $params ) = @_;

    my $self = bless {
        _params   => $params,
        _response => ''
    }, $class;
    
    $pipeline->addServices (
        param => sub { $self->param(@_) },
        response => sub { $self->response(@_) }
    );

    return $self;
}

#===============================================================================

=head2 Services

=head3 param

 #set
 $pipeline->param('name',$value);
 $pipeline->param( name2 => $value2 )

 #retrieve
 $pipeline->param('name');
 
 #delete
 $pipeline->param('name',undef);


the C<param> service provides a storage location for data to be shared between
phases for the duration of the pipline.

=cut

sub param {
    my( $self, $pipeline, $key, $value ) = @_;

    if( @_ == 4 ) {
        return $self->{_params}{$key} = $value
          if defined $value;

        return delete $self->{_params}{$key};
    }

    return defined $self->{_params}{$key}
         ? $self->{_params}{$key}
         : undef;
}

#-------------------------------------------------------------------------------

=head3 response

 #get
 $pipeline->response();

 #set
 $pipeline->response($value);

the C<response> service provides a storage location for text to be sent back
to the requester until the application deems appropriate to send it.

=cut

sub response {
    my( $self, $pipeline, $value ) = @_;

    $self->{_response} = $value if @_ == 3;

    return $self->{_response};
}

#========
1;

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut
