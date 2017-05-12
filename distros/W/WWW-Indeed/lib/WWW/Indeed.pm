package WWW::Indeed;

use strict;
use warnings;
use POSIX qw(ceil);
use LWP::UserAgent;
use XML::Simple qw(XMLin);

our $VERSION = '0.01';

=head1 NAME

WWW::Indeed - Perl interface to the Indeed.com web service

=head1 SYNOPSIS

  use WWW::Indeed;

  my $indeed = WWW::Indeed->new(api_key => 'YOUR API KEY HERE');

  my @postings = $indeed->get_postings(
      'Project Manager',
      location => 'New York, NY',
      sort     => 'date',
      limit    => 25,
      days     => 14,
      filter   => 1,
  );

  for my $posting (@postings) {
      print "$posting->{title} at $posting->{company} - $posting->{url}\n";
  }

  print "Used " . $indeed->api_calls_used . " API calls";

=head1 DESCRIPTION

This module provides an object-oriented Perl interface to the Indeed.com web service.

=head1 METHODS

=cut

sub new
{
    my $class  = shift;
    my %params = @_;
    my $self   = \%params;
    $self->{api_calls_used} = 0;
    bless $self, $class;
    return $self;
}

=head2 $self->get_postings('Project Manager', limit => 10)

Given a query, returns job posting that match that query.

Along with the query, takes the following parameters as a hash:

=over 4

=item * B<limit>

The number of postings that will be returned. Please note that the Indeed API 
has a built-in limit of 20 postings per request, so requests for more than 20
will result in multiple API calls.

Defaults to 20.

=item * B<location>

The location where the job postings should be located. Use a postal/ZIP code or
a city and state for best results.

=item * B<sort>

What the results should be sorted by - one of 'relevance' or 'date'.

Defaults to 'date'.

=item * B<offset>

The offset to begin searching from in the results. Chances are, you won't need
to use this parameter.

=item * B<days>

The limit (in days) on the age of postings. Must be no greater than 30.

Defaults to 30.

=item * B<filter>

Whether or not to filter out duplicate postings.

Defaults to 0.

=back

=cut 

sub get_postings
{
    my ($self, $query, %params) = @_;

    my @nice_postings;
    my $offset = 0;

    my %query = (
        key     => $self->{api_key}  || '',
        q       => $query            || '',
        l       => $params{location} || '',
        sort    => $params{sort}     || 'date',
        start   => $offset,
        limit   => $params{limit}    || 20,

        # surprisingly, this has nothing to do with cheese - it's the "from
        # age" in days
        fromage => $params{days}     || 30,

        filter  => $params{filter}   || 1,
    );

    my $xml = $self->api_call(%query);
    # Indeed has a limit of 20 postings returned per query, so if a limit over
    # 20 is requested, we need to iterate through and make a new request until
    # we've hit the specified amount.
    my $limit            = $params{limit} || 20;
    my $num_queries      = 1;
    my $last_query_limit = $limit;
    if ($limit and $limit > 20)
    {
        my $max_results = $xml->{totalresults};
        $limit = $max_results if $limit > $max_results;

        $num_queries = ceil($limit / 20);

        # The number won't always be divisible by 20. For example, if the user
        # requests 42 results, we need to make two 20-result requests and one
        # 2-result request.
        $last_query_limit -= 20 until $last_query_limit <= 20;

        $limit = 20;
    }

    for my $i (1..$num_queries)
    {
        my $this_limit = $limit;
        $limit = $last_query_limit if ($i == $num_queries);

        my $xml = $self->api_call(%query);

        $offset += 20;
        $query{start} = $offset;

        die $xml->{error} if $xml->{error};

        my $results = [];
        if ($xml->{results})
        {
            my $result = $xml->{results}{result};
            # the result can be an array or hash reference. kinda nasty.
            $results = $result   if (ref($result) eq 'ARRAY');
            $results = [$result] if (ref($result) eq 'HASH');
        }

        last unless @$results;
        for my $posting (@$results)
        {
            push @nice_postings, {
                title     => $posting->{jobtitle} || '',
                company   => $posting->{company}  || '',
                city      => $posting->{city}     || '',
                state     => $posting->{state}    || '',
                country   => $posting->{country}  || '',
                source    => $posting->{source}   || '',
                date      => $posting->{date}     || '',
                snippet   => $posting->{snippet}  || '',
                url       => $posting->{url}      || '',
                latitude  => $posting->{latitude} || '',
                longitude => $posting->{longitude} || '',
            };
        }
    }

    return @nice_postings;
}

=head2 $self->api_calls_used

Returns the number of API calls used for this particular object.

=cut

sub api_calls_used
{
    my $self = shift;
    return $self->{api_calls_used} || 0;
}

=head2 $self->api_call(param1 => 'foo', param2 => 'bar')

Submits an API call to the Indeed API using the passed paramters, parses the
response, and returns it as a Perl data structure. It shouldn't be necessary to
use this method directly.

=cut

sub api_call
{
    my $self       = shift;
    my %params     = @_;
    my @uri_params = map("$_=$params{$_}", keys %params);
    my $uri        = "http://api.indeed.com/apisearch?" . join('&', @uri_params);
    my $agent      = LWP::UserAgent->new;
    my $response   = $agent->get($uri);
    if ($response->is_success)
    {
        my $xml = {};
        eval { $xml = XMLin($response->content) };
        $self->{api_calls_used}++;
        return $xml;
    }
    else
    {
        die "Can't retrieve data from the Indeed API: " .
            $response->status_line;
    }
}

=head1 DEPENDENCIES

LWP::UserAgent, XML::Simple

=head1 BUGS

In cases where the specified limit is above Indeed's maximum, one API call is used solely to determine the number of records available in the search. This should be optimized.

=head1 DISCLAIMER

The author of this module is not affiliated in any way with Indeed.com. Users must follow the Indeed.com API TOS (see http://www.indeed.com) when using this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 Michael Aquilina. All rights reserved.

This code is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Michael Aquilina, aquilina@cpan.org

=cut

1;
