package Test::Pcuke::Gherkin::Parser;

use warnings;
use strict;

use Carp;

use Test::Pcuke::Gherkin::Executor;
use Test::Pcuke::Gherkin::Node::Feature;
use Test::Pcuke::Gherkin::Node::Background;
use Test::Pcuke::Gherkin::Node::Scenario;
use Test::Pcuke::Gherkin::Node::Outline;
use Test::Pcuke::Gherkin::Node::Scenarios;
use Test::Pcuke::Gherkin::Node::Table;
use Test::Pcuke::Gherkin::Node::Table::Row;
use Test::Pcuke::Gherkin::Node::Step;

=head1 NAME

Test::Pcuke::Gherkin::Parser - parses tokens

=head1 SYNOPSIS

TODO SYNOPSIS

    use Test::Pcuke::Gherkin::Parser;

    my $tree = Test::Pcuke::Gherkin::Parser->parse( $tokens );
    ...

=head1 METHODS

=head2 parse

=cut

my $processors = {
	root	=> {
		'PRAG'	=> \&_trash_processor,
		'TAG'	=> \&_tag_processor,
		'FEAT'	=> \&_feature_processor,
	},
	feature	=> {
		'NARR'	=> \&_narrative_processor,
		'BGR'	=> \&_background_processor,
		'SCEN'	=> \&_scenario_processor,
		'OUTL'	=> \&_outline_processor,
	},
	background	=> {
		'STEP'	=> \&_step_processor,
	},
	scenario	=> {
		'STEP'	=> \&_step_processor,
	},
	outline	=> {
		'STEP'	=> \&_step_processor,
		'SCENS'	=> \&_examples_processor,
	},
	example	=> {
		'TROW'	=> \&_table_processor,
	},
	step	=> {
		'TEXT'	=> \&_text_processor,
		'TROW'	=> \&_table_processor,
	},
};

sub new {
	my ($self, $args) = @_;
	my $instance;
	
	# TODO executor->can(execute) ?
	$instance->{executor} = $args->{executor};
	
	bless $instance, $self;
}

sub _get_executor {
	my ($self) = @_;
	
	return $self->{executor}
		if ref $self && $self->{executor};
		
	return Test::Pcuke::Gherkin::Executor->new(); 
	
}

sub parse {
	my ($self, $tokens, $tree) = @_;
	my $level = 'root';
	
	$tree = $self->_subtree_collector($tokens, $tree, $processors->{$level});
	$tree->{feature}->{tags} = $tree->{tags};
	return Test::Pcuke::Gherkin::Node::Feature->new( $tree->{feature} );
}


###
### Processor methods
###

## if a processor returns a   list ($key, $value) then $tree->{$key} = $value
## if a processir returns arrayref [$key, $value] then push @{ $tree->{$key} }, $value
## if a processor returns ('_trash', '_trash') then skip

sub _feature_processor {
	my ($self, $tokens) = @_;
	my $token = shift @$tokens;
	my $tree = { title => $token->[1] };
	return ( 'feature',  $self->_subtree_collector($tokens, $tree, $processors->{'feature'}) );
}

sub _tag_processor {
	my ($self, $tokens) = @_;
	
	my @tags = map { $_->[1] }	$self->_aggregate_tokens('TAG', $tokens);
	
	return ('tags', \@tags );
}

sub _narrative_processor {
	my ($self, $tokens) = @_;
	
	my @lines = map { $_->[1] }	$self->_aggregate_tokens('NARR', $tokens);
	
	return ('narrative', join ( "\n", @lines ) );
}

sub _text_processor {
	my ($self, $tokens) = @_;
	
	my @lines = map { $_->[1] } $self->_aggregate_tokens('TEXT', $tokens);
	
	return ('text',  join ( "\n", @lines ) );
}

sub _background_processor {
	my ($self, $tokens) = @_;
	
	my $token = shift @$tokens;
	my $tree = { title => $token->[1] };
	
	$tree = $self->_subtree_collector($tokens, $tree, $processors->{'background'});
	
	return ('background', Test::Pcuke::Gherkin::Node::Background->new( $tree ) ); 
}

sub _scenario_processor {
	my ($self, $tokens) = @_;
	my $token = shift @$tokens;
	my $tree = { title => $token->[1] };
	
	$tree = $self->_subtree_collector($tokens, $tree, $processors->{'scenario'} );
	$tree->{executor} = $self->_get_executor;
	
	return [ 'scenarios', Test::Pcuke::Gherkin::Node::Scenario->new( $tree ) ]; 
}

sub _outline_processor {
	my ($self, $tokens) = @_;
	my $token = shift @$tokens;
	my $tree = { title => $token->[1] };
	
	$tree = $self->_subtree_collector($tokens, $tree, $processors->{'outline'});
	return [ 'scenarios', Test::Pcuke::Gherkin::Node::Outline->new( $tree ) ];
}

sub _examples_processor {
	my ($self, $tokens) = @_;
	my $token = shift @$tokens;
	my $tree = { title => $token->[1] };
	
	$tree = $self->_subtree_collector($tokens, $tree, $processors->{'example'} );
	
	return ['examples', Test::Pcuke::Gherkin::Node::Scenarios->new( $tree ) ];
}
		
sub _step_processor {
	my ($self, $tokens) = @_;
	my $token = shift @$tokens;
	my $tree = { type => $token->[1], title => $token->[2] };
	$tree = $self->_subtree_collector($tokens, $tree, $processors->{'step'});
	
	$tree->{executor} = $self->_get_executor;
	
	return [ 'steps', Test::Pcuke::Gherkin::Node::Step->new( $tree ) ];
} 

sub _table_processor {
	my ($self, $tokens) = @_;
	my @rows = map { shift @$_; $_ } $self->_aggregate_tokens('TROW', $tokens);
	
	my $tree = {
		headings => shift @rows, 
		rows => [@rows],
		executor => $self->_get_executor
	};
	
	return ('table', Test::Pcuke::Gherkin::Node::Table->new( $tree ) );
}

sub _trash_processor {
	my ($self, $tokens) = @_;
	shift @$tokens;
	return ('_trash', '_trash');
}



### $tokens
### $tree		hashref with the initial tree
### $processors	hashref, keys are token labels, values are coderefs
### upgrades $tree and returns it
sub _subtree_collector {
	my ($self, $tokens, $tree, $processors) = @_;
	
	while ( @$tokens ) {
		if ( !$tokens->[0]->[0] ) {
			shift @$tokens; # --- what a trash?
			next;
		}
		my ($key, $value);
		for ( keys %$processors ) {
			next unless $tokens->[0]->[0] eq $_;
			($key, $value) = $processors->{$_}->($self, $tokens);
			last;
		}
		last if !$key;
		next if $key eq '_trash';
		push @{ $tree->{ $key->[0] } }, $key->[1] if ref $key eq 'ARRAY';
		$tree->{$key} = $value if $value;
	}
	
	return $tree;
}


###
### aggregates tokens with the label
###
sub _aggregate_tokens {
	my ($self, $label, $tokens) = @_;
	my @collection;
	
	confess "tokens are undefined, check the arguments!" unless $tokens;
	
	while ( $tokens->[0]->[0] && $tokens->[0]->[0] eq $label ) {
		my $token = shift @$tokens;
		push @collection, $token;
	}
	
	return @collection;
}


=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Parser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke-Gherkin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is released under the following license: artistic


=cut

1; # End of Test::Pcuke::Gherkin::Parser
