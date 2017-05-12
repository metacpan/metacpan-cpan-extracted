package WWW::Pipeline::Services::Output;
$VERSION = '0.1';

#-- pragmas ---------------------------- 
 use strict;
 use warnings;

=head1 WWW::Pipeline::Services::Output;

This plugin for WWW::Pipeline provide services and mechanisms for delivering
the response from the application to the client.

=cut

#== Plugin =====================================================================

sub load {
    my( $class, $pipeline ) = @_;

    my $self ||= bless { _sent => 0 }, $class;

    $pipeline->addServices(
        headers => sub { $self->headers(@_) },
        flush => sub { $self->flush(@_) }
    );

    $pipeline->addHandler( 'SendResponse', \&send );

    return $self;
}

#== Services ===================================================================

=head2 Services

=head3 headers

 #set:
 $pipeline->headers( -status=>'403 Not Authorized'
                     -cookie  => $cookie,
                     -expires => '+3h'
 );
 
 #retrieve:
 my $loc = $pipeline->headers( '-status' );

 #remove:
 $pipeline->('-expires' => undef );

The headers service is used to build a hash of http headers in the style of
the CGI.pm module.  Setting and Deleting header entries can be mixed, however
retrieval must be done one at a time.

The headers are stored until the SendResponse phase, when the plugin's installed
handler sends them as part of the response.  They may be sent earlier by way of
the plugin's c<flush()> service.

=cut

sub headers {

    my( $self, $pipeline, @params ) = @_;

    if( @params == 1 ) {
        return defined $self->{_headers}{$params[0]}
             ? $self->{_headers}{$params[0]}
             : undef;
    }

    die "headers expects a hash of headers if you pass it more than one parameter"
      if @params % 2 != 0;

    my %headers = @params;
    while( my( $header,$value ) = each %headers ) {
        if( defined $value ) {
            $self->{_headers}{$header} = $value;
        }
        else {
            delete $self->{_headers}{$header};
        }
    }
}

#-------------------------------------------------------------------------------

=head3 flush

 $pipeline->flush();

Sends any stored headers and any content stored in the application's C<response>
service ( which is part of the standard WWW::Pipeline::Services package).
C<flush> may be used more than once, but will only send the headers the first
time.

=cut

sub flush {
    my( $self, $pipeline ) = @_;
    
    unless( $self->{_sent} == 1 ) {
        print $pipeline->query->header( %{$self->{_headers}} );
        $self->{_sent} = 1;
    }

    print $pipeline->response();
    $pipeline->response('');
}

#===============================================================================

=head2 Handlers

=head3 send

The plugin installs the C<send> handler during the host application's
SendResponse phase.  The whole of its purpose is to invoke the C<flush()>
service as described above.

=cut

sub send {
    my $pipeline = shift;
    $pipeline->flush();
}

#========
1;

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut
