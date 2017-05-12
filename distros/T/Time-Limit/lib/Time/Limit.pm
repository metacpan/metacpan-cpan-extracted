package Time::Limit;

use 5.006;
use strict;
use warnings;

BEGIN {
	$Time::Limit::AUTHORITY = 'cpan:TOBYINK';
	$Time::Limit::VERSION   = '0.003';
}

use Carp qw( carp );
use Time::HiRes qw( time usleep );

sub import
{
	shift;
	
	my %opts;
	while (@_ and $_[0] =~ /^-(.+)$/) {
		shift;
		$opts{ $1 }++;
	}
	
	my $start  = time;
	my $limit  = $_[0] || 10;
	my $parent = $$;
	
	if ( !!! fork )
	{
		my $finish = $start + $limit;
		while ( 1 )
		{
			usleep 1;
			
			# Long running parent process
			if ( time > $finish )
			{
				carp("Process $parent timed out!") unless $opts{quiet};
				
				my $counter = 2_000_000;
				
				# While we can still reach the parent process
				while ( kill(0, $parent) )
				{
					# Send it a signal to end
					my $signal = ($counter > 1_000_000) ? 'TERM' : 'KILL';
					$signal = -$signal if $opts{group};
					carp("Sending $signal to $parent") unless $opts{quiet};
					kill($signal, $parent);
					
					# Sleep for progressively less time between kill signals
					usleep $counter;
					$counter -= 250_000;
					$counter = 250_000 if $counter < 250_000;
				}
				
				exit(252);
			}
			
			# Parent process seems to have ended by itself
			elsif ( not kill(0, $parent) )
			{
				carp("Process $parent did not time out") if $opts{verbose};
				# Nothing more to do
				exit;
			}
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Time::Limit - kill your broken Perl script

=head1 SYNOPSIS

   use strict;
   use warnings;
   use Time::Limit '0.5';
   
   while (1) {
      print "infinite loop\n";
   }

=head1 DESCRIPTION

It is oh so very easy to accidentally write a Perl script that dives
straight into an infinite loop, or stumbles into a runaway recursion.
In most cases, you can hit C<< Ctrl + C >> and get on with the job of
figuring out what went wrong. However, if you're not running the
process in a local terminal (e.g. you're running it over a slow SSH
connection, or not in a terminal at all), these processes might be
tricky to kill.

The Time::Limit module starts a monitor process that shadows your
script's execution, and kills it off if your script has overrun its
allotted time limit. Because Time::Limit is global in effect its use
in modules is discouraged. Instead, use it only in your main script,
or pass it as a parameter to Perl on the command line:

   perl -MTime::Limit myscript.pl

The syntax for using Time::Limit is:

   use Time::Limit @flags, $limit;

Flags are strings prefixed with a hyphen. The following flags are
supported:

=over

=item C<< -group >>

Send the signal to your script's process group instead of its
individual process number. That is, your script and any child
processes started with C<fork> will be killed.

=item C<< -quiet >>

Kill the script quietly.

=item C<< -verbose >>

Output extra debugging information.

=back

The C<< $limit >> is a number indicating the time in seconds
before your script gets killed. It does not have to be an integer.
It defaults to a very generous 10.

Be careful to avoid triggering Perl's C<< use MODULE VERSION >>
syntax.

   use Time::Limit -verbose, 4.0;  # yep, kill after 4 seconds
   use Time::Limit '4.0';          # yep, kill after 4 seconds
   use Time::Limit 4.0;            # nah, want $VERSION==4.0

After C<< $limit >> is reached, Time::Limit will try signalling your
script to terminate cleanly (SIGTERM) a few times; if that fails,
it will become more aggressive and send SIGKILL signals until it
receives word of your script's timely death.

Some random examples using Time::Limit from the command-line:

   perl -MTime::Limit=-quiet,4 myscript.pl
   perl -MTime::Limit=-group,-verbose,4.1 myscript.pl
   perl -MTime::Limit=3 myscript.pl

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Time-Limit>.

=head1 SEE ALSO

L<Time::Out> - this allows you to apply a timeout to an individual
block of code, and then gracefully carry on.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

