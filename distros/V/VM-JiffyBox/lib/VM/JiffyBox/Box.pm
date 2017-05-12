package VM::JiffyBox::Box;
$VM::JiffyBox::Box::VERSION = '0.032';
# ABSTRACT: Representation of a Virtual Machine in JiffyBox

use strict;
use warnings;

use Moo;
use JSON;

has id         => (is => 'ro', required => 1);
has hypervisor => (is => 'ro', required => 1);
has name       => (is => 'rwp');

has last          => (is => 'rw');
has backup_cache  => (is => 'rw');
has details_cache => (is => 'rw');
has start_cache   => (is => 'rw');
has stop_cache    => (is => 'rw');
has delete_cache  => (is => 'rw');
has freeze_cache  => (is => 'rw');
has thaw_cache    => (is => 'rw');

sub get_backups {
    my $self = shift;
    
    my $url = $self->{hypervisor}->base_url . '/backups/' . $self->id;
    
    # POSSIBLE EXIT
    return { url => $url } if ($self->{hypervisor}->test_mode);
    
    my $response = $self->{hypervisor}->ua->get($url);

    # POSSIBLE EXIT
    unless ($response->is_success) {

        $self->last ( $response->status_line );
        return;
    }

    my $backup_info = from_json($response->decoded_content);

    $self->last         ($backup_info);
    $self->backup_cache ($backup_info);
    return               $backup_info ;

}

sub get_details {
    my $self = shift;
    
    # add method specific stuff to the URL
    my $url = $self->{hypervisor}->base_url . '/jiffyBoxes/' . $self->id;
    
    # POSSIBLE EXIT
    # return the URL if we are using test_mode
    return { url => $url } if ($self->{hypervisor}->test_mode);
    
    # send the request and return the response
    my $response = $self->{hypervisor}->ua->get($url);

    # POSSIBLE EXIT
    unless ($response->is_success) {

        $self->last ( $response->status_line );
        return;
    }

    my $details = from_json($response->decoded_content);

    $self->last          ($details);
    $self->details_cache ($details);
    return                $details ;
}

sub clone {
    my $self = shift;
    my $args = shift;
    
    # POSSIBLE EXIT (DIE)
    die 'name needed'                     unless $args->{name};
    die 'planid needed'                   unless $args->{planid};

    my $url  = $self->{hypervisor}->base_url . '/jiffyBoxes/' . $self->id;
    my $json = to_json( {
        name     => $args->{name},
        planid   => $args->{planid},
        metadata => $args->{metadata} || {},
    });

    # POSSIBLE EXIT
    return { url => $url, json => $json }
        if ($self->{hypervisor}->test_mode);
    
    # send the request with method specific json content
    my $response = $self->{hypervisor}->ua->post( $url, Content => $json ); 

    # POSSIBLE EXIT
    unless ($response->is_success) {

        $self->last ( $response->status_line );
        return;
    }

    my $clone_info = from_json($response->decoded_content);

    my $clone_box = __PACKAGE__->new(
        id         => $clone_info->{result}->{id},
        name       => $args->{name},
        hypervisor => $self,
    );

    return $clone_box;
}

sub _status_action {
    my $self   = shift;
    my $action = shift;
    my $params = shift;

    return if !$action;

    my $status = uc $action;
    $status    = 'SHUTDOWN' if 'stop' eq lc $action;

    my %opts;
    if ( $status eq 'THAW' ) {
        $opts{planid} = $params->{planid};
    }
    
    my $url  = $self->{hypervisor}->base_url . '/jiffyBoxes/' . $self->id;
    my $json = to_json( { %opts, status => $status } );
    
    # POSSIBLE EXIT
    return { url => $url, json => $json }
        if ($self->{hypervisor}->test_mode);
    
    # send the request with method specific json content
    my $response = $self->{hypervisor}->ua->put( $url, Content => $json ); 

    # POSSIBLE EXIT
    unless ($response->is_success) {

        $self->last ( $response->status_line );
        return;
    }

    my $status_info = from_json($response->decoded_content);

    my $cache_sub = $self->can( $action . '_cache' );
    $self->last ($status_info);
    $cache_sub->($status_info) if $cache_sub;
    return       $status_info ;
}

sub freeze {
    my $self = shift;

    return $self->_status_action( 'freeze' );
}

sub thaw {
    my $self = shift;

    return $self->_status_action( 'thaw', shift );
}

sub start {
    my $self = shift;

    return $self->_status_action( 'start' );
}

