package Text::TemplateLite::Renderer;

use 5.006;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

=head1 NAME

Text::TemplateLite::Renderer - A rendering-management class for
L<Text::TemplateLite>

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $tpl = Text::TemplateLite->new->set(q{<<$var>>});
    print $tpl->render({ var => 'hello' })->result;

    # Setting execution limits before rendering:
    my $rndr = $tpl->new_renderer
      ->limit(step_length => 1000)
      ->limit(total_steps => 1000)
      ->render;

    # Checking for incomplete results after rendering:
    croak "Template rendering exceeded resource limits"
      if $rndr->exceeded_limits;

=head1 DESCRIPTION

This is the rendering companion class for L<Text::TemplateLite>. It
manages template variables and resource usage when rendering a template.

=head1 USER METHODS

This section describes methods for normal usage.

=head2 new( )

This creates and returns a new renderer instance. The renderer must be
associated with a template (see L<"template($template)">) before rendering.

=cut

sub new {
    my ($class) = @_;
    my $self = bless {
	limits => {
	    step_length => undef,	# step-wise string length
	    total_steps => undef,	# total steps
	},
    }, $class;

    return $self->reset;
}

=head2 reset( )

This resets the renderer between consecutive renderings. It clears any
previous result and associated usage statistics and exceeded-limit
information (but not the limits themselves). It returns the rendering
object.

=cut

sub reset {
    my ($self) = @_;

    $self->{exceeded} = {};
    $self->{info} = {
	stop => 0,
	total_steps => 0,
	undef_calls => 0,
    };
    delete $self->{result};

    return $self;
}

=head2 template( )

=head2 template($template)

The first form returns the current template engine instance
(a L<Text::TemplateLite>).

The second form sets the current template engine instance to $template and
returns the rendering object. This is called automatically by
L<Text::TemplateLite/"new_renderer( )">.

=cut

sub template {
    my ($self, $template) = @_;

    return $self->{template} if @_ < 2;

    croak "Template is not a Text::TemplateLite" if defined($template)
      && (!blessed($template) || !$template->isa('Text::TemplateLite'));
    $self->{template} = $template;
    return $self;
}

=head2 limit($type)

=head2 limit($type, $limit)

The first form returns the current limit for the specified type.

The second form sets a limit and returns the rendering object. A numeric
limit sets a specific limit; C<undef> removes the limit.

The limit types supported in this version are:

=over

=item step_length

This is the maximum length (in characters) allowed to be returned as
the result of any step (or sequence of steps) in the template execution.

For example, given:

    ??($condition, $some$variables, $default)

The substitutions of $condition and $default, the concatenation of
$some and $variables, and the return value from function ?? will each be
truncated to a length of step_length (and step_length will be marked
exceeded) if necessary.

=item total_steps

This is the maximum number of steps that may be executed in the template
code (and across all templates if external template calls are involved).

Template execution will stop (and total_steps will be exceeded) after
this many steps.

=back

=cut

sub limit {
    my ($self, $type, $limit) = @_;

    return $self->{limits}{$type} if @_ < 3;

    $self->{limits}{$type} = $limit;
    return $self;
}

=head2 render(\%variables)

This method renders the associated template with the specified variables
and returns the rendering object (not the result; see L<"result( )">).

Beware! The hashref of variables is subject to modification during rendering!

=cut

sub render {
    my ($self, $vars) = @_;

    $self->reset if exists($self->{result});
    $self->{vars} = $vars || {};

    if ($self->{template}) {
	# Execute the template to render the result
	$self->{result} = $self->{template}->execute($self);
	delete $self->{last_renderer};
    } else {
	# Render without template is undefined
	delete $self->{result};
    }

    return $self;
}

=head2 exceeded_limits( )

=head2 exceeded_limits(@limits)

The first form returns a list of names of any exceeded limits.

The second form adds the specified limits to the list of exceeded limits,
stops rendering, and returns the template engine object.

See L<limit($type, $limit)> for types.

