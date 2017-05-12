package Test::Pcuke::Gherkin::Tests::Mockery;

use warnings;
use strict;
use base 'Exporter';

our @EXPORT_OK = qw{cmock instance metrics omock};

use Mock::Quick;
use Carp;

=head1 SYNOPSIS

This package exports functions to mock object and classes for Test::Pcuke::Gherkin::Node
unit tests

	use FindBin qw{$Bin};

	BEGIN {
		if ( $Bin =~ /^(.+)$/ ) { $Bin = $1 } # untaint $Bin
		else { die "wrong Bin path!" }	
		require lib; lib->import( "$Bin/lib" );
	
		require Test::Pcuke::Gherkin::Tests::Mockery; Test::Pcuke::Gherkin::Tests::Mockery->import( qw{omock metrics cmock instance} );
	}

=cut

# keeps configs, controls and instances for cmock
# to factor out project-specific mockery
# one can add config_cmocks function that sets methods
my $cmocks	= {
	outline 		=> {
	 	class	=> 'Test::Pcuke::Gherkin::Node::Outline',
		methods => [ qw{
			add_examples	set_title	add_step
			examples		title		steps
			nsteps			nscenarios
			execute} ],		
	},
	background		=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Background',
		methods => [ qw{
			title		steps		nsteps
			set_title	add_step	execute } ],
	},
	scenario		=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Scenario',
		methods => [ qw{
			title		steps		scenarios
			set_title	add_step	nsteps
			nscenarios	execute} ],
	},
	step			=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Step',
		methods	=> [qw{
			set_type	set_title	set_table	set_text	set_params
			type		title		table		text		unset_params
			execute		status		param_names	exception
			executor
		}],
	},
	execution_status=> {
		class	=> 'Test::Pcuke::Gherkin::Executor::Status',
		methods => [qw{status}],
	},
	scenarios		=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Scenarios',
		methods	=> [qw{title set_title set_table execute table nsteps nscenarios}],
	},
	table			=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Table',
		methods	=> [qw{hashes rows execute headings nsteps nscenarios}],
	},
	trow			=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Table::Row',
		methods	=> [ qw{execute set_data data status nsteps nscenarios set_executor} ]
	},
	feature			=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Feature',
		methods	=> [qw{
			title		narrative		scenarios		background
			set_title	set_narrative	add_scenario	set_background
			add_outline	nsteps			nscenarios
			execute		tags} ],
	},
	executor		=> { # for omock %-)
		class	=> 'Test::Pcuke::Gherkin::Executor',
		methods	=> [qw{execute}],
	},
	step_failure	=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Step::Failure',
	},
	step_undefined	=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Step::Undefined',
	},
	iterator		=> {
		class	=> 'Test::Pcuke::Gherkin::Node::Iterator',
		methods	=> [qw{next}],
	},
	printer			=> {
		class	=> 'Local::Printer',
		methods	=> [qw{print}],
	}
};

# returns the metrics for an invocation of $obj-><$method>()
# $obj can be a mock object reference or a cmocked class nick
sub metrics {
	my ($obj, $method) = @_;
	my $metrics = ref $obj ?
		  ref $obj eq 'Mock::Quick::Object' ?
		  	  qcontrol($obj)->metrics->{$method}
		  	: qcontrol($obj->{instance})->metrics->{$method}
		: $cmocks->{$obj}->{control} ?
		  $cmocks->{$obj}->{control}->metrics->{$method}
		: undef;
			
	return $metrics;
}

# returns an $no-th instance of a class
sub instance {
	my ($nick, $no) = @_;
	$no ||= 0;
	$cmocks->{$nick}->{instances}->[$no];
}

# mocks the class so that CLASS->new returns an object that keeps a metrics of instance method invocations
# $args is a hashref, that say how to override a methods
# keys are method names, values are either a code reference for method or anything that method should return
sub cmock {
	my ($nick, $args) = @_;
	my $class = $cmocks->{$nick}->{class};
	
	confess "Class $nick is not configured!"
		unless $class;
	
	$cmocks->{$nick}->{control} = undef if $cmocks->{$nick}->{control};
	$cmocks->{$nick}->{instances} = [ ];
	
	$cmocks->{$nick}->{control} = qclass(
		-takeover 		=> $class,
		new 			=> sub {
			my ($instance, @instance_args) = @_;
			#
			# one can pass a hashref that says how to override instance methods
			my $instance_args = ref $instance_args[-1] eq 'HASH' ?
				  $instance_args[-1]
				: $args;
			
			my $mocked = {instance => omock($nick, $instance_args) };
			bless $mocked, $class;
			
			push @{ $cmocks->{$nick}->{instances} }, $mocked;
			
			return $mocked;
		},
		map {
			my $method = $_;
			$method => sub {
				my $self = shift;
				my $instance = $self->{instance};
				# invoke the instance method
				$instance->can($method)->($instance, @_);
			}
		} @{ $cmocks->{$nick}->{methods} }
	);
}

# returns a mocked object
# $class is used to override the methods defined in the cmocks configuration
# $args - see cmock()
sub omock {
	my ($nick, $args) = @_;
	
	confess "No '$nick' object is declared"
		unless $cmocks->{$nick};
	
	confess "No methods declared for $nick"
		unless ref $cmocks->{$nick}->{methods} eq 'ARRAY';
		
	my @methods = @{ $cmocks->{$nick}->{methods} };
	
	my ($instance, $control);
	
	($instance, $control) = qstrict(
		_quick_metrics => qmeth {
			my ($self, $method) = @_;
			return $control->metrics->{$method};
		},
		map {
			my $mn = $_;
			my $md = $args->{$mn} || sub { 0 };
			( $mn => qmeth { ref $md eq 'CODE' ? $md->(@_) : $md; } );
		} @methods
	);
	
	return $instance;
}

1;

