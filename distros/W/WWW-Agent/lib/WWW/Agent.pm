package WWW::Agent;

use strict;
use warnings;
use Data::Dumper;
use POE;

=pod

=head1 NAME

WWW::Agent - Abstract web browser

=head1 SYNOPSIS

   use WWW::Agent
   use WWW::Agent::Plugins::Focus;
   ...
   $agent = new WWW::Agent (plugins => [
                                        new WWW::Agent::Plugins::Focus,
                                        ...
                                        ]);
   $agent->run;

=head1 DESCRIPTION

The web agent is a minimalistic web browser, in that the only thing it
supports is to request an object. For this purpose, it maintains a
concept of I<tabs>, similar to those found in most modern web
browsers. A request will be done in the context of a particular tab.
As a consequence, the agents can handle multiple requests, also
concurrently. This is achieved by using L<POE> underneath.

As the agent is otherwise dumb, it is up to plugins to do something
useful. The range of possible features which plugins can add is
considerable: Plugins can take care off testing websites for correct
behaviour, scraping web sites and lauching external function,
spidering sites to analyze pages or link structures, etc.

=head2 Plugin Events

See L<WWW::Agent::Plugins>.

=head1 INTERFACE

=head2 Constructor

The constructor expects a hash with the following key/value pairs:

=over

=item C<name> (string):

This is currently ignored.

=item C<plugins> (list reference, optional):

Any number of plugins can be loaded into an agent. Each plugin must
be an object (instantiated from the appropriate class).

The sequence of plugins in the list is significant as two or more
plugins might register for one and the same event. The execution of
the individual handler is organized according to the list.

=item C<ua> (L<LWP::UserAgent> object, optional):

This object will be used to launch requests. Obviously any subclass
can be used, say, for providing special headers or one providing
additional caching.

If no LWP::UserAgent object is passed in, the a generic one will be
used.

=back

=cut

sub _filter {
    my $kernel   = shift;
    my $heap     = shift;
    my $policies = shift;
    my $tab      = shift;
    my $value    = shift;

#warn "policies ".Dumper $policies;

    foreach my $p (@$policies) {
#warn " in _compute before one code value=$value";	
	$value = &{$p} ($kernel, $heap, $tab, $value, @_);
    }
#warn " in _compute $value";
    return $value;
}

sub _ok {
    my $kernel   = shift;
    my $heap     = shift;
    my $policies = shift;

    return 1 unless $policies;
    foreach (@$policies) {
	&$_ ($kernel, $heap, @_) or die "not satisfied";
    }
    return 1;
}

