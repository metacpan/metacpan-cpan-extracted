
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::Controller;

use X10::Device;
use X10::Event;

sub unique (&@);

sub new
{
   my $type = shift;

   my $self = bless { @_ };
   bless $self, $type;

   $self->{logger} ||= sub {
	shift;
	printf(@_);
	print "\n";
	};

   $self->{verbose} = 1 if $self->{debug};

   $self->{house_code} ||= 'A';
   $self->{house_code} = uc($self->{house_code});

   $self->{listeners} = [];
   $self->{output_word_queue} = [];
   $self->{states} = {};
   $self->{working} = 0;

   return $self;
}


### creating controlled devices...

sub Appliance
{
   my $self = shift;
   return new X10::Device(
	controller => $self,
	@_,
	);
}

sub Lamp
{
   my $self = shift;
   return new X10::Device(
	controller => $self,
	@_,
	);
}

### directing input/output

sub register_listener
{
   my $self = shift;
   my $coderef = shift;

   push @{$self->{listeners}}, $coderef;
}

# this is what the main program will use to find what to select() on
sub select_fds
{
   my $self = shift;

   # nothing, in this abstract class
   return ();
}

# this is what the main program will call when my FD is readable
sub handle_input
{
   my $self = shift;
   # there will be no input in this abstract class...
}

### manipulating controlled devices

sub on
{
   my $self = shift;

   $self->send( map { new X10::Event(sprintf("%s ON", $_->address)) } @_ );
}

sub off
{
   my $self = shift;

   $self->send( map { new X10::Event(sprintf("%s OFF", $_->address)) } @_ );
}

sub dim
{
   my $self = shift;
   $self->send( map { new X10::Event(sprintf("%s DIM", $_->address)) } @_ );
}

sub bright
{
   my $self = shift;
   $self->send( map { new X10::Event(sprintf("%s BRIGHT", $_->address)) } @_ );
}

sub lights_on
{
   my $self = shift;
   my %params = @_;
   $self->send( new X10::Event(
	sprintf("%s LIGHTS ON", $params{house_code} || $self->{house_code} )
	));
}

sub all_off
{
   my $self = shift;
   my %params = @_;
   $self->send( new X10::Event(
	sprintf("%s ALL OFF", $params{house_code} || $self->{house_code} )
	));
}

### semi-private methods

sub send
{
   my $self = shift;

   $self->queue_words(map {$_->compile} @_);
}

sub send_one
{
   my $self = shift;
   my $event = shift;		# this sub ONLY SENDS ONE
   $self->queue_words($event->compile);
}

### private stuff -- only to be called from me & derived modules

sub got_events
{
   my $self = shift;

   foreach (@_)
   {
      $self->got_event($_);
   }
}

sub got_event
{
   my $self = shift;
   my $event = shift;

   foreach (@{$self->{listeners}})
   {
      $_->($event);
   }
}

sub optimize_wordlist
{
   my $self = shift;

   my @words;

   OPTPASS:
   while (@_)
   {
      if (scalar @_ >= 4)
      {
         my ($hc0, $cm0) = $_[0] =~ /^(.)(..)$/;
         my ($hc1, $cm1) = $_[1] =~ /^(.)(..)$/;
         my ($hc2, $cm2) = $_[2] =~ /^(.)(..)$/;
         my ($hc3, $cm3) = $_[3] =~ /^(.)(..)$/;

         if (
		$_[1] eq $_[3]
		&& ( $cm1 eq 'OF' || $cm1 eq 'ON' )
		&& $hc0 eq $hc1
		&& $hc0 eq $hc2
		&& $cm0 =~ /^\d\d$/
		&& $cm2 =~ /^\d\d$/
		)
         {
            $self->{logger}->('info', "Opt 1: %s\n", join(" ", @_[0..3])) if $self->{debug};

            @_[0,1] = @_[1,0];
            shift;

            next OPTPASS;
         }
         elsif (
		$_[0] eq $_[2]
		&& $cm0 =~ /^\d\d$/
		&& $cm2 =~ /^\d\d$/	# 0 & 2 are identical addresses
		&& ( $cm1 eq 'OF' || $cm1 eq 'ON'
			|| $cm1 eq 'BR' || $cm1 eq 'DI' )
		)
         {
            $self->{logger}->('info', "Opt 2: %s\n", join(" ", @_[0..3])) if $self->{debug};
            shift;
            @_[0,1] = @_[1,0];

            next OPTPASS;
         }
      }

      if (scalar @_ >= 3)
      {
      }

      if (scalar @_ >= 2)
      {
         if ($_[0] eq $_[1])
         {
            $self->{logger}->('info', "Opt 3: %s\n", join(" ", @_[0..1])) if $self->{debug};
            shift;
            next OPTPASS;
         }
      }

      push @words, shift;
   }

   return @words;
}

