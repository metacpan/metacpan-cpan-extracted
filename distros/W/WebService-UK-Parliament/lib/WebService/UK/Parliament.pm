package WebService::UK::Parliament;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.00';

use Mojo::Base -base;
use Module::Load qw/load/;

has instantiate => sub{ [qw/Bills CommonsVotes ErskineMay LordsVotes Members Now OralQuestions StatutoryInstruments Treaties WrittenQuestions/] };
has private => 0;

has instantiated => sub { {} };

sub new {
	my $class = shift;
	my $self = bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
	for my $instant (@{ $self->instantiate }) {
		my $class = sprintf "WebService::UK::Parliament::%s", $instant;
		load $class;
		$self->instantiated->{$instant} = $class->new( private => $self->private );
	}
	return $self;
}

sub AUTOLOAD {
	my ($self) = shift;
	my $classname =  ref $self;
        my $validname = '[a-zA-Z][a-zA-Z0-9_]*';
        our $AUTOLOAD =~ /^${classname}::($validname)$/;
	my $key = $1;
        die "illegal key name, must be of $validname form\n$AUTOLOAD" unless $key;
	return $self->instantiated->{ucfirst($key)};
}

1;

__END__

=head1 NAME

WebService::UK::Parliament - Query the UK Parliament API

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament;

	my $factory = WebService::UK::Parliament->new();

	my $members = $factory->members();

	my $local = $members->getLocationConstituencySearch({
		searchText => $j_corbyn,
		take => 326,
	});
		
	... # independence

=head1 DESCRIPTION

Query the UK Parliament API via their OpenAPI definition. 

See L<https://developer.parliament.uk/> for the full documentation.

They have no operationId so they're generated using the method + path minus params and slashes, as an example /api/Location/Constituency/{id} becomes getLocationConstituency.

=head1 METHODS

=head2 bills

An API which retrieves Members data.

	$factory->bills;

=cut

=head2 commonsVotes

An API that allows querying of Commons Votes data.

	$factory->commonsVotes;

=cut

=head2 erskinMay

An API that allows querying of Erskine May data.

	$factory->erskinMay;

=cut
	
=head2 lordsVotes

An API that allows querying of Lords Votes data.

	$factory->lordsVotes;

=cut

=head2 members

An API which retrieves Members data.

	$factory->members;

=cut

=head2 now

Get data from the annunciator system.

	$factory->now;

=cut

=head2 oralQuestions

An API that allows querying all tabled oral and written questions, and motions for the House of Commons.

	$factory->oralQuestions;

=cut

=head2 statutoryInstruments

An API exposing details of the various types of Statutory Instruments laid before Parliament.

	$factory->statutoryInstruments;

=cut

=head2 treaties

An API exposing details of the treaties laid before Parliament.

	$factory->treaties;

=cut

=head2 writtenQuestions

Data around written questions and answers, as well as written ministerial statements.

	$factory->writtenQuestions;

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-uk-parliament at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-UK-Parliament>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::UK::Parliament


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-UK-Parliament>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WebService-UK-Parliament>

=item * Search CPAN

L<https://metacpan.org/release/WebService-UK-Parliament>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

The first ticehurst bathroom experience

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of WebService::UK::Parliament
