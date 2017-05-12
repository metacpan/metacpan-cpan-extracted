package WWW::Metaweb;

use 5.008006;
use strict;
use warnings;

use JSON::XS;
use LWP::UserAgent;
use URI::Escape;
use HTTP::Request;
use Carp;

# debugging
use Data::Dumper;

our $VERSION = '0.02';
our $errstr = '';

=head1 NAME

WWW::Metaweb - An interface to the Metaweb database via MQL

=head1 SYNOPSIS

  use strict;
  use WWW::Metaweb;

  my $mh = WWW::Metaweb->connect( username => $u,
				  password => $p, 
				  server => 'www.freebase.com',
				  auth_uri => '/api/account/login',
				  read_uri => '/api/service/mqlread',
				  write_uri => '/api/service/mqlwrite',
				  trans_uri => '/api/trans',
				  pretty_json => 1 );

  my $query = {
	  '/type/object/creator' => undef,
	  cover_appearances => [{
	    type => '/comic_books/comic_book_issue',
	    name => undef,
	    part_of_series => undef
	  }],
	  created_by => [],
	  id => undef,
	  name => 'Nico Minoru',
	  type => '/comic_books/comic_book_character'
  };

The easy way:

  my $result = $mh->read($query, 'json');
  print $result;

The complicated way:

  $mh->add_query('read', $query);
  $mh->send_envelope('read')
    or die $WWW::Metaweb::errstr;

  my $result = $mh->result('read', 'json');
  print $result . "\n";

=head1 ABSTRACT

WWW::Metaweb provides an interface to a Metaweb database through it's HTTP API and MQL.

=head1 DESCRIPTION

WWW::Metaweb provides an interface to a Metaweb database instance. The best example currently is Freebase (www.freebase.com). Queries to a Metaweb are made through HTTP requests to the Metaweb API.

Qeueries are written in the Metaweb Query Language (MQL), using Javascript Object Notation (JSON). WWW::Metaweb allows you to write the actual JSON string yourself or provide a Perl array ref / hash ref structure to be converted to JSON.

=head1 METHODS

=head2 Class methods

=over

=item B<< $version = WWW::Metaweb->version >>

Returns the version of WWW::Metaweb being used.

=back

=cut

sub version  {
	return $WWW::Metaweb::VERSION;
} # ->version

=head2 Constructors

=over

=item B<< $mh = WWW::Metaweb->connect( [option_key => 'option_value' ...] ) >>

Returns a new WWW::Metaweb instance, a number of different attributes can be sethere (see below).

If a C<username> and C<password> are supplied then C<connect()> will attempt to authenticate before returning. If this authentication fails then C<undef> will be returned.

=over

=item B<< Metaweb parameters >>

=over

=item B<< auth_uri >>

The URI used to authenticate for this Metaweb (eg. /api/account/login).

=item B<< read_uri >>

The URI used to submit a read MQL query to this Metaweb (eg. /api/service/mqlread).

=item B<< write_uri >>

The URI used to submit a write MQL query to this Metaweb (eg. /api/service/mqlwrite).

=item B<< trans_uri >>

The URI used to access the translation service for this Metaweb (eg. /api/trans). Please note this this URI does not include the actual C<translation>, at this time these are C<raw>, C<image_thumb> and C<blurb>.

=back

=item B<< JSON parameters >>

=over

=item B<< pretty_json >>

Determines whether the response to a JSON query is formatted nicely. This is just passed along to the JSON object as C<JSON::XS->new->pretty($mh->{pretty})>.

=item B<< json_preprocessor >>

Can provide a reference to a sub-routine that pre-processes JSON queries, the sub-routine should expect one argument - the JSON query as a string and return the processed JSON query as a scalar.

=back

=back

=cut

