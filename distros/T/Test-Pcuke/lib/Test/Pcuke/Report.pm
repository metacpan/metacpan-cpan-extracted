package Test::Pcuke::Report;

use warnings;
use strict;

use Template;
use Carp;

our $template;
our $blocks;

=head1 NAME

Test::Pcuke::Report - report builder

=head1 SYNOPSIS

    use Test::Pcuke::Report;
    
	my $report = Test::Pcuke::Report->new(
		features_iterator	=> Test::Pcuke::Iterator->new( $self->{_executed_features} ),
	);
	
	$report->build();

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class, %args) = @_;
	
	my $self = {};
	bless $self, $class;
	
	$self->set_features( $args{features} )
		if $args{features};
	$self->set_debug_template( $args{debug} || q{} );
	
	return $self;
}

sub set_debug_template { $_[0]->{debug_template} = $_[1] }
sub debug_template { $_[0]->{debug_template} || undef }

sub set_features {
	my ($self, $features) = @_;
	$self->{features} = $features;
}

sub features {
	return $_[0]->{features};
}

sub set_printer {
	my ($self, $printer) = @_;
	$self->{printer} = $printer;
}

sub printer { $_[0]->{printer}; }

sub build {
	my ($self) = @_;
	my $output;
	my ($template, $blocks) = $self->_get_template;
	
	my $engine = Template->new(
		PRE_CHOMP	=> 1,
		POST_CHOMP	=> 1,
		PLUGIN_BASE => 'Template::Plugin::Filter',
		BLOCKS		=> $blocks,
		VARIABLES	=> {
			stats 		=> {
				scenarios_failed	=> 0,
				scenarios_undefined	=> 0,
				scenarios_total		=> 0,
				steps_failed		=> 0,
				steps_undefined		=> 0,
				steps_total			=> 0,
			},
			colors		=> {
				head	=> 'bold cyan',
				pass	=> 'green',
				fail	=> 'red',
				undef	=> 'yellow',
			}
			
		},
		DEBUG		=> $self->debug_template,
	)
		|| confess( Template->error(), "\n" );
	
	$engine->process(\$template, {
		features	=> $self->features,
	}, \$output )
		|| confess( Template->error(), "\n" );

	return $output;	
}



sub _get_template {
	my ($self) = @_;
	
	my $text;
	
	return ($template, $blocks)
		if $template && $blocks;
		
	{
		local $/;
		$text = <DATA>;
	}
	
	my @blocks = grep { $_ }
		split( /(\[!!![^!]+!!!\])/, $text );
	
	while( @blocks ) {
		my ($header, $body) = (shift @blocks, shift @blocks);
		if ( $header =~ /\[!!!\s+MAIN\s+!!!\]/ ) {
			$template = $body;
		}
		elsif ( $header =~ /\[!!!\s+BLOCK\s+(\w+)\s+!!!\]/ ) {
			$blocks->{$1} = $body;
		}
		else {
			confess "unknown header: $header!";
		}
	}
	
	return ($template, $blocks);
}

=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is released under the following license: artistic


=cut

1; # End of Test::Pcuke::Report
__DATA__
[!!! MAIN !!!]
[% USE ANSIColor 'color' %]
[% FOREACH feature IN features %]
	[% stats.scenarios_failed		= stats.scenarios_failed	+ feature.nscenarios('fail') %]
	[% stats.scenarios_total		= stats.scenarios_total		+ feature.nscenarios('fail') %]
	[% stats.scenarios_undefined	= stats.scenarios_undefined	+ feature.nscenarios('undef') %]
	[% stats.scenarios_total		= stats.scenarios_total		+ feature.nscenarios('undef') %]
	[% stats.scenarios_total		= stats.scenarios_total		+ feature.nscenarios('pass') %]
	[% stats.steps_failed		= stats.steps_failed	+ feature.nsteps('fail') %]
	[% stats.steps_total		= stats.steps_total		+ feature.nsteps('fail') %]
	[% stats.steps_undefined	= stats.steps_undefined	+ feature.nsteps('undef') %]
	[% stats.steps_total		= stats.steps_total		+ feature.nsteps('undef') %]
	[% stats.steps_total		= stats.steps_total		+ feature.nsteps('pass') %]

	[% feature.title _ "\n\n"%]

	[% feature.narrative _ "\n\n" | indent(4) %]

	[% bgr = feature.background %]
	[% FILTER indent(4) %]
		[% bgr.title _ "\n" %]
		[% FOREACH step IN bgr.steps %]
			[% INCLUDE step %]
		[% END %]
	[% END %][% "\n" %]

	[% FOREACH scenario IN feature.scenarios %]
		[% FILTER indent(4) %][% INCLUDE scenario %][% END %]
	[% END %]
