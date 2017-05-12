package VANAMBURG::SEMPROG::SimpleGraph;

use vars qw($VERSION);
$VERSION = '0.010';

use Moose;
use Text::CSV_XS;
use Set::Scalar;
use List::MoreUtils qw(each_array);
use JSON;
use File::Slurp;

use English;

#
# Store triples in nested hashrefs with a Set::Scalar instance
# at the leaf nodes.
# Keep several hashes for accessing based on need
# in calls to 'triples' method.  Three indexes are:
#   1) subject, then predicate then object set, or
#   2) predicate, object, then subject set,
#   3) object, then subject then predicate set.
#
# example:
#
#    my $obj_set = $self->_spo()->{sub}->{pred};
#

has '_spo' => ( isa => 'HashRef', is => 'rw', default => sub { {} } );
has '_pos' => ( isa => 'HashRef', is => 'rw', default => sub { {} } );
has '_osp' => ( isa => 'HashRef', is => 'rw', default => sub { {} } );

sub add {
    my ( $self, $sub, $pred, $obj ) = @_;

    $self->_addToIndex( $self->_spo(), $sub,  $pred, $obj );
    $self->_addToIndex( $self->_pos(), $pred, $obj,  $sub );
    $self->_addToIndex( $self->_osp(), $obj,  $sub,  $pred );
}

sub _addToIndex {
    my ( $self, $index, $a, $b, $c ) = @ARG;

    return if ( !defined($a) || !defined($b) || !defined($c) );

    if ( !defined( $index->{$a}->{$b} ) ) {
        my $set = Set::Scalar->new();
        $set->insert($c);
        $index->{$a}->{$b} = $set;
    }
    else {
        $index->{$a}->{$b}->insert($c);
    }
}

sub remove {
    my ( $self, $sub, $pred, $obj ) = @ARG;

    my @tripls = $self->triples( $sub, $pred, $obj );
    for my $t (@tripls) {
        $self->_removeFromIndex( $self->_spo(), $t->[0], $t->[1], $t->[2] );
        $self->_removeFromIndex( $self->_pos(), $t->[1], $t->[2], $t->[0] );
        $self->_removeFromIndex( $self->_osp(), $t->[2], $t->[0], $t->[1] );
    }
}

sub _removeFromIndex {
    my ( $self, $index, $a, $b, $c ) = @ARG;

    eval {
        my $bs   = $index->{$a};
        my $cset = $bs->{$b};
        $cset->delete($c);
        delete $bs->{$b} if ( $cset->size == 0 );
        delete $index->{$a} if ( keys(%$bs) == 0 );
    };
    if ($EVAL_ERROR) { print "ERROR: $EVAL_ERROR\n"; }
}

sub triples {
    my ( $self, $sub, $pred, $obj ) = @ARG;

    my @result;

    # check which terms are present in order to use the correct index:

    if ( defined($sub) ) {
        if ( defined($pred) ) {

            # sub pred obj
            if ( defined($obj) && defined( $self->_spo()->{$sub}->{$pred} ) ) {
                push @result, [ $sub, $pred, $obj ]
                  if ( $self->_spo()->{$sub}->{$pred}->has($obj) );

            }
            else {

                # sub pred undef
                map { push @result, [ $sub, $pred, $_ ]; }
                  $self->_spo()->{$sub}->{$pred}->members()
                  if defined( $self->_spo()->{$sub}->{$pred} );
            }
        }
        else {

            # sub undef obj
            if ( defined($obj) && defined( $self->_osp()->{$obj}->{$sub} ) ) {
                push @result, [ $sub, $obj, $_ ]
                  for $self->_osp()->{$obj}->{$sub}->members();
            }
            else {

                # sub undef undef
                while ( my ( $retPred, $objSet ) =
                    each %{ $self->_spo()->{$sub} } )
                {
                    push @result, [ $sub, $retPred, $_ ] for $objSet->members();
                }
            }
        }
    }
    else {
        if ( defined($pred) ) {

            # undef pred obj
            if ( defined($obj) ) {

                map { push @result, [ $_, $pred, $obj ] }
                  $self->_pos()->{$pred}->{$obj}->members()
                  if ( defined( $self->_pos()->{$pred}->{$obj} ) );
            }
            else {

                # undef pred undef
                while ( my ( $retObj, $subSet ) =
                    each %{ $self->_pos()->{$pred} } )
                {
                    push @result, [ $_, $pred, $retObj ] for $subSet->members();
                }
            }
        }
        else {

            # undef undef obj
            if ( defined($obj) ) {
                while ( my ( $retSub, $predSet ) =
                    each %{ $self->_osp()->{$obj} } )
                {
                    push @result, [ $retSub, $_, $obj ] for $predSet->members();
                }
            }
            else {

                # undef undef undef
                while ( my ( $retSub, $predHash ) = each %{ $self->_spo() } ) {
                    while ( my ( $retPred, $objSet ) = each %{$predHash} ) {
                        push @result, [ $retSub, $retPred, $_ ]
                          for $objSet->members();
                    }
                }
            }
        }

    }

    return @result;
}

