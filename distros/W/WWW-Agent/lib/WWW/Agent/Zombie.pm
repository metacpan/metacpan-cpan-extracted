package WWW::Agent::Zombie;

use strict;
use warnings;

use Data::Dumper;
use POE;

=pod

=head1 NAME

WWW::Agent::Zombie - Walking through websites like a zombie

=head1 SYNOPSIS

  use WWW::Agent::Zombie;
  my $z = new WWW::Agent::Zombie ();
  $z->run (q{...
           # some WeeZL here
           });

=head1 DESCRIPTION

This package provides a way to let zombies stalk the earth. Seriously,
a plan (written in WeeZL, a simple text language, see
L<WWW::Agent::Plugins::Director>) controls a L<WWW::Agent> object.

=head1 INTERFACE

=head2 Constructor

The constructor expects a hash with the following key/value pairs:

=over

=item C<functions> (hash reference, optional):

In a WeeZL script you can refer to functions which you can provide
here.  The keys are the names of the functions as the can appear in
the WeeZL script, as values you have to pass in subroutine references.

When such a subroutine is invoked, it will get the current context as
parameter. See L<WWW::Agent::Plugins::Director> for details.

Example:

   my $zombie = new WWW::Agent::Zombie (functions => {
                                            'test' => sub {
                                                  warn "here I am";
                                                  }
                                            'test2' => sub {
                                                  warn "and again";
                                                  },
                                                      });

=item C<time_dither> (string, percentation number, optional)

In WeeZL scripts you can ask the agent to pause for a time interval.
If you specify there C<~ 4 secs> (wait for approximately 5 seconds),
then the time dither factor controls, what I<approximately> means.

In case of C<20%>, the actual waiting time will randomly range from 4
to 6 seconds.

The default is C<10%>.

=back

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    my $self    = bless {}, $class;

    $self->{functions}   = delete $options{functions}   || {};
    $self->{time_dither} = delete $options{time_dither} || '10%';
#    die "unsupported dithering spec '".$self->{time_dither}."'" unless $self->{time_dither} =~ /^(\d+)\%$/;
#    $self->{time_dither} = $1;
    $self->{ua}          = delete $options{ua};

    use WWW::Agent;
#	use WWW::Agent::Plugins::LWP;
    use WWW::Agent::Plugins::Focus;
#    use WWW::Agent::Plugins::History;
    use WWW::Agent::Plugins::Director;
    new WWW::Agent (ua      => $self->{ua},
		    plugins => [
#							    new WWW::Agent::Plugins::LWP,
				new WWW::Agent::Plugins::Focus,
#				new WWW::Agent::Plugins::History (length => 10),
				new WWW::Agent::Plugins::Director (time_dither => $self->{time_dither},
								   functions   => $self->{functions},
								   exception   => sub { $self->{exception} = shift; }),
				]);
    return $self;
}

=pod

=head2 Methods

=over

=item C<run>

This method expects a string with a script written in WeeZL. If that
is missing, the default

   die "no plan to run"

will be used. Once this executes, obviously we return with an exception.

The method will not return until the WeeZL script has terminated. Any
infinite loop there will be exactly that. If the WeeZL script contains
execptions, these will be caught and re-raised into your application.

Example:

   $zombie->run (q{
		 goto http://www.example.org/
		 wait ~ 15 secs
		 goto http://www.example.org/login.php
                 });

=cut

sub run {
    my $self = shift;
    my $plan = shift || q|die "no plan to run"|;

    POE::Kernel->post ( 'agent', 'director_execute', 'zombie', $plan );
    POE::Kernel->run  ();

    die $self->{exception} if $self->{exception};                      # if POE ended with an exception, we raise it here
}

=pod

=back

=head1 AUTHOR

Robert Barta, E<lt>rho@bigpond.net.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

our $VERSION  = '0.04';
our $REVISION = '$Id: Zombie.pm,v 1.2 2005/03/19 05:08:17 rho Exp $';

1;

__END__



