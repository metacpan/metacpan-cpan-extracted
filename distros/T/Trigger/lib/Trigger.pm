package Trigger;

use strict;
use 5.8.1;
our $VERSION = '0.02';

use base qw(Class::Accessor::Fast);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->mk_accessors(qw/heap _process _trigger _action _trigger_and_action _end/);
    
    my $args  = {
        #inline_states => {},
        @_
    };

    if( my $inline_states = delete $args->{inline_states} ){
        $args = {
            heap    => {},
            init    => undef,
            process => sub { 1 },
            trigger_and_action  => [],
            end     => undef,
            %{$inline_states}
        };
    }

    $self->heap($args->{heap}) if defined $args->{heap};
    $self->_process($args->{process});
    $self->_trigger([]);
    $self->_action([]);
    $self->_end($args->{end});
    $self->_trigger_and_action( scalar @{$args->{trigger_and_action}} );
    $self->_trigger_and_action % 2 and die ;
    while( @{$args->{trigger_and_action}} ){
        my($trigger, $action) = splice @{$args->{trigger_and_action}}, 0, 2;
        push @{$self->_trigger}, $trigger;
        push @{$self->_action} , $action;
    }
    $self->_trigger_and_action( $self->_trigger_and_action / 2 - 1);
    $args->{init}->($self) if defined $args->{init} and ref $args->{init};
    return $self;
}

sub eval{
    my $self = shift;
    my @action_re;
    my @process_re = $self->_process->($self => @_);
    for ( 0 .. $self->_trigger_and_action ){
        if( my @trigger_re = $self->_trigger->[$_]->($self => @process_re) ){
            if( ref $self->_action->[$_] eq 'CODE' ){
                @action_re = $self->_action->[$_]->($self => @trigger_re) ;
            }elsif( ref $self->_action->[$_] eq 'ARRAY' ){
                for my $code( @{$self->_action->[$_]} ){
                    @action_re = $code->($self => @trigger_re);
                }
            }else{
                die ref $self->_action->[$_];
            }
        }
    }
    @action_re ? return @action_re : return @process_re;
}

sub DESTROY{
    my $self = shift;
    $self->_end->($self) if $self->_end;
    delete $self->{$_} for (keys %{$self});
}

1;
__END__

=encoding utf-8

=head1 NAME

Trigger - Trigger framework

=head1 SYNOPSIS

	use Trigger;
	my $trigger = Trigger->new(
		inline_states => {
		    heap        => {}, # \%hash or \@array or \$scalar or \&sub or object
		    init        => sub {
		        my $context = shift;
		        my $heap = $context->heap;
		        # Initial processing
		    },
		    process     =>  sub {
		        my $context = shift;
		        my $heap = $context->heap;
		        my @args = @_;
		        # Main processing
		    },
	
		    trigger_and_action => [
		        sub { # trigger
		            # The place which defines conditions.
		            my $context = shift;
		            my $heap = $context->heap;
		            my @args = @_; # The return value of 'process'
		            # 'trigger' must return a value or must return FALSE.
		            # ex.) defined $result ? return $result : return;
		        } => sub { # action
		            my $context = shift;
		            my $heap = $context->heap;
		            # Processing to carry out when a condition was satisfied

		            # 'action' will be performed if 'trigger' returns true.
		            my @trigger_re = @_; # The return value of 'trigger'
		        },

		        #   One or more triggers and actions can be defined.
                sub { # trigger
                    #   :
                } => [ 
                	# The reference of arrangement can define two or more "actions."
                	# "Action" is performed by the defined turn.
                	sub { # action
	                    my $context = shift;
    	                my $heap = $context->heap;
                    	#   :
                	},
                	sub { # action
	                    my $context = shift;
    	                my $heap = $context->heap;
                    	#   :
                	},
                ],
          ],
          end     =>  sub {
              my $context = shift;
              my $heap = $context->heap;
              # Post-processing
          },
      }
  );

  while ( @list ){
      my @args = split /,/, $_;
      my $result = $trigger->eval(@args) or last;
      # It evaluates whether the conditions of a trigger are fulfilled.
  }


=head1 DESCRIPTION

When conditions (Triggers) are set, the specified action will be processed automatically. 
More than one Trigger and action can be defined.


=head1 METHODS

=head2 new(%args)

A trigger and action are defined.

=head2 eval(@args)

The result of an eval method returned the result processed by 'process'. 
When the conditions of a trigger are fulfilled, the result of action serves as a return value of an eval method.
When one or more triggers are defined, the return value of action performed at the end turns into a return value of an eval method.


=head1 AUTHOR

Yuji Suzuki E<lt>yuji.suzuki.perl@gmail.comE<gt>

L<http://arbolbell.jp/> # Japanese only


=head1 BUGS

Please report any bugs or feature requests to C<bug-trigger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Trigger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Trigger

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Trigger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Trigger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Trigger>

=item * Search CPAN

L<http://search.cpan.org/dist/Trigger>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Yuji Suzuki, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
