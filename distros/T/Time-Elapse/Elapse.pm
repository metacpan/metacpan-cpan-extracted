package Time::Elapse;

require 5.006;
use strict;
use warnings;
use autouse 'Carp' => qw(confess);
use POSIX qw/ strftime /;
use Time::HiRes qw/ gettimeofday /; 

# localtime and gmtime seem to be reversed
# across different OS's (MacPerl, Darwin Perl, linux Perl)
# perhaps my install of Perl is broken? setting local TZ to
# UTC seems to resolve this but it *should not be necessary!*

our $VERSION = 1.24_02;
our $_DEBUG = 0;

sub TIESCALAR
{
	local $ENV{TZ} = 'UTC';# ridiculous! shouldn't be necessary.
	my( $class, $val ) = @_;
	$val = "" unless defined($val); 

	confess "Elapse->lapse() unable to use referenced values"
	  if ref($val); 

	bless { now => [gettimeofday()], val => $val }, $class;
}

sub FETCH
{
	local $ENV{TZ} = 'UTC';# ridiculous! shouldn't be necessary.
	my ( $impl, $val ) = @_;
	my ($time, $ms) =  gettimeofday();

	print "(\$time = $time, \$ms = $ms)\n" 
		if $_DEBUG;

	if ( $ms < $impl->{now}[1] ) 
	{
		$time--; 
		$ms += 1000000; 
	}

	print "changed? (\$time = $time, \$ms = $ms) [ $impl->{now}[1] ]\n" 
		if $_DEBUG;

	my $float = sprintf("%06d", $ms - $impl->{now}[1]);
	print "Float = $float\n" 
		if $_DEBUG;

	my $int = strftime( "%H:%M:%S", localtime( $time - $impl->{now}[0] ) );

	print <<"EOF" if $_DEBUG;
	# int = $int
	# Time = $time
	# IMPL = $impl->{now}[0]
	# Time - IMPL = @{[ $time - $impl->{now}[0] ]}
	# localtime = @{[ localtime($time - $impl->{now}[0]) ]}
EOF

	$val =  $impl->{val} eq "" ? "" : " [$impl->{val}]";

	return "$int.$float" . $val;
}

sub STORE
{
	local $ENV{TZ} = 'UTC';# ridiculous! shouldn't be necessary.
	my($impl, $val) = @_;
	$val = "" unless defined($val);

	confess "Elapse->lapse() unable to use referenced values"
	  if ref($val); 

	$impl->{now} = [gettimeofday()];
	$impl->{val} = $val;
}


sub lapse
{
	tie $_[1], $_[0], $_[1];
}

1;

__END__

=pod

=head1 NAME

Time::Elapse - Perl extension for monitoring time conveniently during tasks

=head1 DESCRIPTION

Time::Elapse is a very simple class with one method: lapse.


Basically, the lapse method 'eats the brains' of the variable,
squirrels away whatever value it may have held internally,
(much like space aliens are known to do in the movies), and also stores 
the current time within it. Then, whenever you access the value of 
the variable, the 'alien' within formats the time differential 
between when you initialized the variable, and when you printed it, 
and returns that (along with any value the variable may hold, as well). :-) 
Every time you print it, you get the updated differential, returned by 
the method hidden inside the variable itself. The output will be formatted 
as HH:MM:SS.000000 [in Microseconds].


Frankly it doesn't do much more than time(), but then again the simplest 
things rarely do. :-)


All it really does is hides the calculations that anyone else would have had 
to set up manually in a clever way and then produce a reasonably formatted 
output which lends itself equally well to single-line output or inlining with
other text.

=head1 SYNOPSIS

=head2 Usage


To use Elapse is simplicity itself:

    use Time::Elapse;

    # somewhere in your program...
    Time::Elapse->lapse(my $now); 
    # or you can do:
    # Time::Elapse->lapse(my $now = "processing");

    #...rest of program execution

    print "Time Wasted: $now\n";

To update the description and reset the time counter mid-stream, simply 
assign to the variable

    $now = "parsing";

somewhere in the middle of the program. The new value is stored, while 
the original time is replaced with the current time.


=head2 Sample Output


Output looks something like this, using above code:

    Time Wasted: 00:00:05.565763
  or
    Time Wasted: 00:00:03.016700 [processing]
    (more output)
    Time Wasted: 00:00:02.003764 [parsing]


=head2 Additional example code


You can also use this during a Net::FTP download loop of files to show 
elapsed time for each file's download. 

  foreach my $file (@files_to_download) 
  {
    # extract localfile name from $file
    # ...
    Time::Elapse->lapse(my $now = "Downloading $localfile.");
    $ftp->get($file, $localfile) or carp("### Could not download $file! $!") and next;
    print "Done. Elapsed : $now\n";
    # ...
  }

This can also be a useful trick when you're processing a lot of data from multiple sources. 


=head1 'BUGS'

Elapse offers time granularity smaller than 1 second, but values are approximate since 
the accuracy is slightly hampered by the virtue of the process itself taking somewhere 
roughly around 0.00001 - 0.0009 seconds. (depending on the system and how many 
processes are running at the time. :-) 

    #!/usr/bin/perl
    use Time::Elapse;
    Time::Elapse->lapse(my $now = "testing 0");
    for (1 .. 5)
    {
        print "$now\n";
        $now = "testing $_";
    }
    print "$now\n";

   (results from a PowerMac G3/400 running MacPerl 5.004
    on MacOS 8.6)
    00:00:00.000937 [testing 0]
    00:00:00.000743 [testing 1]
    00:00:00.000344 [testing 2]
    00:00:00.000327 [testing 3]
    00:00:00.000358 [testing 4]
    00:00:00.000361 [testing 5]

   (results from an AMD Duron 1.1Ghz running Perl 5.8.0
    on RedHat Linux 8.0)
    00:00:00.000079 [testing 0]
    00:00:00.000035 [testing 1]
    00:00:00.000018 [testing 2]
    00:00:00.000016 [testing 3]
    00:00:00.000016 [testing 4]
    00:00:00.000020 [testing 5]

=head1 EXPORT

None by default.


=head1 AUTHOR

=head2 Author

Scott R. Godin, C<E<lt>mactech@webdragon.netE<gt>>

=head2 Last Update

Fri Aug  8 01:12:56 EDT 2003

=head1 COPYRIGHT

Copyright (c) 2001 Scott R. Godin. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

L<Time::HiRes>.

=cut
