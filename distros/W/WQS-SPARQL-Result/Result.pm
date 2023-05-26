package WQS::SPARQL::Result;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use URI;

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub result {
	my ($self, $result_hr, $vars_ar) = @_;

	if (! defined $vars_ar) {
		$vars_ar = $result_hr->{'head'}->{'vars'};
	}

	my @res;
	if (exists $result_hr->{'results'}->{'bindings'}) {
		my @items = @{$result_hr->{'results'}->{'bindings'}};
		foreach my $item_hr (@items) {
			my $result_hr;
			foreach my $var (@{$vars_ar}) {

				# TODO Implement other values

				# QID.
				# TODO Check real QID, could be another uri.
				if ($item_hr->{$var}->{'type'} eq 'uri') {
					my $qid_uri = URI->new($item_hr->{$var}->{'value'});
					my @segs = $qid_uri->path_segments;
					$result_hr->{$var} = $segs[-1];
				}
			}
			push @res, $result_hr;
		}
	}

	return @res;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WQS::SPARQL::Result - Processing Wikidata Query Service SPARQL result.

=head1 SYNOPSIS

 use WQS::SPARQL::Result;

 my $obj = WQS::SPARQL::Result->new;
 my @res = $obj->result($result_hr, $vars_ar);

=head1 DESCRIPTION

Class which gets structure which is originally JSON result from Wikidata Query
Service and parse values from it.

=head1 METHODS

=head2 C<new>

 my $obj = WQS::SPARQL::Result->new;

Constructor.

Returns instance of class.

=head2 C<result>

 my @res = $obj->result($result_hr, $vars_ar);

Select variables from structures and return list.

Variables:

 C<$result_hr> - Structure converted from JSON string.
 C<$vars_ar> - Reference to array with keys, which we need to return.

Returns list of structures with key => value pairs.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<URI>.

=head1 SEE ALSO

=over

=item L<WQS::SPARQL::Query::Count>

Simple SPARQL count query.

=item L<WQS::SPARQL::Query::Select>

Simple SPARQL select query.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WQS-SPARQL-Result>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2023

BSD 2-Clause License

=head1 VERSION

0.01

=cut