=cut

sub exceeded_limits {
    my $self = shift;

    return keys(%{$self->{exceeded}}) unless @_;

    $self->{exceeded}{$_} = 1 foreach (@_);
    $self->{info}{stop} = 1;
    return $self;
}

=head2 result( )

This method returns the most recent rendering result, or C<undef> if there
isn't one.

=cut

sub result { return shift->{result}; }

=head2 stop( )

This sets the stop flag (visible in L<"info( )">), causing template
execution to terminate further processing. It returns the rendering object.

=cut

sub stop {
    my ($self) = @_;

    $self->{info}{stop} = 1;
    return $self;
}

=head2 info( )

This returns the most recent rendering's execution information as a
hash. The template engine currently returns the following usage (but
library functions could potentially add metrics for specific calls):

=over

=item stop

This is true if execution stopped before the end of the template
(e.g. because total_steps was exceeded).

=item total_steps

This is the total number of steps that were executed (including any
recorded by external template calls).

=item undef_calls

This is the number of calls to undefined functions or external templates
during rendering.

=back

=cut

sub info { return shift->{info}; }

=head2 vars( )

This method returns the hash of current template variables.

=cut

sub vars { return shift->{vars} ||= {}; }

=head1 AUTHOR METHODS

This section describes methods generally only used by library function
authors.

=head2 execute_each($list)

This method is a short-cut to call the template engine's execute_each
method.

=cut

sub execute_each {
    my ($self, $list) = @_;

    return $self->template->execute_each($list, $self);
}

=head2 execute_sequence($code)

This method is a short-cut to call the template engine's execute_sequence
method.

=cut

sub execute_sequence {
    my ($self, $code) = @_;

    return $self->template->execute_sequence($code, $self);
}

=head2 last_renderer( )

This method returns the most recent external template renderer. This
information is only retained until the current rendering has completed
or the next external template call, whichever happens first.

=cut

sub last_renderer { return shift->{last_renderer}; }

=head1 ENGINE METHODS

These methods are used by the template engine. You should probably not be
calling them directly.

=head2 step( )

=head2 step($step)

The first form checks that it is OK to perform another step (based on the
total_steps limit) in template execution. If so, it increments the step
usage and returns true. Otherwise it returns false.

The second form sets the step usage to the specified step number if it is
higher than the current value and returns the rendering object.

=cut

sub step {
    my ($self, $step) = @_;
    my $limit = $self->{limits}{total_steps};

    if (@_ > 1) {
	$self->{info}{total_steps} = $step
	  if $step > $self->{info}{total_steps};
	$self->exceeded_limits('total_steps')
	  if defined($limit) && $step > $limit;
	return $self;
    }

    return 0 if $self->{info}{stop};

    if (!defined($limit) || $self->{info}{total_steps} < $limit) {
	# OK - bump usage
	++$self->{info}{total_steps};
	return 1;
    }

    # Now exceeding step limit
    $self->exceeded_limits('total_steps');
    return 0;
}

=head2 render_external($template, \%vars)

Render an external template, communicating resource usage in and out.

The external renderer is returned.

=cut

sub render_external {
    my ($self, $ext_tpl, $vars) = @_;
    my $ext_rend = $self->{last_renderer} = $ext_tpl->new_renderer();
    my $limits = $self->{limits};

    # Export rendering state
    $ext_rend->limit($_, $limits->{$_}) foreach keys(%$limits);
    $ext_rend->step($self->{info}{total_steps});

    # Render the external template
    $ext_rend->render($vars);

    # Update the internal state to reflect the external rendering
    my $ext_info = $ext_rend->info;
    $self->step($ext_info->{total_steps})
      ->exceeded_limits($ext_rend->exceeded_limits);
    $self->{info}{stop} = 1 if $ext_info->{stop};
    $self->{info}{undef_calls} += $ext_info->{undef_calls};

    return $ext_rend;
}

1; # End of Text::TemplateLite::Renderer