sub value {
    my ( $self, $sub, $pred, $obj ) = @ARG;

    for my $t ( $self->triples( $sub, $pred, $obj ) ) {
        return $t->[0] if !defined($sub);
        return $t->[1] if !defined($pred);
        return $t->[2] if !defined($obj);
        last;
    }
}

sub load {
    my ( $self, $filename ) = @ARG;

    my $csv = Text::CSV_XS->new(
        { allow_whitespace => 1, binary => 1, blank_is_undef => 1 } )
      or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

    open my $fh, "<:encoding(utf8)", $filename or die "$!";

    while ( my $row = $csv->getline($fh) ) {
        $self->add( $row->[0], $row->[1], $row->[2] );
    }

    close $fh or die "$!";
}

sub load_json {
    my ( $self, $filename ) = @ARG;

    my $text = read_file($filename) or die "Cannot read_file: $!";
    my $data = from_json( $text, { utf8 => 1 } );

    for my $t ( @{ $data->{triples} } ) {
        $self->add( $t->{s}, $t->{p}, $t->{o} );
    }
}

sub save {
    my ( $self, $filename ) = @ARG;

    open my $fh, ">", $filename or die "Cannot open file for save: $!";

    my $csv =
      Text::CSV_XS->new( { allow_whitespace => 1, blank_is_undef => 1 } )
      or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

    $csv->eol("\r\n");

    $csv->print( $fh, $_ )
      or csv->error_diag()
      for $self->triples( undef, undef, undef );

    close $fh or die "Cannot close file for save: $!";
}

sub query {
    my ( $self, $clauses ) = @ARG;

    my @bindings;

    my @trpl_inx = ( 0 .. 2 );

    for my $clause (@$clauses) {
        my %bpos;
        my @qparams;
        my @rows;

        # Check each three indexes of clause to see if
        # it is a binding variable (starts with '?').
        # Generate a store for the binding variables,
        # implimented as a hash keyed by binding variable name,
        # and holding the triple index indicating if it
        # represents a subject, predicate, or object.
        #
        # Also define parameters for subsequent call to
        # 'triples'.

        my $each = each_array( @$clause, @trpl_inx );
        while ( my ( $x, $pos ) = $each->() ) {
            if ( $x =~ /^\?/ ) {
                push @qparams, undef;
                my $key = substr( $x, 1 );
                $bpos{$key} = $pos;
            }
            else {
                push @qparams, $x;
            }
        }

        @rows = $self->triples( $qparams[0], $qparams[1], $qparams[2] );
        if ( !@bindings ) {
            for my $row (@rows) {
                my %binding;
                while ( my ( $var, $pos ) = each %bpos ) {
                    $binding{$var} = $row->[$pos];
                }

                push @bindings, \%binding;
            }
        }
        else {
            my @newb;
            for my $binding (@bindings) {
                for my $row (@rows) {
                    my $validmatch  = 1;
                    my %tempbinding = %$binding;
                    while ( my ( $var, $pos ) = each %bpos ) {
                        if ( defined( $tempbinding{$var} ) ) {
                            if ( $tempbinding{$var} ne $row->[$pos] ) {
                                $validmatch = 0;
                            }
                        }
                        else {
                            $tempbinding{$var} = $row->[$pos];
                        }
                    }
                    if ($validmatch) {
                        push @newb, \%tempbinding;
                    }

                }
            }
            @bindings = @newb;
        }
    }
    return @bindings;
}

sub applyinference {
    my ( $self, $rule ) = @ARG;

    my @bindings = $self->query( $rule->getqueries() );

    for my $binding (@bindings) {
        for my $triple ( @{ $rule->maketriples($binding) } ) {
            $self->add(@$triple);
        }
    }

}

