package WebService::YQL;

use strict;
use warnings;

use URI;
use URI::QueryParam;
use LWP::UserAgent;
use JSON::Any;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.04';
}

=head1 NAME

WebService::YQL - Simple interface for Yahoo Query Language

=head1 SYNOPSIS

  use WebService::YQL;
  
  my $yql = WebService::YQL->new;

  my $data = $yql->query("select * from search.web where query = 'YQL'");
  for my $result ( @{ $data->{'query'}{'results'}{'result'} } ) {
      print $result->{'title'}, "\n";
      print $result->{'abstract'}, "\n";
      print '* ', $result->{'url'}, "\n\n";
  }

=head1 DESCRIPTION

This is a simple wrapper to the Yahoo Query Language service. Instead of 
manually sending a GET request to Yahoo and getting XML or JSON you can 
now use a simple function call and get a deep Perl data structure.

=head1 USAGE

  my $data = $yql->query("select * from table");

=head1 FUNCTIONS

=head2 new

New instance of WebService::YQL. Accepts one argument, 'env', to load more data tables,
e.g. WebService::YQL->new(env => 'http://datatables.org/alltables.env');

=cut

sub new {
    my ($class, %params) = @_;

    my $self = bless ({}, ref ($class) || $class);

    $self->{'_base_url'} = URI->new('http://query.yahooapis.com/v1/public/yql');
    $self->{'_env'} = $params{'env'}; # || 'http://datatables.org/alltables.env';
    # $self->{'_other_query_args'} = ...

    # Instantiate helper objects
    $self->{'_ua'} = LWP::UserAgent->new;
    $self->{'_json'} = JSON::Any->new;

    return $self;
}

=head2 query

Run an YQL query. Accepts one argument, the query as a string.

=cut

sub query {
    my ($self, $query) = @_;
    die "You must specify a yql statement to execute" unless defined $query;

    my $url = $self->_base_url;
    $url->query_form( q => $query );

    my $response = $self->_request($url);
    my $decoded = $self->{'_json'}->decode($response);

    return $decoded;
}

=head2 useragent

Returns the LWP::UserAgent object used to contact yahoo. You can tweak that 
object as required, e.g. $yql->useragent->env_proxy in order to use the proxy 
set in environment.

=cut

sub useragent {
    my ($self) = @_;
    return $self->{'_ua'};
}

sub _request {
    my ($self, $url) = @_;

    $url->query_param( format   => 'json' );
    $url->query_param( env      => $self->{'_env'} ) if $self->{'_env'};

    # XXX POST for insert/update/delete ?
    my $req = HTTP::Request->new(GET => $url);
    my $res = $self->{'_ua'}->request($req);

    # Check the outcome of the response
    if ($res->is_success) {
        return $res->content;
    }
    else {
        warn "$url status ".$res->status_line;
        return undef;
    }
}

sub _base_url {
    my ($self) = @_;
    return $self->{'_base_url'}->clone;
}

=head1 BUGS

As any software, it has bugs, but I'm hunting them down.

=head1 SUPPORT

Check the source code or contact author for support.

=head1 AUTHOR

Viorel Stirbu
CPAN ID: VIORELS
http://stirbu.name

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

http://developer.yahoo.com/yql
http://developer.yahoo.com/yql/console

=cut

1;
# The preceding line will help the module return a true value