sub queue_words
{
   my $self = shift;

   push @{$self->{output_word_queue}}, @_;

   @{$self->{output_word_queue}} = $self->optimize_wordlist(@{$self->{output_word_queue}});

   $self->work;
}

sub work
{
   my $self = shift;

   return if $self->{working};

   $self->{working} = 1;
   while (my $word = shift @{$self->{output_word_queue}})
   {
      $self->send_word($word);
   }
   $self->{working} = 0;
}

sub send_word
{
   my $self = shift;
   my $word = shift;
   $self->{logger}->('info', "Sending word: %s", $word) if $self->{verbose};
   $self->got_words($word);	# here's the fake-out since we're abstract
}

# this does all the state-machine stuff to keep track of what's going on...
# does NOT keep track of what devices are on/off
sub got_words
{
   my $self = shift;

   while ( my $word = shift )
   {

      if ($word =~ /^([a-p])(\d\d)$/i)		# got an address
      {
         my $hc = uc($1);
         my $uc = $2 * 1;

         unless (exists $self->{states}->{$hc})
         {
            $self->{states}->{$hc}->{mode} = 'addr';
            $self->{states}->{$hc}->{selected} = [];
         }

         if ($self->{states}->{$hc}->{mode} eq 'addr')
         {
            push @{$self->{states}->{$hc}->{selected}}, $uc;
         }
         elsif ($self->{states}->{$hc}->{mode} eq 'cmd')
         {
            $self->{states}->{$hc}->{mode} = 'addr';
            $self->{states}->{$hc}->{selected} = [ $uc ];
         }
         else
         {
            warn "Bleah: ", Dumper($self->{states});
         }
      }
      elsif ($word =~ /^([a-p])(on|of|di|br)$/i)	# got a cmd
      {
         my $hc = uc($1);
         my $cmd = uc($2);

         unless (exists $self->{states}->{$hc})
         {
            $self->{states}->{$hc}->{mode} = 'addr';
            $self->{states}->{$hc}->{selected} = [];
         }

         # use long versions
         $cmd = 'off' if $cmd eq 'OF';
         $cmd = 'dim' if $cmd eq 'DI';
         $cmd = 'bright' if $cmd eq 'BR';

         $self->{states}->{$hc}->{mode} = 'cmd';

         $self->got_events(
		map { new X10::Event(sprintf("%s%02s %s", $hc, $_, $cmd)) }
		unique { $_ }
		@{$self->{states}->{$hc}->{selected}}
		);
      }
      elsif ($word =~ /^([a-p])(a0|l1)$/i)	# got an 'all' cmd
      {
         my $hc = uc($1);
         my $cmd = uc($2);

         unless (exists $self->{states}->{$hc})
         {
            $self->{states}->{$hc}->{mode} = 'addr';
            $self->{states}->{$hc}->{selected} = [];
         }

         # use long versions
         $cmd = 'all off' if $cmd eq 'A0';
         $cmd = 'lights on' if $cmd eq 'L1';

         $self->{states}->{$hc}->{mode} = 'cmd';
         $self->{states}->{$hc}->{selected} = [];

         $self->got_events( new X10::Event(sprintf("%s %s", $hc, $cmd)) );
      }
      else
      {
         warn "Unknown word: ", $word;
      }
   }

}

###

sub unique (&@)
{
   my($c,%hash) = shift;
   grep { not $hash{&$c}++ } @_;
}



1;

