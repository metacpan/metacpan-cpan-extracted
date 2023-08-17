package WebService::Rackspace::CloudFiles::ConnCache;
use Moo;
use Types::Standard qw(Int);

extends 'LWP::ConnCache';
 
has 'max_keep_alive_requests', is => 'rw', isa => Int;

around 'deposit' => sub {
    my ($coderef, $self, $type, $key, $conn) = @_;
    my $max_keep_alive_requests = $self->max_keep_alive_requests;
 
    my $keep_alive_requests = ${*$conn}{'myhttp_response_count'};
    if ($keep_alive_requests < $max_keep_alive_requests) {
        $self->$coderef($type, $key, $conn);
    }
};
 
1;
 
__END__

=head1 NAME
 
WebService::Rackspace::CloudFiles::ConnCache is a subclass of LWP::ConnCache,
and is very similar to LWP::ConnCache::MaxKeepAliveRequests except that it uses
Moo instead of Moose.

=head1 SYNOPSIS

Same as LWP::ConnCache::MaxKeepAliveRequests.

=head1 DESCRIPTION

Same as LWP::ConnCache::MaxKeepAliveRequests.

=head1 ADDITIONAL ATTRIBUTES

=head2 max_keep_alive_requests

Should be specied in the constructor. Read-only integer.

=head1 METHODS MODIFIED

=head2 deposit

Same functionality as LWP::ConnCache::MaxKeepAliveRequests.

=head1 AUTHOR
 
Dondi Michael Stroma <dstroma@gmail.com>.

Based on LWP::ConnCache::MaxKeepAliveRequests by Leon Brocard.
 
=head1 COPYRIGHT
 
Copyright (C) 2017, Dondi Michael Stroma.
 
=head1 LICENSE
 
This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
