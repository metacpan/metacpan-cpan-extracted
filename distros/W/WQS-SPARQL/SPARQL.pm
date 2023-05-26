package WQS::SPARQL;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;
use URI;
use URI::QueryParam;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# User agent.
	$self->{'agent'} = __PACKAGE__." ($VERSION)";

	# LWP::UserAgent object.
	$self->{'lwp_user_agent'} = undef;

	# Query site.
	$self->{'query_site'} = 'query.wikidata.org';

	# SPARQL endpoint.
	$self->{'sparql_endpoint'} = '/bigdata/namespace/wdq/sparql';

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'lwp_user_agent'}) {
		$self->{'lwp_user_agent'} = LWP::UserAgent->new(
			'agent' => $self->{'agent'},
		);
	} else {
		if (! $self->{'lwp_user_agent'}->isa('LWP::UserAgent')) {
			err "Parameter 'lwp_user_agent' must be a 'LWP::UserAgent' instance.";
		}
	}

	# Full URL of api.
	$self->{'_api_uri'} = 'https://'.$self->{'query_site'}.$self->{'sparql_endpoint'};

	return $self;
}

sub query {
	my ($self, $query) = @_;

	my $uri = URI->new($self->{'_api_uri'});
	$uri->query_param_append('format' => 'json');
	$uri->query_param_append('query' => $query);

	return $self->_http_get_json($uri->as_string);
}

sub query_count {
	my ($self, $query) = @_;

	my $ret_hr = $self->query($query);

	return $ret_hr->{'results'}->{'bindings'}->[0]->{'count'}->{'value'};
}

sub _http_get_json {
	my ($self, $uri) = @_;

	my $res = $self->{'lwp_user_agent'}->get($uri);
	if ($res->is_success) {
		my $content = decode_json($res->decoded_content);
		return wantarray ? ($content, $res->headers) : $content;
	} else {
		err 'Cannot get.',
			'Error', $res->status_line,
			'URI', $uri;
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WQS::SPARQL - Simple SPARQL query for Wikidata Query Service.

=head1 SYNOPSIS

 use WQS::SPARQL;

 my $obj = WQS::SPARQL->new;
 my $ret_hr = $obj->query($sparql);
 my $count = $obj->query_count($sparql_count);

=head1 METHODS

=head2 C<new>

 my $obj = WQS::SPARQL->new;

Constructor.

Returns instance of class.

=head2 C<query>

 my $ret_hr = $obj->query($sparql);

Do SPARQL query and returns result.

Returns reference to hash with result.

=head2 C<query_count>

 my $count = $obj->query_count($sparql_count);

Get count value for C<$sparql_count> SPARQL query.

Returns number.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'lwp_user_agent' must be a 'LWP::UserAgent' instance.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use WQS::SPARQL;
 use WQS::SPARQL::Query::Count;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 ccnb\n";
         exit 1;
 }
 my $ccnb = $ARGV[0];

 my $q = WQS::SPARQL->new;
 my $sparql = WQS::SPARQL::Query::Count->new->count_simple('P3184',
         $ccnb);
 my $ret_hr = $q->query($sparql);

 # Dump structure to output.
 p $ret_hr;
 
 # Output for cnb002826100:
 # \ {
 #     head      {
 #         vars   [
 #             [0] "count"
 #         ]
 #     },
 #     results   {
 #         bindings   [
 #             [0] {
 #                 count   {
 #                     datatype   "http://www.w3.org/2001/XMLSchema#integer",
 #                     type       "literal",
 #                     value      1
 #                 }
 #             }
 #         ]
 #     }
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use WQS::SPARQL;
 use WQS::SPARQL::Query::Count;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 ccnb\n";
         exit 1;
 }
 my $ccnb = $ARGV[0];

 my $q = WQS::SPARQL->new;
 my $sparql = WQS::SPARQL::Query::Count->new->count_simple('P3184',
         $ccnb);
 my $ret = $q->query_count($sparql);

 # Print count.
 print "Count: $ret\n";
 
 # Output for 'cnb002826100':
 # Count: 1

 # Output for 'bad':
 # Count: 0

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>.
L<HTTP::Request>,
L<JSON::XS>,
L<LWP::UserAgent>,
L<URI>,
L<URI::QueryParam>.

=head1 SEE ALSO

=over

=item L<WQS::SPARQL::Query>

Usefull Wikdata Query Service SPARQL queries.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WQS-SPARQL>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2023

BSD 2-Clause License

=head1 VERSION

0.01

=cut
