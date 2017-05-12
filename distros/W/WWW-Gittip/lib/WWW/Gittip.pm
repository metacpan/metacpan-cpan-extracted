package WWW::Gittip;
use strict;
use warnings;

use LWP::UserAgent;
use JSON qw(from_json);
use HTML::TreeBuilder 5 -weak;

our $VERSION = '0.07';
my $BASE_URL = 'https://www.gratipay.com';

=head1 NAME

WWW::Gittip - Implementing the Gittip (now Gratipay) API. More or less.

=head1 SYNOPSIS

  use WWW::Gittip;
  my $gt = WWW::Gittip->new;
  my $charts = $gt->charts;

  my $user_charts = $gt->user_charts('szabgab');

=head1 DESCRIPTION

This module provides a Perl interface to the L<Gratipay|http://www.gratipay.com> API.
Gittip describes itself as "a way to give small weekly cash gifts to people you
love and are inspired by". It is one way you can give small recurring amounts to
people who've written open source software that you regularly use.

The API docs of Gittp: L<https://github.com/gittip/www.gittip.com#api>

When necessary, you can get an API key from your account on Gittip at L<https://www.gratipay.com/about/me/account>

=cut


=head2 new

  my $gt = WWW::Gittip->new;
  my $gt = WWW::Gittip->new( api_key => '123-456' );


=cut

sub new {
	my ($class, %params) = @_;
	bless \%params, $class;
}

=head2 api_key

Set/Get the API_KEY

  $gt->api_key('123-456');

  my $api_key = $gt->api_key;

=cut


sub api_key {
	my ($self, $value) = @_;
	if (defined $value) {
		$self->{api_key} = $value;
	}
	return $self->{api_key};
}


=head2 charts

Returns an array reference from /about/charts.json
Each element in the array has the following fields:

    {
        "active_users" => 50,
        "charges"      => 25.29,
        "date"         => "2012-06-22",
        "total_gifts"  => 62.08,
        "total_users"  => 621,
        "weekly_gifts" => 30.08,
        "withdrawals"  => 0.00
    },

=cut


sub charts {
	my ($self) = @_;

	my $url = "$BASE_URL/about/charts.json";
	return $self->_get($url);
}

=head2 user_charts

   $gt->user_charts(USERNAME);

Returns an array referene from /%username/charts.json
Each element in the array has the following fields:

   {
     'date'     => '2012-06-08',
     'npatrons' => 0,
     'receipts' => '0',
     'ts_start' => '2012-06-08T12:02:45.182409+00:00'
   }


=cut


sub user_charts {
	my ($self, $username) = @_;

	#croak "Invalid username '$username'" if $username eq 'about';

	my $url = "$BASE_URL/$username/charts.json";
	return $self->_get($url);
}


=head2 paydays

Returns an array reference from /about/paydays.json
Each element in the array has the following fields:

     {
       'ach_fees_volume'    => '0',
       'ach_volume'         => '0',
       'charge_fees_volume' => '2.11',
       'charge_volume'      => '25.28',
       'nachs'              => 0,
       'nactive'            => 25
       'ncc_failing'        => 1,
       'ncc_missing'        => 18,
       'ncharges'           => 11,
       'nparticipants'      => 175,
       'ntransfers'         => 49,
       'ntippers'           => 12,
       'transfer_volume'    => '24.8',
       'ts_end'             => '2012-06-08T12:03:19.889215+00:00',
       'ts_start'           => '2012-06-08T12:02:45.182409+00:00',
     },

=cut

sub paydays {
	my ($self) = @_;

	my $url = "$BASE_URL/about/paydays.json";
	return $self->_get($url);
}

=head2 stats

Returns a reference to a hash from /about/stats.json
with lots of keys...

=cut



sub stats {
	my ($self) = @_;

	my $url = "$BASE_URL/about/stats.json";
	return $self->_get($url);
}

=head2 communities

See L<https://github.com/gittip/www.gittip.com/issues/2014>

L<https://www.gratipay.com/for/perl/?limit=20>

L<https://www.gratipay.com/for/perl/?limit=20&offset=20>

L<https://github.com/gittip/www.gittip.com/issues/2408>

Currently only returns an empty list.

=cut

sub communities {
	my ($self) = @_;

	my $url = "$BASE_URL/for/communities.json";
	return $self->_get($url);
}

=head2 user_public

   $gt->user_public(USERNAME);

Returns an hash referene from /%username/public.json
Some of the fields look like these:


    {
          'id' => 25031,
          'username' => 'szabgab',
          'number' => 'singular',
          'on' => 'gittip',
          'giving' => undef,
          'npatrons' => 7,
          'receiving' => '5.01',
          'goal' => undef,
          'avatar' => 'https://avatars.githubusercontent.com/u/48833?s=128',
          'bitcoin' => 'https://blockchain.info/address/1riba1Z6o3man18rASVyiG6NeFAhvf7rU',
          'elsewhere' => {
                           'github' => {
                                         'user_id' => '48833',
                                         'id' => 85177,
                                         'user_name' => 'szabgab'
                                       },
                           'twitter' => {
                                          'user_id' => '21182516',
                                          'user_name' => 'szabgab',
                                          'id' => 424525
                                        }
                         },
    };