sub connect  {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my ($username, $password);


	my $options = { @_ };
	$username = $options->{username} || '' if exists $options->{username};
	$password = $options->{password} || '' if exists $options->{password};
	delete $options->{username};
	delete $options->{password};

	my $self = {
		     auth_uri => undef,
		     read_uri => undef,
		     write_uri => undef,
		     trans_uri => undef,
		     read_envelope => { },
		     write_envelope => { },
		     result_envelope => { },
		     json_preprocessor => undef,
		     pretty_json => 0,
		     query_counter => 0,
		     debug => 0
		   };
	
	bless $self, $class;
	
	$self->server($options->{server}); # Sets the server.
	delete $options->{server};
	# Sets the option attributes from $options into $self.
	foreach my $key (keys %$options)  {
		if (exists $self->{$key})  {
			$self->{$key} = $options->{$key};
		}
		else  {
			carp "Unknown option '$key' used in connect().";
		}
	}

	# A little bit of vanity here (the agent).
	$self->useragent(LWP::UserAgent->new( agent => 'Metaweb/'.$WWW::Metaweb::VERSION,
					      timeout => 10)
			);

	# Attempt to authenticate if $username and $password are defined.
	# As far as Freebase goes this is a required step right now.
	if (defined $username && defined $password)  {
		$self = undef unless ($self->authenticate($username, $password));
	}

	return $self;
} # ->connect

=back

=head2 Authentication

=over

=item B<< $mh->authenticate($username, $password) >>

Authenticates to the auth_uri using the supplied username and password. If the authentication is successful then the cookie is retained for future queries.

In the future this method may give the option to accept a cookie instead of username and password.

=cut

sub authenticate  {
	my $self = shift;
	my ($username, $password) = @_;
	my ($response, $raw_header, $credentials, @cookies);
	my $login_url = $self->server.$self->{auth_uri};


	$response = $self->useragent->post($login_url, { username => $username,
						       	 password => $password
						       });
	# This would indicate some form of network problem (such as the server
	# being down).
	unless ($response->is_success)  {
		$WWW::Metaweb::errstr = 'Authentication HTTP request failed: ' . $response->status_line;
		return undef;
	}

	unless ($raw_header = $response->header('Set_Cookie'))  {
		# Authentication failed.
		my $jsonxs = JSON::XS->new->utf8;
		my $reply = $jsonxs->decode($response->content);
		$WWW::Metaweb::errstr = "Login failed: [status: $reply->{status}, code: $reply->{code}]";
		
		return undef;
	}
	@cookies = split /,\s+/, $raw_header;
	$credentials = '';
	my $crumb_count = 0;
	foreach my $cookie (@cookies)  {
		my @crumbs = split ';', $cookie;
		$credentials .= ';';
		$credentials .= $crumbs[0];
	}

	$self->useragent->default_header('Cookie' => $credentials);
	$self->{authenticated} = 1;

	return 1;
} # ->authenticate

=back

=head2 Easy Querying

=over

=item B<< @results = $mh->read($read_query [, $read_query2 ...] [, $format]) >> or B<< $result = $mh->read($read_query [, $format]) >>

The easy way to perform a read query.

Accepts one or more queries which are bundled up in one envelope and sent to the read service. The response is an array containing the results in the same order as the queries were given in.

If only one query is given and assigned to a scaler then the single query will be returned as a scaler instead of in an array.

=cut

sub read  {
	my $self = shift;
	my @read_queries = @_;
	my ($i, $format);

	$self->clear_read_queries;
	
	# Add each query to the envelope and replace it's place in the array
	# with the query name asigned to it.
	for ($i = 0; $i < @read_queries; $i++)  {
		if ($read_queries[$i] eq 'perl' || $read_queries[$i] eq 'json')  {
			$format = $read_queries[$i];
			delete $read_queries[$i];
		}
		else  {
			my $read_query = $read_queries[$i];
			$read_queries[$i] = "query$i";

			$self->add_read_query($read_queries[$i] => $read_query);
			#carp 'WWW::Metaweb - Bad format in read() - ($format = \'' . $read_queries[$i] . '\')';
			#delete $read_queries[$i];
		}
	}

	# We're helpless if this fails, return undef and trust the errstr has
	# been set further down.
	return undef unless (defined $self->send_read_envelope);

	# Replace the query names in our array with the result of the query.
	map { $_ = $self->result($_, $format); } @read_queries;

	# If there is only one result and an array hasn't been asked for, return
	# the single value as a scaler instead.
	return (@read_queries == 1 && not wantarray) ? $read_queries[0] : @read_queries;
} # ->read