sub stop {
    my $self = shift;

    return $self->_status_action( 'stop' );
}

sub delete {
    my $self = shift;
    
    my $url = $self->{hypervisor}->base_url . '/jiffyBoxes/' . $self->id;
    
    # POSSIBLE EXIT
    return { url => $url } if ($self->{hypervisor}->test_mode);
    
    my $response = $self->{hypervisor}->ua->delete($url);    

    # POSSIBLE EXIT
    unless ($response->is_success) {

        $self->last ( $response->status_line );
        return;
    }

    my $delete_info = from_json($response->decoded_content);

    $self->last         ($delete_info);
    $self->delete_cache ($delete_info);
    return               $delete_info ;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

VM::JiffyBox::Box - Representation of a Virtual Machine in JiffyBox

=head1 VERSION

version 0.032

=head1 SYNOPSIS

This module should be used together with L<VM::JiffyBox>.
L<VM::JiffyBox> is the factory for producing objects of this module.
However if you want to do it yourself:

 my $box = VM::JiffyBox::Box->new(id => $box_id, hypervisor => $ref);

You then can do a lot of stuff with this box:

 # get some info
 my $backup_id = $box->get_backups()->{result}->{daily}->{id};
 my $plan_id   = $box->get_details()->{result}->{plan}->{id};

 # get more info using the caching technique
 my $state = $box->details_chache->{result}->{status};
 my $ip    = $box->last->{result}->{ips}->{public}->[0];
 # ... or
 use Data::Dumper;
 print Dumper( $box->backup_cache->{result} );

 # start, stop, delete...
 if ( $box->start ) {
     print "VM started"
 }

 # and so on...

(See also the SYNOPSIS of L<VM::JiffyBox> or the C<examples> directory for more examples of working code.)

=head1 ERROR HANDLING

All methods will return C<0> on failure, so you can check for this with a simple C<if> on the return value.
If you need the error message you can use the cache and look into the attribute C<last>.
The form of the message is open.
It can contain a simple string, or also a hash.
This depends on the kind of error.
So if you want to be sure, just use L<Data::Dumper> to print it.

=head1 CACHING

There are possibilities to take advantage of caching functionality.
The following caches are available:

=over

=item last

Always contains the last information.

=item backup_cache 

Contains information of the last call to get_backups().

=item details_cache

Contains information of the last call to get_details().

=item start_cache

Contains information of the last call to start().

=item stop_cache

Contains information of the last call to stop().

=item delete_cache

Contains information of the last call to delete().

=item freeze_cache

Contains information of the last call to freeze().

=item thaw_cache

Contains information of the last call to thaw().

=back

=head1 METHODS

All methods (exluding C<new>) will return information about the request, instead of doing a call to the API if the hypervisor is in C<test_mode>.

=head2 new

Creates a box-object.
Requires two parameters.

=over

=item id

C<ID> of the box.
Required.
See the official documentation of I<JiffyBox> for more information.

=item hypervisor

An object reference to C<VM::JiffyBox>.
Required.

=back

Optional parameters

=over 4

=item * name

Name of the box

=back

=head2 get_details

Returns hashref with information about the virtual machine.
Takes no arguments.

=head2 get_backups

Returns hashref with information about the backups of the virtual machine.
Takes no arguments.

=head2 clone

Clones a virtual machine. Needs a C<name> and a C<planid>. Returns a C<VM::JiffyBox::Box> object.

  my $clone = $box->clone(
      name   => 'Clonename',
      planid => 22,
  );

=head2 start

Starts a virtual machine.
It must be ensured (by you) that the machine has the state C<READY> before calling this.

=head2 stop

Stop a virtual machine.

  $box->stop();

=head2 freeze

freeze a virtual machine.

  $box->freeze();

=head2 thaw

Thaw a virtual machine.

  $box->thaw({
      planid => 22,
  });

=head2 delete

Delete a virtual machine.
(Be sure that the VM has the appropriate state for doing so)

=head1 SEE ALSO

=over

=item *

Source, contributions, patches: L<https://github.com/borisdaeppen/VM-JiffyBox>

=item *

This module is B<not> officially supported by or related to the company I<domainfactory> in Germany.
However it aims to provide an interface to the API of their product I<JiffyBox>.
So to use this module with success you should also B<read their API-Documentation>, available for registered users of their service.

=back

=head1 AUTHOR

Tim Schwarz, Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Tim Schwarz, Boris Däppen, plusW.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
