package WebService::PutIo::URLs;

use base 'WebService::PutIo';

my $class='urls';

sub analyze { shift->request($class,'analyze',@_); }
sub extracturls { shift->request($class,'extracturls',@_); }

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

=head2 analyze

Returns an array of urls that Put.io can fetch

=head3 Parameters:

=over 4

=item urls

=back

=head2 extracturls

Returns an array of urls

=head3 Parameters:

=over 4

=item txt

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

1;