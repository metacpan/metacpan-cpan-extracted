package WebService::PutIo::Messages;

use base 'WebService::PutIo';

my $class='messages';

sub list { shift->request($class,'list',@_); }
sub delete { shift->request($class,'delete',@_); }

=head1 NAME

WebService::PutIo::Messages - Dashboard Messages  for put.io

=head1 SYNOPSIS

    use WebService::PutIo::Messages;
	my $messages=WebService::PutIo::Messages->new(api_key=>'..',api_secret=>'..');
	my $res=$messages->list;
	foreach my $message (@{$res->results}) {
	   print "Got ". Data::Dumper($message);
	}

=head1 DESCRIPTION

Dashboard message related methods for the put.io web service

=head1 METHODS

=head2 list

Returns a list of messages

=head2 delete

Deletes a message

=head3 Parameters:

=over 4 

=item id

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

1;