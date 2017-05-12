package WWW::Finger::CPAN;

use 5.010;
use common::sense;
use utf8;

use Digest::MD5 0 qw(md5_hex);
use JSON 2.00 qw(from_json);
use LWP::Simple 0 qw(get);

use parent qw(WWW::Finger);

BEGIN {
	$WWW::Finger::CPAN::AUTHORITY = 'cpan:TOBYINK';
	$WWW::Finger::CPAN::VERSION   = '0.105';
}

sub speed { 50 }

sub new
{
	my $class = shift;
	my $ident = shift;
	my $self  = bless {}, $class;

	$ident = "mailto:$ident"
		unless $ident =~ /^[a-z0-9\.\-\+]+:/i;
	$ident = URI->new($ident);
	
	return undef
		unless $ident;
		
	$self->{ident} = $ident;
	
	my ($user, $host) = split /\@/, $self->{ident}->to;
	return undef
		unless lc $host eq 'cpan.org';
	
	return $self;
}

sub name
{
	my $self = shift;
	my $name = $self->metacpan_data->{name};
	
	return wantarray
		? @{ [$name] }
		: $name;
}

sub mbox
{
	my $self = shift;	
	my @e    = @{$self->metacpan_data->{email}};
	
	return wantarray
		? @e
		: $e[0];
}

sub pauseid
{
	my $self = shift;
	my ($user, $host) = split /\@/, uc $self->{ident}->to;

	return wantarray
		? @{[ $user ]}
		: $user;
}

sub cpanpage
{
	my $self = shift;
	my $user = $self->pauseid;
	my $cpanpage = 'https://metacpan.org/author/' . (uc $user) . '/';
	
	return wantarray
		? @{[$cpanpage]}
		: $cpanpage;
}

sub homepage
{
	my $self = shift;
	my @hp   = @{$self->metacpan_data->{website}};
	
	push @hp, scalar $self->cpanpage
		unless grep { $self->cpanpage eq $_ } @hp;
	
	return wantarray
		? @hp
		: $hp[0];
}

sub image
{
	my $self = shift;
	my $md5  = lc md5_hex(lc $self->{ident}->to);
	
	return wantarray
		? @{ ["http://www.gravatar.com/avatar/$md5.jpg"] }
		: "http://www.gravatar.com/avatar/$md5.jpg";
}

sub weblog
{
	my $self = shift;	
	my @blog = map { $_->{url} } @{$self->metacpan_data->{blog}};
	
	return wantarray
		? @blog
		: $blog[0];
}

sub metacpan_data
{
	my $self = shift;
	
	unless ($self->{metacpan_data})
	{
		my $user = $self->pauseid;
		my $uri  = sprintf('http://api.metacpan.org/v0/author/%s', uc $user);
		$self->{metacpan_data} = from_json(get($uri));
	}
	
	$self->{metacpan_data};
}

sub releases
{
	my $self = shift;
	
	unless ($self->{releases})
	{
		my $user = $self->pauseid;
		my $uri  = sprintf('http://api.metacpan.org/v0/release/_search?q=author:%s%%20AND%%20status:latest&size=100', uc $user);
		$self->{releases} = [ map { $_->{_source} } @{ from_json(get($uri))->{hits}->{hits} } ];
	}
	
	return wantarray
		? @{ $self->{releases} }
		: scalar @{ $self->{releases} };
}

sub webid
{
	my $self = shift;
	my $user = $self->pauseid;
	my $webid = 'http://purl.org/NET/cpan-uri/person/' . lc $user;
	
	return wantarray
		? @{[ $webid ]}
		: $webid;
}

1;
__END__

=head1 NAME

WWW::Finger::CPAN - WWW::Finger implementation using MetaCPAN.

=head1 DESCRIPTION

Additional methods (other than standard WWW::Finger):

=over

=item * C<pauseid> - returns the person's PAUSE ID.

=item * C<cpanpage> - returns the person's metacpan.org homepage.

=item * C<metacpan_data> - hashref of interesting data.

=item * C<releases> - list of releases. If called in scalar context, count of releases.

=back

=head1 SEE ALSO

L<WWW::Finger>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009-2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