=cut

sub user_public {
	my ($self, $username) = @_;

	my $url = "$BASE_URL/$username/public.json";
	return $self->_get($url);
}

# https://www.gratipay.com/about/tip-distribution.json
# returns an array of numbers \d+\.\d\d  (over 8000 entries), probably the full list of tips.

=head2 user_tips

Requires API_KEY.

GET /%username/tips.json  and returns an array reference of hashes.
Each hash is looks like this

          {
            'username' => 'perlweekly',
            'platform' => 'gittip',
            'amount' => '1.01'
          }

  $gt->user_tips($username);

=cut

sub user_tips {
	my ($self, $username) = @_;

	my $url = "$BASE_URL/$username/tips.json";
	return $self->_get($url);
}

=head2 community_members

  $gt->community_members('perl');

Given the name of a community, returns a hash with 3 keys:
new, give, and receive corresponding to the 3 columns of the
https://www.gratipay.com/for/perl page.

Each key has an array reference as the value. Each arr has several elements:

  {
    new => [
      {
        name => 'szabgab',
      },
      {
        name => 'rjbs',
      },
      ...
    ],
    give => [
      ...
    ],
    receive => [
      ...
    ],
  }

There is no official API, so this call is scraping the HTML page.
Currently Gittip limits the number of people shown in each column to 100. 

The user could set the limt at a lower number using limit=... in the URL.
The user can also set the starting user using offset=...

WWW::Gittip sends multiple requests as necessary to fetch all the users.
It uses limit=100 and the appropriate offset=  for each request.

=cut

sub community_members {
	my ($self, $name) = @_;

# limit=10
# offset=12

	my %NAMES = (
		'New Members'   => 'new',
		'Top Givers'    => 'give',
		'Top Receivers' => 'receive',
	);

	my %members;

	my $limit  = 100;
	my $offset = 0;
	my $total;
	while (1) {
		my $url = "$BASE_URL/for/$name?limit=$limit&offset=$offset";

		print "Requesting: $url\n";

		my $response = $self->_get_html($url);

		if (not $response->is_success) {
			warn 'Failed';
			return;
		}


		my $html = $response->decoded_content;
		my $tree = HTML::TreeBuilder->new;
		$tree->parse($html);

		if (not $total) {
			# <div class="on-community">
			#     <h2 class="pad-sign">Perl</h2>
			#     <div class="number">516</div>
			#     <div class="unit pad-sign">members</div>
			# </div>
			my $cl = $tree->look_down('class', 'on-community');
			my $n = $cl->look_down('class', 'number');
			$total = $n->as_text;
		}

		my $leaderboard = $tree->look_down('id', 'leaderboard');
		foreach my $ch ($leaderboard->content_list) {
			next if not defined $ch or ref($ch) ne 'HTML::Element';
			# The page had 4 columns, one of them was empty.
			my $h2 = $ch->look_down('_tag', 'h2');
			my $type = $NAMES{ $h2->as_text };

			my $group = $ch->look_down('class', 'group');
			foreach my $member ($group->content_list) {
				next if not defined $member or ref($member) ne 'HTML::Element';
				# I think these are the anonymous members.

				my $n = $member->look_down('class', 'name');
				push @{ $members{$type} }, {
					name => $n->as_text,
				};
			}
		}

		$offset += $limit;
		if (not $total) {
			warn "Could not find total number of members\n";
			last;
		}
		last if $offset >= $total;
	}

	return \%members;
	
#<div id="leaderboard">
#
#    <div class="people">
#        <h2>New Members</h2>
#        <ul class="group">
#            
#            <li>
#                <a href="/dwierenga/" class="mini-user tip"
#                data-tip="">
#                    <span class="inner">
#                        <span class="avatar"
#                            style="background-image: url(\'https://avatars.githubusercontent.com/u/272648?s=128\')">
#                        </span>
#                        <span class="age">14 <span class="unit">hours</span></span>
#                        <span class="name">dwierenga</span>
#                    </span>
#                </a>
#            </li>

}

sub _get_html {
	my ($self, $url) = @_;

	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);

	my $api_key = $self->api_key;
	if ($api_key) {
		require MIME::Base64;
		$ua->default_header('Authorization',  "Basic " . MIME::Base64::encode("$api_key:", '') );
	}

	my $response = $ua->get($url);
	return $response;

}


sub _get {
	my ($self, $url) = @_;

	my $response = $self->_get_html($url);
	if (not $response->is_success) {
		warn "Failed request $url\n";
		warn $response->status_line . "\n";
		return [];
	}

	my $charts = $response->decoded_content;
	if (not defined $charts or $charts eq '') {
		warn "Empty return\n";
		return [];
	}
	my $data = eval { from_json $charts };
	if ($@) {
		warn $@;
		warn "Data received: '$charts'\n";
		$data = [];
	}
	return $data;
}



=head1 AUTHOR

Gabor Szabo L<http://perlmaven.com/>

=head1 LICENSE

Copyright (c) 2014, Gabor Szabo L<http://szabgab.com/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;