1;

__END__


=head1 SYNOPSIS

A Perl interpretation of the SimpleGraph developed in Python by Toby Segaran in his book "Programming the Semantic Web", published by O'Reilly, 2009.  CPAN modules are used in place of the Python standard library modules used by Mr. Segaran.

    my $graph = VANAMBURG::SEMPROG::SimpleGraph->new();

    $graph->load("data/place_triples.txt");

    $graph->add("Morgan Stanley", "headquarters", "New_York_New_York");

    my @sanfran_key = $graph->value(undef,'name','San Francisco');

    my @sanfran_triples = $graph->triples($sanfram_key, undef, undef);

    my @bindings = $g->query([
       ['?company', 'headquarters', 'New_York_New_York'],
       ['?company', 'industry',     'Investment Banking'],
       ['?contrib', 'contributor',  '?company'],
       ['?contrib', 'recipient',    'Orrin Hatch'],
       ['?contrib', 'amount',       '?dollars'],
    ]);

    for my $binding (@bindings){
       printf "company=%s, contrib=%s, dollars=%s\n", 
           ($binding->{company},$binding->{contrib},$binding->{dollars});
    }
    

    $graph->applyinference( VANAMBURG::SEMPROG::GeocodeRule->new() );


=head1 SimpleGraph

   
This module and it's test suite is inspired by the simple triple store implimentation
developed in chapters 2 and 3 of "Programming the Semantic Web" by Toby Segaran, 
Evans Colin, Taylor Jamie, 2009, O'Reilly.  Mr. Segaran uses Python and 
it's standard library to show the workins of a triple store.  This module 
and it's test make the same demonstration using Perl and CPAN modules, which 
may be thought of as a Perl companion to the book for readers who are interested in Perl.  Copies of Mr. Segaran's test data files are included in this distribution for your convenience.

In addition to SimpleGraph, the triple store, the other exercises presented in chapters 2 and 3 are here interpreted as a set of perl test programs, using
Test::More and are found in the modules 't/' directory.
    

B<Triple Store Modules>

    lib/VANAMBURG/SEMPROG/SimpleGraph.pm
    
    lib/VANAMBURG/SEMPROG/CloseToRule.pm
    lib/VANAMBURG/SEMPROG/GeocodeRule.pm
    lib/VANAMBURG/SEMPROG/InferenceRule.pm    
    lib/VANAMBURG/SEMPROG/TouristyRule.pm
    lib/VANAMBURG/SEMPROG/WestCoastRule.pm

B<Module Usage Shown in Tests>

    t/semprog_ch02_03_places.t
    t/semprog_ch02_04_celebs.t
    t/semprog_ch02_05_business.t
    t/semprog_ch02_moviegraph.t
    t/semprog_ch03_01_queries.t
    t/semprog_ch03_02_inference.t
    t/semprog_ch03_03_chain_of_rules.t
    t/semprog_ch03_04_shortest_path.t
    t/semprog_ch03_05_join_graph.t
    qt/semprog_ch03_chain_of_rules.t


Find out more about, or get the book at http://semprog.com, the Semantic Programming web site.

=head1 INSTALLATION NOTES

This module can be installed via cpan.  This method resolves dependency
issues and is convenient. In brief, it looks something like this in a 
terminal on linux:
 
  $sudo cpan
  cpan>install VANAMBURG::SEMPROG::SimpleGraph
  ...
  cpan>quit
  $

All dependencies, as well as the modules are now installed.  Leave out 'sudo' if using Strawberry perl on Windows.

You can then download the source package and read and run the test programs.

  $tar xzvf VANAMBURG-SEMPROG-SimpleGraph-0.001.tar.gz
  $cd VANAMBURG-SEMPROG-SimpleGraph-0.001/  
  $ perl Makefile.PL
  ...
  $make
  ...

Run 'dmake' instead of 'make' if using Strawberry Perl on Windows.

To run all the test programs:
 
  $make test

  -- Note that some tests require internet access for geo code data.

To run one test:

  $prove -Tvl lib - t/semprog_ch03_05_join_graph.t 





=head1 MooseX::Declare Experiment

Version 0.007 was an experiment in using MooseX::Declare.  The code remaind the same as version 0.006,
except that classes were defined by the 'class' keyword instead of 'package' and methods are
defined using 'method' keyword and well defined parameter lists in place of 'sub' and '@_'.  
'class' and 'method' are supplied by MooseX::Declare.

