package WebService::PutIo::Transfers;

use base 'WebService::PutIo';

my $class='transfers';

sub list { shift->request($class,'list',@_); }
sub cancel { shift->request($class,'cancel',@_); }
sub add { shift->request($class,'add',@_); }

=head1 NAME

WebService::PutIo::Transfers - Transfer Operations for put.io

=head1 SYNOPSIS

    use WebService::PutIo::Transfers;
	my $transfers=WebService::PutIo::Transfers->new(api_key=>'..',api_secret=>'..');
	my $res=$transfers->list;
	foreach my $transfer (@{$res->results}) {
	   print "Got ". Data::Dumper($transfers);
	}

=head1 DESCRIPTION

Transfer related methods for the put.io web service

=head1 METHODS

=head2 list

Returns a list of active transfers.

=head2 cancel

Cancels a transfer.

=head3 Parameters:

=over 4

=item id

=back

=head2 add

Adds urls to fetch and returns a list of active transfers.

=head3 Parameters:

=over 4 

=item links

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

1;