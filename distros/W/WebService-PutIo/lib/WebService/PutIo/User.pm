package WebService::PutIo::User;

use base 'WebService::PutIo';

my $class='user';

sub info { shift->request($class,'info',@_); }
sub friends { shift->request($class,'friends',@_); }
sub token { shift->request($class,'acctoken',@_); }

=head1 NAME

WebService::PutIo::URLs - Analyze URLs

=head1 SYNOPSIS

    use WebService::PutIo::URLs;
	my $urls=WebService::PutIo::URLs->new(api_key=>'..',api_secret=>'..');
	my $res=$urls->analyze;
	foreach my $url (@{$res->urls}) {
	   print "Got ". Data::Dumper($url);
	}

=head1 DESCRIPTION

Methods to analyze urls for use with put.io

=head1 METHODS 

=head2 info

Returns more detailed info about the user.

=head2 friends

Returns user's friend list.

=head2 token

Returns user's access token.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

1;