[% END %][% "\n" %]

[% stats.scenarios_total %] scenarios
[% IF stats.scenarios_failed > 0 || stats.scenarios_undefined > 0 %]
	[% " (" %]
	[% IF stats.scenarios_undefined > 0 %]
		[% stats.scenarios_undefined _ " undefined" | color colors.undef %]
		[% IF stats.scenarios_failed > 0 %][% ", " %][% END %]
	[% END %]
	[% IF stats.scenarios_failed > 0 %]
		[% stats.scenarios_failed _ " failed" | color colors.fail %]
	[% END %]
	[%")" %]
[% END %][% "\n" %]

[% stats.steps_total %] steps
[% IF stats.steps_failed > 0 || stats.steps_undefined > 0 %]
	[% " (" %]
	[% IF stats.steps_failed > 0 %]
		[%"${stats.steps_failed} failed"  | color 'red'%]
		[% IF stats.steps_undefined > 0 %][% ", " %][% END %]
	[% END%]
	[% IF stats.steps_undefined > 0 %]
		[% "${stats.steps_undefined} undefined" | color 'yellow' %]
	[% END %]
	[% ")"%]
[% END %]

[!!! BLOCK step !!!]
[% FILTER indent(2) %][% FILTER color colors.${ step.status } %]
	[% step.type | lower | ucfirst %] 
	[% " " _ step.title %]
	[% text = step.text %]
	[% IF text %]
		[% "\n\"\"\"\n" _ text _ "\n\"\"\"" %]
	[% END %]
	[% table = step.table %]
	[% IF table %][% "\n" %]
		[% INCLUDE table %]
	[% END %]
[% END %][% END %]
[% exception = step.result.exception %]
[% IF exception.message %]
[% "\n\nException: " _ exception.message _ "\n" | color colors.fail %]
[% END %]

[!!! BLOCK scenario !!!]
[% scenario.title _ "\n" %]
[% FOREACH step IN scenario.steps %]
	[% INCLUDE step %]
[% END %]
[% FOREACH example IN scenario.examples %]
	[% example.title %][% "\n" %]
	[% table = example.table %]
	[% IF table %][% "\n" %][% INCLUDE table %][% END %]
[% END %]

[!!! BLOCK table !!!]
[% headings = table.headings %]
[% FOREACH h IN headings %]
	[% width.${h} = h.length %]
[% END %]

[% data = [] %]
[% rows = table.rows %]
[% FOREACH r IN rows %]
	[% dr = {} %]
	[% FOREACH c IN r.data %]
		[% dr.${c.key}.value = c.value %]
		[% dr.${c.key}.status = r.column_status( c.key ) %]
	[% END %]
	[% data.push(dr)%]
[% END %]
[% FOREACH hash IN data %]
	[% FOREACH h IN headings %]
		[% IF hash.${h}.value.length > width.${h} %]
			[% width.${h} = hash.${h}.length %]
		[% END %]
	[% END %]
[% END %]

[% FILTER indent(2) %]
	[% FOREACH h IN headings %]
		[% "| " %]
		[% h | format ( '%' _ width.${h} _ 's') | color colors.head %]
		[% " " %]
	[% END %][% "|\n" %]
	[% FOREACH hash IN data %]
		[% FOREACH h IN headings %]
			[% status = hash.${h}.status %]
			[% "| " %] [% hash.${h}.value | format( '%' _ width.${h} _ 's' ) | color colors.${ status } %][% " " %]
		[% END %][% "|\n" %]
	[% END %]
[% END %]