=head2 Types of Changes to Source Files

The types of changes to the source looks like this.
	
	1) CLASS DECLARATIONS WERE CHANGED

	OLD PACKAGE STATEMENTS REMOVED:
	<<package VANAMBURG::SEMPROG::SimpleGraph;
	<<use Moose;

	REPLACED WITH MUCH CLEANER DECLARATIONS:
	>>use MooseX::Declare;
	>>class VANAMBURG::SEMPROG::SimpleGraph{

	2) METHOD DECLARATIONS WERE CHANGED

	OLD SUB AND @ARG REMOVED:
	<<sub _addToIndex{
	<<    my ($self, $index, $a, $b, $c) = @ARG;
	 
	REPLACED WITH METHOD AND DEFINED OPTIONAL PARAMS:
	>>method add($sub?, $pred?, $obj?){

=head2 Performance Changes

Version 0.007, using MooseX::Declare took ten times as long as using Moose alone.Subsequent to this test, version 0.008 was created by rolling back to the Version 0.006 sources.

=head2 Devel::NYTProf For Version 0.006 (Moose only)


	Performance Profile Index
	For t/semprog_ch03_01_queries.t
	  Run on Sun Jan 10 01:14:07 2010
	Reported on Sun Jan 10 01:16:44 2010

	Profile of t/semprog_ch03_01_queries.t for 64.0s, executing 10616075 statements and 3106325 subroutine calls in 119 source files and 194 string evals.
	Top 15 Subroutines — ordered by exclusive time 
	Calls 	P 	F 	Exclusive
	Time 	Inclusive
	Time 	Subroutine
	374201	2	2	6.10s	8.74s	Set::Scalar::Base::::_insert_elements Set::Scalar::Base::_insert_elements
	187100	1	1	3.90s	15.2s	Set::Scalar::::_insert_hook Set::Scalar::_insert_hook
	451618	2	2	3.18s	3.18s	Set::Scalar::Base::::_invalidate_cached Set::Scalar::Base::_invalidate_cached
	264518	4	3	2.61s	3.88s	Set::Scalar::Base::::_make_elements Set::Scalar::Base::_make_elements
	109683	3	1	2.45s	26.6s	VANAMBURG::SEMPROG::SimpleGraph::::_addToIndexVANAMBURG::SEMPROG::SimpleGraph::_addToIndex
	109683	2	1	1.86s	14.0s	Set::Scalar::Real::::insert Set::Scalar::Real::insert
	187100	2	2	1.85s	17.1s	Set::Scalar::Base::::_insert Set::Scalar::Base::_insert
	187101	2	2	1.72s	6.10s	Set::Scalar::Virtual::::_extend Set::Scalar::Virtual::_extend
	77417	1	1	1.63s	9.01s	Set::Scalar::::_new_hook Set::Scalar::_new_hook
	36561	1	1	1.39s	28.6s	VANAMBURG::SEMPROG::SimpleGraph::::addVANAMBURG::SEMPROG::SimpleGraph::add
	77417	1	1	1.36s	1.90s	Set::Scalar::Real::::_delete Set::Scalar::Real::_delete
	77417	1	1	1.32s	6.82s	Set::Scalar::Real::::clear Set::Scalar::Real::clear
	219366	1	1	1.26s	1.26s	Set::Scalar::Base::::_strval Set::Scalar::Base::_strval
	77417	1	1	1.11s	4.73s	Set::Scalar::Real::::delete Set::Scalar::Real::delete
	77419	3	2	1.11s	10.1s	Set::Scalar::Base::::new Set::Scalar::Base::new

=head2 Devel::NYTProf For Version 0.007 (MooseX::Declare)

	Performance Profile Index
	For t/semprog_ch03_01_queries.t
	  Run on Sun Jan 10 01:28:09 2010
	Reported on Sun Jan 10 01:38:25 2010

	Profile of t/semprog_ch03_01_queries.t for 489s, executing 74793743 statements and 24836936 subroutine calls in 371 source files and 407 string evals.
	Top 15 Subroutines — ordered by exclusive time 
	Calls 	P 	F 	Exclusive
	Time 	Inclusive
	Time 	Subroutine
	1426306	23	11	38.3s	250s	MooseX::Types::TypeDecorator::::AUTOLOAD MooseX::Types::TypeDecorator::AUTOLOAD
	438753	1	1	36.5s	186s	MooseX::Types::Structured::::__ANON__[MooseX/Types/Structured.pm:745] MooseX::Types::Structured::__ANON__[MooseX/Types/Structured.pm:745]
	2304288	3	1	26.0s	30.6s	MooseX::Types::TypeDecorator::::__type_constraint MooseX::Types::TypeDecorator::__type_constraint
	1280098	6	5	21.2s	163s	Moose::Meta::TypeConstraint::::check Moose::Meta::TypeConstraint::check
	548425	2	2	15.1s	18.8s	Moose::Meta::TypeConstraint::::Defined Moose::Meta::TypeConstraint::Defined
	146251	1	1	12.2s	16.8s	MooseX::Method::Signatures::Meta::Method::::__ANON__[MooseX/Method/Signatures/Meta/Method.pm:430] MooseX::Method::Signatures::Meta::Method::__ANON__[MooseX/Method/Signatures/Meta/Method.pm:430]
	585005	2	1	11.2s	303s	MooseX::Meta::TypeConstraint::Structured::::__ANON__[MooseX/Meta/TypeConstraint/Structured.pm:115] MooseX::Meta::TypeConstraint::Structured::__ANON__[MooseX/Meta/TypeConstraint/Structured.pm:115]
	1426306	1	2	9.06s	9.06s	MooseX::Types::TypeDecorator::::CORE:match MooseX::Types::TypeDecorator::CORE:match (opcode)
	438881	9	7	8.41s	17.2s	MooseX::Types::TypeDecorator::::isa MooseX::Types::TypeDecorator::isa
	3924871	56	34	7.80s	7.80s	Scalar::Util::::blessed Scalar::Util::blessed (xsub)
	1426685	7	6	7.22s	7.22s	Moose::Meta::TypeConstraint::::_compiled_type_constraint Moose::Meta::TypeConstraint::_compiled_type_constraint
	374201	2	2	6.31s	9.05s	Set::Scalar::Base::::_insert_elements Set::Scalar::Base::_insert_elements
	219366	4	2	5.35s	227s	VANAMBURG::SEMPROG::SimpleGraph::::_addToIndex VANAMBURG::SEMPROG::SimpleGraph::_addToIndex
	146251	1	1	4.87s	256s	MooseX::Meta::TypeConstraint::ForceCoercion::::validateMooseX::Meta::TypeConstraint::ForceCoercion::validate
	146251	1	1	4.87s	263s	MooseX::Method::Signatures::Meta::Method::::validate MooseX::Method::Signatures::Meta::Method::validate


=head1 METHODS

=head2 add

Adds a triple to the graph.

    $g->add("San Francisco", "inside", "California");
    $g->add("Ann Arbor", "inside", "Michigan");

=head2 remove

Remove a triple pattern from the graph.    

    # remove all triples with predicate "inside"
    $g->remove(undef, "inside", undef);


=head2 triples

    # retrieve all triples with predicate "inside"
    my @triples = $g->triples(undef, "inside", undef);

    # @triples looks like this:
    #  ( 
    #    ["San Francisco", "inside", "California"],
    #    ["Ann Arbor", "inside", "Michigan"],
    #  )

=head2 value

Retrieve a single value from a triple.

    my $x = $g->value(undef, 'inside', 'Michigan');
    # $x contains "Ann Arbor" given examples added.


=head2 query

Returns array of hashrefs where keys are binding variables for triples.

    my @bindings = $g->query([
	['?company','headquarters','New_York_New_York'],
	['?company','industry','Investment Banking'],
	['?cont','contributor','?company'],
	['?cont', 'recipient', 'Orrin Hatch'],
	['?cont', 'amount', '?dollars'],
    ]);

=head2 applyinference

Given an InferenceRule, generates additional triples in the triple store.


=head2 load
 
Loads a csv file in utf8 encoding.

    $g->load("some/file.csv");


=head2 load_json

Loads a json file into a graph.  The json file should be formated as follows:

{
    "triples" : [
        {   "s": "your subject 1",
            "p": "your predicate 1",
 	    "o": "your object 1"
        }, { "s": "your subject 2",
            "p": "your predicate 2",
 	    "o": "your object 2"
        }
     ]
}


=head2 save
 
Saves a csv file in utf8 encoding.

    $g->load("some/file.csv");

=head2 _addToIndex

See source for details.


=head2 _removeFromIndex

        Removes a triple from an index and clears up empty indermediate structures.


=cut 
