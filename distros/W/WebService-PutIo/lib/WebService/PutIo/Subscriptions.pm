package WebService::PutIo::Subscriptions;

use base 'WebService::PutIo';

my $class='subscriptions';

sub list { shift->request($class,'list',@_); }
sub create { shift->request($class,'create',@_); }
sub edit { shift->request($class,'edit',@_); }
sub delete { shift->request($class,'delete',@_); }
sub pause { shift->request($class,'pause',@_); }
sub info { shift->request($class,'info',@_); }

=head1 NAME

WebService::PutIo::Subscriptions - Manage RSS Subscriptions

=head1 SYNOPSIS

    use WebService::PutIo::Subscriptions;
	my $subs=WebService::PutIo::Subscriptions->new(api_key=>'..',api_secret=>'..');
	my $res=$subs->list;
	foreach my $sub (@{$res->results}) {
	   print "Got ". Data::Dumper($sub);
	}

=head1 DESCRIPTION

Methods to manage RSS subscriptions on put.io

=head1 METHODS

=head2 list

Returns a list of subscriptions

=head2 create

Creates a subscription and returns it.

=head3 Parameters:

=over 4

=item title

=item url

=item do_filters

=item dont_filters

=item parent_folder_id

=item paused

=back

=head2 edit

Updates a subscription and returns it.

=head3 Parameters:

=over 4

=item id

=item title

=item url

=item do_filters

=item dont_filters

=item parent_folder_id

=item paused

=back

=head2 delete

Deletes a subscription.

=head3 Parameters:

=over 4

=item id

=back

=head2 pause

Toggles the activity of a subscription. Use it to pause or resume.

=head3 Parameters:

=over 4

=item id

=back

=head2 info

Returns detailed information of a subscription

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