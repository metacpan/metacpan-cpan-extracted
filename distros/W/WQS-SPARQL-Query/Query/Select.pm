package WQS::SPARQL::Query::Select;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);

our $VERSION = 0.03;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub select_value {
	my ($self, $property_pairs_hr, $filter_ar) = @_;

	my %sort;
	foreach my $property (keys %{$property_pairs_hr}) {
		if ($property !~ m/^P(\d+)(\/P\d+\*?)?$/ms) {
			err "Bad property '$property'.";
		}
		$sort{$property} = $1;
	}

	my $sparql = "SELECT ?item WHERE {\n";
	foreach my $property (sort { $sort{$a} <=> $sort{$b} } keys %{$property_pairs_hr}) {
		my $property_wdt = $self->_property($property);

		my $value = $property_pairs_hr->{$property};
		if ($value =~ m/^Q\d+$/ms) {
			$value = "wd:$value";
		} elsif ($value =~ m/^\?/ms) {
			# same
		} elsif ($value =~ m/^(.*?)(@\w\w)$/ms) {
			my ($main_value, $lang) = ($1, $2);
			$main_value =~ s/'/\\'/msg;
			$value = "'$main_value'$lang";
		} else {
			$value =~ s/'/\\'/msg;
			$value = "'$value'";
		}

		$sparql .= "  ?item $property_wdt $value.\n"
	}
	foreach my $filter_item_ar (@{$filter_ar}) {
		$sparql .= '  FILTER('.$filter_item_ar->[0].' '.$filter_item_ar->[1].' '.$filter_item_ar->[2].')'."\n";
	}
	$sparql .= "}\n";

	return $sparql;
}

sub _property {
	my ($self, $property_key) = @_;

	my $property_wdt;
	if ($property_key =~ m/^P\d+$/ms) {
		$property_wdt = 'wdt:'.$property_key;
	} else {
		my ($p1, $p2) = ($property_key =~ m/^(P\d+)\/(P\d+\*?)$/ms);
		$property_wdt = 'wdt:'.$p1.'/wdt:'.$p2;
	}

	return $property_wdt;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WQS::SPARQL::Query::Select - Simple SPARQL select query.

=head1 SYNOPSIS

 use WQS::SPARQL::Query::Select;

 my $obj = WQS::SPARQL::Query::Select->new;
 my $sparql = $obj->select_value($property_pairs_hr);

=head1 METHODS

=head2 C<new>

 my $obj = WQS::SPARQL::Query::Select->new;

Constructor.

Returns instance of class.

=head2 C<select_value>

 my $sparql = $obj->select_value($property_pairs_hr);

Construct SPARQL command and return it.
Input is reference to hash with pairs property => value.

Value could be in forms:

=over

=item * Q__number__

QID identifier.

Example output: Q42

=item * __string__@__lang__

String with language.

'lang' is 2 character language code.

Example output: 'string'@en

=item * __string__

String without language.

Example output: 'string'

=back

Returns string.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 select_value():
         Bad property '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use WQS::SPARQL::Query::Select;

 my $obj = WQS::SPARQL::Query::Select->new;

 my $property = 'P957';
 my $isbn = '80-239-7791-1';
 my $sparql = $obj->select_value({$property => $isbn});

 print "Property: $property\n";
 print "ISBN: $isbn\n";
 print "SPARQL:\n";
 print $sparql;

 # Output:
 # Property: P957
 # ISBN: 80-239-7791-1
 # SPARQL:
 # SELECT ?item WHERE {
 #   ?item wdt:P957 '80-239-7791-1'.
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<WQS::SPARQL::Query>

Useful Wikdata Query Service SPARQL queries.

=item L<WQS::SPARQL::Query::Count>

Simple SPARQL count query.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WQS-SPARQL-Query>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
