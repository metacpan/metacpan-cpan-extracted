package WWW::Scrape::BillionGraves;

use warnings;
use strict;
use HTTP::Request;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use URI;
use Carp;

# Request send JSON to https://billiongraves.com/api/1.3/search, for example
# {"given_names":"isaac","family_names":"horne","death_year":"1964","exact":false,"phonetic":false,"year_range":0,"military":false,"conflict":null,"branch":null,"rank":null,"start":0,"size":15}
# gets JSON back

=head1 NAME

WWW::Scrape::BillionGraves - Scrape the BillionGraves website

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WWW::Scrape::BillionGraves;

    my $bg = WWW::Scrape::BillionGraves->new({
	firstname => 'John',
	lastname => 'Smith',
	country => 'England',
	date_of_death => 1862
    });

    while(my $url = $bg->get_next_entry()) {
	print "$url\n";
    }
}

=head1 SUBROUTINES/METHODS

=head2 new

Creates a WWW::Scrape::BillionGraves object.

It takes two mandatory arguments firstname and lastname.

Also one of either date_of_birth and date_of_death must be given.

There are two optional arguments: middlename and host.

host is the domain of the site to search, the default is billiongraves.com.
=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my %args;
	if(ref($_[0]) eq 'HASH') {
		%args = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak("Usage: __PACKAGE__->new(%args)");
	} elsif(@_ % 2 == 0) {
		%args = @_;
	}

	die "First name is not optional" unless($args{'firstname'});
	die "Last name is not optional" unless($args{'lastname'});
	die "You must give one of the date of birth or death"
		unless($args{'date_of_death'} || $args{'date_of_birth'});

	my $ua = delete $args{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	$ua->env_proxy(1);

	my $rc = {
		ua => $ua,
		date_of_birth => $args{'date_of_birth'},
		date_of_death => $args{'date_of_death'},
		country => $args{'country'},
		firstname => $args{'firstname'},
		middlename => $args{'middlename'},
		lastname => $args{'lastname'},
		year_range => 0,
		matches => 0,
		index => 0,
		size => 15,
		start => 0,
	};
	$rc->{'host'} = $args{'host'} || 'billiongraves.com';

# {"given_names":"isaac","family_names":"horne","death_year":"1964","exact":false,"phonetic":false,"year_range":0,"military":false,"conflict":null,"branch":null,"rank":null,"start":0,"size":15}
	my $query_parameters;
	if($args{'firstname'}) {
		$query_parameters->{'given_names'} = $args{'firstname'};
	}
	if($args{'middlename'}) {
		$query_parameters->{'middlename'} = $args{'middlename'};
	}
	if($args{'lastname'}) {
		$query_parameters->{'family_names'} = $args{'lastname'};
	}
	if($args{'date_of_birth'}) {
		$query_parameters->{'birth_year'} = $args{'date_of_birth'};
	}
	if($args{'date_of_death'}) {
		$query_parameters->{'death_year'} = $args{'date_of_death'};
	}
	if($args{'country'}) {
		if($args{'country'} eq 'England') {
			$query_parameters->{'cemetery_country'} = 'United Kingdom';
			$query_parameters->{'cemetery_state'} = 'England';
		} else {
			$query_parameters->{'cemetery_country'} = $args{'country'};
		}
	}
	my $json = JSON->new();
	my $data = $json->encode($query_parameters);

	my $uri = URI->new("https://$rc->{host}/api/1.3/search");
	my $req = HTTP::Request->new('POST', $uri);
	$req->header('Content-Type' => 'application/json');
	$req->content($data);

	# my $url = $uri->as_string();
	# ::diag($url);

	my $resp = $ua->request($req);

	$rc->{'resp'} = $resp;
	$data = $json->decode($resp->content());

	my @items = $data->{'items'};
	$rc->{'matches'} = scalar(@items);
	$rc->{'query_parameters'} = $query_parameters;
	$rc->{'items'} = $data->{'items'};
	$rc->{'json'} = $json;
	return bless $rc, $class;
}

=head2 get_next_entry

Returns the next match as a URL to the BillionGraves page.

=cut

sub get_next_entry
{
	my $self = shift;

	return if(!defined($self->{'matches'}));
	return if($self->{'matches'} == 0);

	my $rc = pop @{$self->{'results'}};
	return $rc if $rc;

	return if($self->{'index'} >= $self->{'matches'});

	my $firstname = $self->{'firstname'};
	my $lastname = $self->{'lastname'};
	# my $date_of_death = $self->{'date_of_death'};	# FIXME: check results against this
	# my $date_of_birth = $self->{'date_of_birth'};	# FIXME: check results against this

	foreach my $item (@{$self->{'items'}}) {
		push @{$self->{'results'}}, "https://$self->{host}/$item->{url}";
	}
	$self->{'index'}++;
	if($self->{'index'} <= $self->{'matches'}) {
		$self->{'query_parameters'}->{'start'} += 15;

		my $uri = URI->new("https://$self->{host}/api/1.3/search");

		my $json = $self->{'json'};
		my $data = $json->encode($self->{'query_parameters'});

		my $req = HTTP::Request->new('POST', $uri);
		$req->header('Content-Type' => 'application/json');
		$req->content($data);

		# my $url = $uri->as_string();
		# ::diag($url);

		my $resp = $self->{'ua'}->request($req);

		$self->{'resp'} = $resp;
		$data = $json->decode($resp->content());

		my @items = @{$data->{'items'}};
		$self->{'matches'} = scalar(@items);
		$self->{'items'} = $data->{'items'};
	}

	return pop @{$self->{'results'}};
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-scrape-billiongraves at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scrape-BillionGraves>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<https://github.com/nigelhorne/gedcom>
L<https://billiongraves.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Scrape::BillionGraves

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scrape-BillionGraves>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Scrape-BillionGraves>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Scrape-BillionGraves>

=item * Search CPAN

L<https://metacpan.org/release/WWW-Scrape-BillionGraves>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of WWW::Scrape::BillionGraves