sub new {
    my $class   = shift;
    my %options = @_;
    my $self    = bless {}, $class;

    $self->{name}    = delete $options{name}    || 'agent';
    $self->{plugins} = delete $options{plugins} || [];

    use LWP::UserAgent;
    $self->{ua}      = delete $options{ua}      || LWP::UserAgent->new;

    POE::Session->create (
			  inline_states => {
			      _start   => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
				  my ($plugins)       = $_[ARG0];

				  $kernel->alias_set ('agent');
				  $heap->{ua}       = $self->{ua};

				  $heap->{policies} = {
				      init                   => [],
				      cycle_consider         => [],
				      cycle_prepare_request  => [],
#				      cycle_initiate_request => [],
#				      cycle_analyze_response => [],
				      cycle_pos_response     => [],
				      cycle_neg_response     => [],
				      cycle_complete         => [],
				  };

				  foreach my $plugin (@$plugins) {
				      my $ns = $plugin->{namespace};                # reserving namespace
				      die "duplicate namespace '$ns'" if $heap->{$ns};
				      $heap->{$ns} = {};

				      if ($plugin->{depends}) {
					  foreach (@{$plugin->{depends}}) {
					      die "plugin '$ns' depends on other plugin '$_' but that has not been loaded" unless $heap->{$_};
					  }
				      }

				      foreach my $policy_group (keys %{$plugin->{hooks}}) {
					  my $policy   = $plugin->{hooks}->{$policy_group};

					  if ($heap->{policies}->{$policy_group}) { # policy group already exists
					      push @{$heap->{policies}->{$policy_group}}, $policy;
					  } else {                                  # no policy group existed, lets make one
					      $kernel->state ( $policy_group, $policy );
					  }
				      }
				  }

				  _ok ($kernel, $heap, $heap->{policies}->{init});
			      },
			      
			      cycle_start  => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
				  my ($tab, $request) = @_[ARG0, ARG1];
				  $heap->{tabs}->{$tab}->{request} = $request;
				  $kernel->yield ('cycle_consider', $tab);
			      },
			      cycle_consider => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
				  my ($tab)           = $_[ARG0];

				  if (_ok ($kernel, $heap, $heap->{policies}->{cycle_consider}, $tab, $heap->{tabs}->{$tab}->{request})) {
				      $kernel->yield ('cycle_prepare_request', $tab);
				  } else {
				      $kernel->yield ('cycle_complete', $tab);
				  }
			      },
			      cycle_prepare_request => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
				  my ($tab)           = $_[ARG0];
				  my $htab            = $heap->{tabs}->{$tab};

				  $htab->{request} = _filter ($kernel, $heap, $heap->{policies}->{cycle_prepare_request}, $tab, $htab->{request});
				  $kernel->yield ('cycle_initiate_request', $tab);
			      },
			      cycle_initiate_request => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
				  my ($tab)           = $_[ARG0];
				  my $htab            = $heap->{tabs}->{$tab};

				  $htab->{response}   = $heap->{ua}->request ($htab->{request});
				  $kernel->yield ('cycle_analyze_response', $tab);
			      },
			      cycle_analyze_response => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
                                  my ($tab)           = $_[ARG0];
 				  my $htab            = $heap->{tabs}->{$tab};

				  if ($htab->{response}->is_success) {
#				      $htab->{current_url} = $htab->{response}->request->uri;
				      $kernel->yield ('cycle_pos_response', $tab);
				  } else {
				      $kernel->yield ('cycle_neg_response', $tab);
				  }
			      },
			      cycle_pos_response => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
                                  my ($tab)           = $_[ARG0];
 				  my $htab            = $heap->{tabs}->{$tab};

				  $htab->{response} = _filter ($kernel, $heap, $heap->{policies}->{cycle_pos_response}, $tab, $htab->{response});
				  $kernel->yield ('cycle_complete', $tab);
			      },
			      cycle_neg_response => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
                                  my ($tab)           = $_[ARG0];
 				  my $htab            = $heap->{tabs}->{$tab};

				  $htab->{response} = _filter ($kernel, $heap, $heap->{policies}->{cycle_neg_response}, $tab, $htab->{response});
				  $kernel->yield ('cycle_complete', $tab);
			      },
			      cycle_complete => sub {
				  my ($kernel, $heap) = @_[KERNEL, HEAP];
                                  my ($tab)           = $_[ARG0];

				  _ok ($kernel, $heap, $heap->{policies}->{cycle_complete}, $tab);
			      },
			  },
			  args => [ $self->{plugins} ],
			  );
    return $self;
}

=pod

=head2 Methods

=over

=item C<run> (no parameters)

This method makes the agent run and do whatever it is told to do. If
you have not posted any requests to C<cycle_start> before that, then
the agent will immediately terminate.

Consequently it is either your responsibility to task the agent with
requests, or the responsibility of specific plugins to do that.  One
other option is to set up another L<POE> session which posts events to
the agent (it's POE name is C<agent>, btw).

Example:

   my $a = new WWW::Agent (....);
   use POE;
   POE::Kernel->post ('agent', 'cycle_start', 'new_tab', 'http://www.example.org/');
   $a->run;  # fetch it and ... that's it

=cut

sub run {
    my $self = shift;
    POE::Kernel->run();
}

=pod

=back

=head1 SEE ALSO

L<WWW::Agent::Plugins>, L<LWP::UserAgent>, L<POE>

=head1 AUTHOR

Robert Barta, E<lt>rho@bigpond.net.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

our $VERSION  = '0.03';
our $REVISION = '$Id: Agent.pm,v 1.3 2005/03/19 10:01:15 rho Exp $';

1;


__END__
