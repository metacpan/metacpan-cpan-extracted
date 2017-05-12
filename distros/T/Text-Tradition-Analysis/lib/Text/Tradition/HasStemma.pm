package Text::Tradition::HasStemma;

use strict;
use warnings;
use Moose::Role;
use Date::Parse;
use Text::Tradition::Stemma;

=head1 NAME

Text::Tradition::HasStemma - add-on to associate stemma hypotheses to
Text::Tradition objects

=head1 DESCRIPTION

It is often the case that, for a given text tradition, the order of copying
of the witnesses can or should be reconstructed (or at least the attempt
should be made.) This class is a role that can be applied to
Text::Tradition objects to record stemma hypotheses.  See the documentation
for L<Text::Tradition::Stemma> for more information.

=head1 METHODS

=head2 stemmata

Return a list of all stemmata associated with the tradition.

=head2 stemma_count

Return the number of stemma hypotheses defined for this tradition.

=head2 stemma( $idx )

Return the L<Text::Tradition::Stemma> object identified by the given index.

=head2 clear_stemmata

Delete all stemma hypotheses associated with this tradition.

=head2 has_stemweb_jobid

Returns true if there is currently a Stemweb job ID, indicating that a
stemma tree calculation from the Stemweb service is in process.

=head2 stemweb_jobid

Return the currently-running job ID (if any) for calculation of Stemweb 
trees.

=head2 set_stemweb_jobid( $jobid )

Record a job ID for a Stemweb calculation.

=cut

has 'stemmata' => (
	traits => ['Array'],
	isa => 'ArrayRef[Text::Tradition::Stemma]',
	handles => {
		stemmata => 'elements',
		_add_stemma => 'push',
		stemma => 'get',
		stemma_count => 'count',
		clear_stemmata => 'clear',
	},
	default => sub { [] },
	);
  
has 'stemweb_jobid' => (
	is => 'ro',
	isa => 'Str',
	writer => 'set_stemweb_jobid',
	predicate => 'has_stemweb_jobid',
	clearer => '_clear_stemweb_jobid',
	);
	
before 'set_stemweb_jobid' => sub {
	my( $self ) = shift;
	if( $self->has_stemweb_jobid ) {
		$self->throw( "Tradition already has a Stemweb jobid: "
			. $self->stemweb_jobid );
	}
};

=head2 add_stemma( dotfile => $dotfile )
=head2 add_stemma( dot => $dotstring )
=head2 add_stemma( $stemma_obj )

Initializes a Text::Tradition::Stemma object from the given dotfile,
and associates it with the tradition.

=begin testing

use Text::Tradition;

my $t = Text::Tradition->new( 
    'name'  => 'simple test', 
    'input' => 'Tabular',
    'file'  => 't/data/simple.txt',
    );
is( $t->stemma_count, 0, "No stemmas added yet" );
my $s;
ok( $s = $t->add_stemma( dotfile => 't/data/simple.dot' ), "Added a simple stemma" );
is( ref( $s ), 'Text::Tradition::Stemma', "Got a stemma object returned" );
is( $t->stemma_count, 1, "Tradition claims to have a stemma" );
is( $t->stemma(0), $s, "Tradition hands back the right stemma" );

=end testing

=cut

sub add_stemma {
	my $self = shift;
	my $stemma;
	if( ref( @_ ) eq 'Text::Tradition::Stemma' ) {
		$stemma = shift;
	} else {
		$stemma = Text::Tradition::Stemma->new( @_ );
	}
	$self->_add_stemma( $stemma ) if $stemma;
	return $stemma;
}

=head2 record_stemweb_result( $format, $data )

Records the result returned by a Stemweb calculation, and clears any
existing job ID. Returns any new stemmata that were created.

=begin testing

use Text::Tradition;
use JSON qw/ from_json /;

my $t = Text::Tradition->new( 
    'name'  => 'Stemweb test', 
    'input' => 'Self',
    'file'  => 't/data/besoin.xml',
    'stemweb_jobid' => '4',
    );

is( $t->stemma_count, 0, "No stemmas added yet" );

my $answer = from_json( '{"status": 0, "job_id": "4", "algorithm": "RHM", "format": "newick", "start_time": "2013-10-26 10:44:14.050263", "result": "((((((((((((_A_F,_A_U),_A_V),_A_S),_A_T1),_A_T2),_A_A),_A_J),_A_B),_A_L),_A_D),_A_M),_A_C);\n", "end_time": "2013-10-26 10:45:55.398944"}' );
my $newst = $t->record_stemweb_result( $answer );
is( scalar @$newst, 1, "New stemma was returned from record_stemweb_result" );
is( $newst->[0], $t->stemma(0), "Answer has the right object" );
ok( !$t->has_stemweb_jobid, "Job ID was removed from tradition" );
is( $t->stemma_count, 1, "Tradition has new stemma" );
ok( $t->stemma(0)->is_undirected, "New stemma is undirected as it should be" );
is( $t->stemma(0)->identifier, "RHM 1382784254_0", "Stemma has correct identifier" );
is( $t->stemma(0)->from_jobid, 4, "New stemma has correct associated job ID" );
foreach my $wit ( $t->stemma(0)->witnesses ) {
	ok( $t->has_witness( $wit ), "Extant stemma witness $wit exists in tradition" );
}

=end testing

=cut

sub record_stemweb_result {
	my( $self, $answer ) = @_;
	my $jobid = $self->stemweb_jobid;
	my $stemmata = [];
	if( $answer->{format} eq 'dot' ) {
		$self->add_stemma( dot => $answer->{result} );
	} elsif( $answer->{format} eq 'newick' ) {
		my $realsig;
		map { $realsig->{$_->ascii_sigil} = $_->sigil } $self->witnesses;
		$stemmata = Text::Tradition::Stemma->new_from_newick( $answer->{result} );
		my $title = sprintf( "%s %d", $answer->{algorithm}, 
			str2time( $answer->{start_time}, 'UTC' ) );
		my $i = 0;
		foreach my $stemma ( @$stemmata ) {
			my $ititle = $title . "_$i"; $i++;
			$stemma->set_identifier( $ititle );
			$stemma->_set_from_jobid( $jobid );
			# Convert back from ASCII sigla
			$stemma->rename_witnesses( $realsig, 1 );
			$self->_add_stemma( $stemma );
		}
	} else {
		$self->throw( "Cannot parse tree results with format " . $answer->{format} );
	}
	$self->_clear_stemweb_jobid();
	return $stemmata;
}

1;

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