=item B<< @result = $mh->write($write_query [, $write_query2 ...] [, $format]) >> or B<< $result = $mh->write($write_query [, $format]) >>

The easy way to perform a write query.

The syntax and behaviour are exactly the same as C<read()> (above).

=cut

sub write  {
	my $self = shift;
	my @write_queries = @_;
	my ($i, $format);

	# This method works exactly the same as the read method.
	
	$self->clear_write_queries;
	
	for ($i = 0; $i < @write_queries; $i++)  {
		if ($write_queries[$i] eq 'perl' || $write_queries[$i] eq 'json')  {
			$format = $write_queries[$i];
			delete $write_queries[$i];
		}
		else  {
			my $write_query = $write_queries[$i];
			$write_queries[$i] = "query$i";

			$self->add_write_query($write_queries[$i] => $write_query);
		}

	}

	return undef unless defined $self->send_write_envelope;

	map { $_ = $self->result($_, $format); } @write_queries;

	return (@write_queries == 1 && not wantarray) ? $write_queries[0] : @write_queries;
} # ->write

=back

=head2 Translation Service

=over

=item B<< $content = $mh->trans($translation, $guid) >>

Gets the content for a C<guid> in the format specified by C<$translation>. Metaweb currently supports the translations C<raw>, C<image_thumb> and C<blurb>.

C<$translation> is not checked for validity, but an error will most likely be returned by the server.

C<$guid> should be the global identifier of a Metaweb object of type C</common/image> or C</type/content> and/or C</common/document> depending on the translation requested, if not the Metaweb will return an error. The global identifier can be prefixed with either a '#' or the URI escaped version '%23' then followed by the usual string of lower case hex.

=cut

