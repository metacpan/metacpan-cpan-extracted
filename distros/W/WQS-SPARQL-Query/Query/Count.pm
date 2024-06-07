package WQS::SPARQL::Query::Count;

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

sub count_item {
	my ($self, $property, $item) = @_;

	if ($property !~ m/^P\d+$/ms) {
		err "Bad property '$property'.";
	}
	if ($item !~ m/^Q\d+$/ms) {
		err "Bad item '$item'.";
	}

	my $sparql = <<"END";
SELECT (COUNT(?item) as ?count) WHERE {
  ?item wdt:$property wd:$item
}
END

	return $sparql;
}

sub count_value {
	my ($self, $property, $value) = @_;

	if ($property !~ m/^P\d+$/ms) {
		err "Bad property '$property'.";
	}

	$value =~ s/'/\\'/msg;
	my $sparql = <<"END";
SELECT (COUNT(?item) as ?count) WHERE {
  ?item wdt:$property '$value'
}
END

	return $sparql;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WQS::SPARQL::Query::Count - Simple SPARQL count query.

=head1 SYNOPSIS

 use WQS::SPARQL::Query::Count;

 my $obj = WQS::SPARQL::Query::Count->new;
 my $sparql = $obj->count_item($property, $item);
 my $sparql = $obj->count_value($property, $value);

=head1 METHODS

=head2 C<new>

 my $obj = WQS::SPARQL::Query::Count->new;

Constructor.

Returns instance of class.

=head2 C<count_item>

 my $sparql = $obj->count_item($property, $item);

Construct SPARQL command and return it.

Returns string.

=head2 C<count_value>

 my $sparql = $obj->count_value($property, $value);

Construct SPARQL command and return it.

Returns string.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 count_item():
         Bad item '%s'.
         Bad property '%s'.

 count_value():
         Bad property '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use WQS::SPARQL::Query::Count;

 my $obj = WQS::SPARQL::Query::Count->new;

 my $property = 'P957';
 my $item = 'Q62098524';
 my $sparql = $obj->count_item($property, $item);

 print "Property: $property\n";
 print "Item: $item\n";
 print "SPARQL:\n";
 print $sparql;

 # Output:
 # Property: P957
 # ISBN: 80-239-7791-1
 # SPARQL:
 # SELECT (COUNT(?item) as ?count) WHERE {
 #   ?item wdt:P957 wd:Q62098524
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use WQS::SPARQL::Query::Count;

 my $obj = WQS::SPARQL::Query::Count->new;

 my $property = 'P957';
 my $isbn = '80-239-7791-1';
 my $sparql = $obj->count_value($property, $isbn);

 print "Property: $property\n";
 print "ISBN: $isbn\n";
 print "SPARQL:\n";
 print $sparql;

 # Output:
 # Property: P957
 # ISBN: 80-239-7791-1
 # SPARQL:
 # SELECT (COUNT(?item) as ?count) WHERE {
 #   ?item wdt:P957 '80-239-7791-1'
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<WQS::SPARQL::Query>

Useful Wikdata Query Service SPARQL queries.

=item L<WQS::SPARQL::Query::Select>

Simple SPARQL select query.

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
