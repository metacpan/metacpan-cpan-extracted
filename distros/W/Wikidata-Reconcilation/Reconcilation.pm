package Wikidata::Reconcilation;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use LWP::UserAgent;
use Unicode::UTF8 qw(encode_utf8);
use WQS::SPARQL;
use WQS::SPARQL::Result;

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# User agent.
	$self->{'agent'} = __PACKAGE__." ($VERSION)";

	# First match mode.
	$self->{'first_match'} = 0;

	# Language.
	$self->{'language'} = 'en';

	# LWP::UserAgent object.
	$self->{'lwp_user_agent'} = undef;

	# Verbose mode.
	$self->{'verbose'} = 0;

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

	$self->{'_q'} = WQS::SPARQL->new(
		'lwp_user_agent' => $self->{'lwp_user_agent'},
	);

	return $self;
}

sub reconcile {
	my ($self, $reconcilation_rules_hr) = @_;

	my @sparql = $self->_reconcile($reconcilation_rules_hr);

	my $ret_hr;
	my %qids;
	if ($self->{'verbose'}) {
		print "SPARQL queries:\n";
	}
	foreach my $sparql (@sparql) {
		if ($self->{'verbose'}) {
			print encode_utf8($sparql)."\n";
		}

		$ret_hr = $self->{'_q'}->query($sparql);
		my @ret = map { $_->{'item'} } WQS::SPARQL::Result->new(
			'verbose' => $self->{'verbose'},
		)->result($ret_hr);
		foreach my $ret (@ret) {
			$qids{$ret}++;
		}
		if (@ret && $self->{'first_match'}) {
			last;
		}
	}
	if ($self->{'verbose'}) {
		print "Results:\n";
		foreach my $item (sort keys %qids) {
			print '- '.$item.': '.$qids{$item}."\n";
		}
	}

	return sort keys %qids;
}

sub _reconcile {
	my ($self, $reconcilation_rules_hr) = @_;

	err "This is abstract class. You need to implement _reconcile() method.";
	my @sparql;

	return @sparql;
}

sub _exists_id {
	my ($self, $reconcilation_rules_hr, $id) = @_;

	if (exists $reconcilation_rules_hr->{'identifiers'}->{$id}
		&& defined $reconcilation_rules_hr->{'identifiers'}->{$id}) {

		return 1;
	} else {
		return 0;
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikidata::Reconcilation - Abstract class for Wikidata reconcilations.

=head1 SYNOPSIS

 use Wikidata::Reconcilation;

 my $obj = Wikidata::Reconcilation->new;
 my @qids = $obj->reconcile($reconcilation_rules_hr);

=head1 DESCRIPTION

Abstract class for Wikidata reconcilation.
Method, which need to implement: C<_reconcile()>.

=head1 METHODS

=head2 C<new>

 my $obj = Wikidata::Reconcilation->new;

Constructor.

Returns instance of object.

=head2 C<reconcile>

 my @qids = $obj->reconcile($reconcilation_rules_hr);

Reconcile information defined in input structure and returns list of QIDs.

Returns list of strings.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'lwp_user_agent' must be a 'LWP::UserAgent' instance.

 reconcile():
         This is abstract class. You need to implement _reconcile() method.


=head1 EXAMPLE

=for comment filename=simple_reconcile.pl

 use strict;
 use warnings;

 package Foo;

 use base qw(Wikidata::Reconcilation);

 use WQS::SPARQL;
 use WQS::SPARQL::Query::Select;

 sub _reconcile {
         my ($self, $reconcilation_rules_hr) = @_;
 
         # Reconcilation process.
         my @sparql;
         if (exists $reconcilation_rules_hr->{'identifiers'}->{'given_name_qids'}
                 && exists $reconcilation_rules_hr->{'identifiers'}->{'surname_qid'}) {

                 my $sparql = <<'END';
 SELECT ?item WHERE {
   ?item wdt:P31 wd:Q5.
 END
                 foreach my $given_name_qid (@{$reconcilation_rules_hr->{'identifiers'}->{'given_name_qids'}}) {
                         $sparql .= '  ?item wdt:P735 wd:'.$given_name_qid.".\n";
                 }
                 $sparql .= '  ?item wdt:P734 wd:'.
                         $reconcilation_rules_hr->{'identifiers'}->{'surname_qid'}.".\n";
                 $sparql .= "}\n";
                 push @sparql, $sparql;
         } elsif (exists $reconcilation_rules_hr->{'identifiers'}->{'surname_qid'}) {
                 push @sparql, WQS::SPARQL::Query::Select->new->select_value({
                         'P31' => 'Q5',
                         'P734' => $reconcilation_rules_hr->{'identifiers'}->{'surname_qid'},
                 });
         }

         return @sparql;
 }

 package main;

 # Object.
 my $obj = Foo->new('verbose' => 1);

 # Save cached value.
 my @qids = $obj->reconcile({
         'identifiers' => {
                  'given_name_qids' => ['Q18563993', 'Q15730712'], # 'Michal', 'Josef'
                  'surname_qid' => 'Q16883641', # 'Špaček'
         },
 });

 # Output is defined by 'verbose' => 1

 # Output like:
 # SPARQL queries:
 # SELECT ?item WHERE {
 #   ?item wdt:P31 wd:Q5.
 #   ?item wdt:P735 wd:Q18563993.
 #   ?item wdt:P735 wd:Q15730712.
 #   ?item wdt:P734 wd:Q16883641.
 # }
 # 
 # {
 #     head      {
 #         vars   [
 #             [0] "item"
 #         ]
 #     },
 #     results   {
 #         bindings   [
 #             [0] {
 #                     item   {
 #                         type    "uri",
 #                         value   "http://www.wikidata.org/entity/Q27954834"
 #                     }
 #                 }
 #         ]
 #     }
 # }
 # Results:
 # - Q27954834: 1

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<LWP::UserAgent>,
L<Unicode::UTF8>,
L<WQS::SPARQL>,
L<WQS::SPARQL::Result>.

=head1 SEE ALSO

=over

=item L<Wikidata::Reconcilation::Periodical>

Wikidata reconcilation class for periodical.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Reconcilation>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