sub trans  {
	my $self = shift;
	my $translation = shift;
	my $guid = lc shift;
	my ($url, $response);

	# Check that the guid looks mostly correct and replace a hash at the
	# beginning of the guid with the URI escape code.
	unless ($guid =~ s/^(\#|\%23)([\da-f]+)$/\%23$2/)  {
		$WWW::Metaweb::errstr = "Bad guid: $guid";
		return undef;
	}

	$url = $self->server.$self->{trans_uri}.'/'.$translation.'/'.$guid;
	$response = $self->useragent->get($url);
	
	# An HTTP response that isn't success indicates something bad has
	# happened and there's nothing I can do about it.
	unless ($response->is_success)  {
		$WWW::Metaweb::errstr = "Trans query failed, HTTP response: " . $response->status_line;
		return undef;
	}

	return $response->content;
} # ->trans

=item B<< $content = $mh->raw($guid) >>

Convenience method for getting a C<raw> translation of the object with C<$guid>. See C<trans()> for more details.

=cut

sub raw  {
	my $self = shift;
	my $guid = shift;

	return $self->trans('raw', $guid);
} # ->raw

=item B<< $content = $mh->image_thumb($guid) >>

Convenience method for getting a C<image_thumb> translation of the object with C<$guid>. See C<trans()> for more details.

=cut

sub image_thumb  {
	my $self = shift;
	my $guid = shift;

	return $self->trans('image_thumb', $guid);
} # ->image_thumb

=item B<< $content = $mh->blurb($guid) >>

Convenience method for getting a C<blurb> translation of the object with C<$guid>. See C<trans()> for more details.

=cut

sub blurb  {
	my $self = shift;
	my $guid = shift;

	return $self->trans('blurb', $guid);
} # ->blurb

=back

=head2 Complicated Querying

=over

=item B<< $mh->add_query($method, query_name1 => $query1 [, query_name2 => $query2 [, ...]]) >>

This method adds queries to a query envelope. C<$method> must have a value of either 'read' or 'write'.

Each query must have a unique name, otherwise a new query will overwrite an old one. By the same token, if you wish to change a query in the query envelope, simply specify a new query with the old query name to overwrite the original.

A query may either be specified as a Perl structure, or as a JSON string. The first example below is a query as a Perl structure.

  $query_perl = {
	  name => "Nico Minoru",
	  id => undef,
	  type => [],
	  '/comic_books/comic_book_character/cover_appearances' => [{
		name => null  
	  }]
  };

The same query as a JSON string:

  $query_json = '
  {
	  "name":"Nico Minoru",
	  "id":null,
	  "type":[],
	  "/comic_books/comic_book_character/cover_appearances":[{
		  "name":null
	  }]
  }';

For the same of completeness this JSON query can be submitted the same way as in the query editor, a shortened version formatted like this is below:

  $query_json_ext = '
  {
	  "query":{
		  "name":"Nico Minoru",
		  "type":[]
	  }
  }';

Now we can add all three queries specified above to the envelope with one call.

  $mh->add_query( query_perl => $query_perl, query_json => $query_json, query_json_ext => $query_json_ext );

=cut

sub add_query  {
	my $self = shift;
	my $method = shift;
	my ($envelope, $queries);

	return undef unless $envelope = __test_envelope($method, 'add_query');

	if (@_ == 1)  {
		my $query = shift;
		$queries = { netmetawebquery => $query };
	}
	elsif (@_ > 1 && (@_ % 2) == 0)  {
		$queries = { @_ };
	}
	else  {
		$WWW::Metaweb::errstr = "Query name found with missing paired query. You probably have an odd number of query names and queries.";
		return undef;
	}

	my ($query_name, $query);
	my $no_error = 1;	
	foreach $query_name (keys %$queries)  {
		$query = $queries->{$query_name};
		$no_error = 0 unless $self->check_query_syntax($method, $queries->{$query_name});

		if (ref $query eq 'HASH' or ref $query eq 'ARRAY')  {
			# It's a Perl structure.
			if (((ref $query) eq 'HASH' && (not defined $query->{query})) || ((ref $query) eq 'ARRAY' && (not defined $query->[0]->{query})))  {
				$query = { query => $query };
			}
			$query->{anti_cache} = (time . $self->{query_counter}++);
			$query->{cursor} = JSON::XS::true if $self->{auto_cursors} && not defined $query->{cursor};
		}
		elsif ((not ref $query))  {
			# It's a JSON string - but we'll convert it to Perl and
			# back again to manipulate it.
			my ($jxs, $p_query);
			$p_query = from_json($query);
			if (((ref $p_query) eq 'HASH' && (not defined $p_query->{query})) || ((ref $p_query eq 'ARRAY') && (not defined $p_query->[0]->{query})))  {	
				$p_query = { query => $p_query };
			}
			$p_query->{anti_cache} = (time . $self->{query_counter}++);
			$p_query->{cursor} = JSON::XS::true if $self->{auto_cursors} && not defined $query->{cursor};
			$query = to_json($p_query);
		}
		# Now store it for sending.
		$self->{$envelope}->{$query_name} = $query;
	}

	return $no_error;
} # ->add_query

=item B<< $mh->clear_queries($method) >>

Clears all the previous queries from the envelope.

C<$method> must be either 'read' or 'write'.

=cut

sub clear_queries  {
	my $self = shift;
	my $method = shift;
	my $envelope;

	return undef unless $envelope = __test_envelope($method, 'clear_envelope');

	$self->{$envelope} = { };

	return 1;
} # ->clear_queries

=item B<< $count = $mh->query_count($method) >>

Returns the number of queries held in the C<$method> query envelope.

=cut

sub query_count  {
	my $self = shift;
	my $method = shift;
	my ($envelope, @keys, $key_count);

	return undef unless $envelope = __test_envelope($method, 'query_count');
	@keys = keys %{$self->{$envelope}};
	$key_count = @keys;
	
	return $key_count; 
} # ->query_count

=item B<< $bool = $mh->check_query_syntax($method, $query) >>

Returns a boolean value to indicate whether the query provided (either as a Perl structure or a JSON string) follows correct MQL syntax. C<$method> should be either 'read' or 'write' to indicate which syntax to check query against.

Note: This method has not yet been implemented, it will always return TRUE.

=cut

sub check_query_syntax  {
	my $self = shift;
	my $method = shift;
	my $query = shift;

	return 1;
} # ->check_query_syntax

=item B<< $http_was_successful = $mh->send_envelope($method) >>

Sends the current query envelope and returns whether the HTTP portion was successful. This does not indicate that the query itself was well formed or correct.

C<$method> must be either 'read' or 'write'.

=cut

sub send_envelope  {
	my $self = shift;
	my $method = shift;
	my $envelope;

	return undef unless $envelope = __test_envelope($method, 'send_envelope');

	my $jsonxs = JSON::XS->new->utf8;
	my ($json_envelope, $url, $request, $response);

	# Create a list of pre-processors
	my @preprocessors;
	if (ref $self->{json_preprocessor} eq 'CODE')  {
		@preprocessors = ( $self->{json_preprocessor} );
	}
	elsif (ref $self->{json_preprocessor} eq 'ARRAY')  {
		foreach my $sub (@{$self->{json_preprocessor}})  {
			push @preprocessors, $sub if (ref $sub eq 'CODE');
		}
	}
	
	my $first = 1;
	$json_envelope = '{';
	foreach my $query_name (keys %{$self->{$envelope}})  {
		my $query = (ref $self->{$envelope}->{$query_name}) ? $jsonxs->encode($self->{$envelope}->{$query_name}) : $self->{$envelope}->{$query_name};
		#$query =~ s/"format":"(?:json|perl)",//;

		foreach my $sub (@preprocessors)  {
			$query = &$sub($query);
		}
		# If the query has been botched - set it to an empty string.
		$query = '' unless defined $query;

		$json_envelope .= ',' if $first == 0;
		$json_envelope .= '"'.$query_name.'":'.$query;

		$first = 0;
	}
	$json_envelope .= '}';

	print $json_envelope . "\n" if $self->{debug};
	
	# Set up the request depending on whether this is a read or write op.
	$request = HTTP::Request->new;
	$request->header( 'X-Metaweb-Request' => 'True' );
	if ($method eq 'read')  {
		$request->method('GET');
		$request->uri($self->server.$self->{$method.'_uri'}.'?queries='.uri_escape($json_envelope));
	}
	else  {
		$request->method('POST');
		$request->uri($self->server.$self->{$method.'_uri'});
		$request->content_type('application/x-www-form-urlencoded'); 
		$request->content('queries='.uri_escape($json_envelope));
	}
	$response = $self->useragent->request($request);

	$self->{last_envelope_sent} = $method;

	unless ($response->is_success)  {
		$WWW::Metaweb::errstr = "Query failed, HTTP response: " . $response->status_line;
		return undef;
	}
	
	return ($self->set_result($method, $response->content)) ? $response->is_success : undef;
} # ->send_envelope

=back

=head2 Query Convenience Methods (for complicated queries)

As most of the query and result methods require a C<$method> argument as the first parameter, I've included methods to call them for each method explicitly.

If you know that you will always be using a method call for either a read or a write query/result, then it's safer to user these methods as you'll get a compile time error if you spell read or write incorrectly (eg. a typo), rather than a run time error.

Of course it's probably much easier to just use C<read()> and C<write()> from the L<Easy Querying> section above.

=over

=item B<< $mh->add_read_query(query_name1 => $query1 [, query_name2 => $query2 [, ...]]) >>

Convenience method to add a read query. See C<add_query()> for details.

=cut

sub add_read_query  {
	my $self = shift;

	return $self->add_query('read', @_);
} # ->add_read_query

=item B<< $mh->add_write_query(query_name1 => $query1 [, query_name2 => $query2 [, ...]]) >>

Convenience method to add a write query. See C<add_query()> for details.

=cut

sub add_write_query  {
	my $self = shift;

	return $self->add_query('write', @_);
} # ->add_write_query

=item B<< $mh->clear_read_queries >>

Convenience method to clear the read envelope. See C<clear_queries()> for details.

=cut

sub clear_read_queries  {
	my $self = shift;

	return $self->clear_queries('read', @_);
} # ->clear_read_queries

=item B<< $mh->clear_write_queries >>

Convenience method to clear the write envelope. See C<clear_queries()> for details.

=cut

sub clear_write_queries  {
	my $self = shift;

	return $self->clear_queries('write', @_);
} # ->clear_write_queries

=item B<< $count = $mh->read_query_count >>

Convenience method, returns the number of queries in the read envelope. See C<query_count()> for details.

=cut

sub read_query_count  {
	my $self = shift;

	return $self->query_count('read', @_);
} # ->read_query_count

=item B<< $count = $mh->write_query_count >>

Convenience method, returns the number of queries in the write envelope. See C<query_count()> for details.

=cut

sub write_query_count  {
	my $self = shift;

	return $self->query_count('write', @_);
} # ->write_query_count

=item B<< $http_was_successful = $mh->send_read_envelope >>

Convenience method, sends the read envelope. See C<send_envelope()> for details.

=cut

sub send_read_envelope  {
	my $self = shift;

	return $self->send_envelope('read');
} # ->send_read_envelope

=item B<< $http_was_successful = $mh->send_write_envelope >>

Convenience method, sends the write envelope. See C<send_envelope()> for details.

=cut

sub send_write_envelope  {
	my $self = shift;

	return $self->send_envelope('write');
} # ->send_write_envelope

=back

=head2 Result manipulation (for complicated queries)

=over

=item B<< $mh->set_result($json) >>

Sets the result envelope up so that results can be accessed for the latest query. Any previous results are destroyed.

This method is mostly used internally.

=cut

sub set_result  {
	my $self = shift;
	my $method = shift;
	my $json_result = shift;
	my $envelope;

	return undef unless $envelope = __test_envelope($method, 'set_result');
	
	$self->{result_envelope} = $json_result;
	my $perl_result = from_json($json_result);

	my $status = $perl_result->{status};
	unless ($status eq '200 OK')  {
		$WWW::Metaweb::errstr = 'Bad outer envelope status: ' . $status;
		return 0;
	}

	$self->{result_format} = { };
	foreach my $query_name (keys %{$self->{$envelope}})  {
		$self->{result_format}->{$query_name} = (ref $self->{$envelope}->{$query_name}) ? 'perl' : 'json';
	}

	return 1;
} # ->set_result

=item B<< $bool = $mh->result_is_ok($query_name) >>

Returns a boolean result indicating whether the query named C<$query_name> returned a status ok. Returns C<undef> if there is no result for C<query_name>.

=cut

sub result_is_ok  {
	my $self = shift;
	my $query_name = shift || 'netmetawebquery';
	my $result_is_ok = undef;

	my $result = from_json($self->{result_envelope})->{$query_name};	
	if (defined $result)  {
		my ($code, $message);
		$code = $result->{code};
		if ($code eq '/api/status/ok')  {
			$result_is_ok = 1;
		}
		else  {
			$message = $result->{messages}->[0]->{message};
			$WWW::Metaweb::errstr = "Result status not okay for $query_name: $code; error: $message;";
		}

	}
	else  {
		$WWW::Metaweb::errstr = 'No result found for query name: ' . $query_name;
		$result_is_ok = undef;
	}
	
	return $result_is_ok;
} # ->result_is_okay

=item B<< $mh->result($query_name [, $format]) >>

Returns the result of query named C<$query_name> in the format C<$format>, which should be either 'perl' for a Perl structure or 'json' for a JSON string.

if C<$query_name> is not defined then the default query name 'netmetawebquery' will be used instead.

If C<$format> is not specified then the result is returned in the format the original query was supplied.

Following the previous example, we have three separate results stored, so let's get each of them out.

  $result1 = $mh->result('query_perl');
  $result2 = $mh->result('query_json');
  $result3 = $mh->result('query_json_ext', 'perl');

The first two results will be returned in the format their matching queries were submitted in - Perl structure and JSON string respectively - the third will be returned as a Perl structure, as it has been explicitly asked for in that format.

Fetching a result does not effect it, so a result fetched in one format can be later fetched using another.

=cut

sub result  {
	my $self = shift;
	my $query_name = shift || 'netmetawebquery';
	my $format = shift;
	my $result;
	my $raw_result;
	my $perl_result;

	# If the query isn't okay - just return undef, errstr will have been set
	return undef unless $self->result_is_ok($query_name);

	# Check the return format if it hasn't been explicitly set.
	$format = $self->{result_format}->{$query_name} unless defined $format;
	
	$JSON::UnMapping = 1;
	$perl_result = from_json($self->{result_envelope})->{$query_name}->{result};

	if ($format eq 'json')  {
		$result = JSON::XS->new->utf8->pretty($self->{pretty_json})->encode($perl_result);
	}
	else  {
		$result = $perl_result;
	}
	
	return $result;
} # ->result

=item B<< $text = $mh->raw_result >>

Returns the raw result from the last time an envelope was sent.

After a successful query this will most likely be a JSON structure consisting of the outer envelope with the code and status as well as a result for each query sent in the last batch.

After an unsuccessful query this will contain error messages detailing what went wrong as well as code and status sections to similar effect.

If the transaction itself failed then the returned text will probably be empty, but at the very least this method will always return an empty string, never C<undef>.

=cut

sub raw_result  {
	my $self = shift;

	return $self->{result_envelope} || '';
} # ->raw_result

=back

=head2 Accessors

=over

=item B<< $ua = $mh->useragent >> or B<< $mh->useragent($ua) >>

Gets or sets the LWP::UserAgent object which is used to communicate with the Metaweb. This method can be used to change the user agent settings (eg. C<$mh->useragent->timeout($seconds)>).

=cut

sub useragent  {
	my $self = shift;
	my $new_useragent = shift;

	$self->{ua} = $new_useragent if defined $new_useragent;

	return $self->{ua};
} # ->useragent

=item B<< $host = $mh->server >> or B<< $mh->server($new_host) >>

Gets or sets the host for this Metaweb (eg. www.freebase.com). No checking is currently done as to the validity of this host.

=cut

sub server  {
	my $self = shift;
	my $new_server = shift;
	
	$self->{server} = $new_server if defined $new_server;
	$self->{server} = 'http://'.$self->{server} unless $self->{server} =~ /^http:\/\//;

	return $self->{server};
} # ->server

=back

=head1 BUGS AND TODO

Still very much in development. I'm waiting to hear from you.

There is not query syntax checking - the method exists, but doesn't actually do anything.

If authentication fails not much notice is given.

More information needs to be given when a query fails.

I would like to implement transparent cursors in read queries so a single query can fetch as many results as exist (rather than the standard 100 limit).

=head1 ACKNOWLEDGEMENTS

While entirely rewritten, I think it's only fair to mention that the basis for the core of this code is the Perl example on Freebase (http://www.freebase.com/view/helptopic?id=%239202a8c04000641f800000000544e139).

Michael Jones has also been a great help - pointing out implementation issues and providing suggested fixes and code.

=head1 SEE ALSO

Freebase, Metaweb

=head1 AUTHORS

Hayden Stainsby E<lt>hds@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Hayden Stainsby

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

################################################################################
# Below here are private functions - so no POD for here.

# __test_envelope
# Tests that an envelope is either 'read' or 'write'. If it is, '_envelope' is
# appended and returned. If not, undef is returned and an error message is set.
sub __test_envelope  {
	my $envelope = shift;
	my $method = shift;

	if ($envelope eq 'read' || $envelope eq 'write')  {
		$envelope .= '_envelope';
	}
	else  {
		$WWW::Metaweb::errstr = "Envelope must have a value of 'read' or 'write' in $method()";
		$envelope = undef;
	}

	return $envelope;
} # &__test_envelope

return 1;
__END__


