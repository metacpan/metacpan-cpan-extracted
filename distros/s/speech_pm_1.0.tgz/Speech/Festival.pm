package Speech::Festival;

$rcsId=' $Id: Festival.pm,v 1.1.2.1 1999/10/08 17:33:33 rjc Exp $ ';

 ###########################################################################
 #                                                                         #
 # Interface to festival server.                                           #
 #                                                                         #
 ###########################################################################

use strict "subs";
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
use Socket;


@ISA = qw(Exporter);
@EXPORT = qw(
	     );

# bootstrap Festival $VERSION;

$Speech::Festival::nextstream='festival00000';

$Speech::Festival::speech_error='';
*speech_error = *main::synth_error;
$Speech::Festival::end_key='ft_StUfF_key';

$Speech::Festival::OK='OK';
$Speech::Festival::ERROR='ER';
$Speech::Festival::SCHEME='LP';
$Speech::Festival::WAVE='WV';

sub new 
{
    my ($class, $host, $port) = @_;

    $host ||= 'localhost';
    $port ||= 1314;
    my ($self) = [ $host, $port, $Speech::Festival::nextstream++, {} ];

    return bless $self, $class;
}

sub conn
{
    my ($self) = @_;
    my ($host, $port, $s, $prop) = @$self;

    my($iaddr, $paddr, $proto);

    unless ($iaddr   = inet_aton($host))
	{
	$speech_error = "no host: $host - $!";
	return 0;
	}

    $paddr   = sockaddr_in($port, $iaddr);

    $proto   = getprotobyname('tcp');

    unless(socket($s, PF_INET, SOCK_STREAM, $proto))
	{
	$speech_error = "socket: $!";
	return 0;
	}

    unless(connect($s, $paddr))
	{
	$speech_error = "connect: $!";
	return 0;
	}

    my ($old) = select($s);
    $|=1;
    select($old);

    $prop{C}=1;

    return $s;
}

sub disconnect
{
    my ($self) = @_;
    
    my ($host, $port, $s, $prop) = @$self;

    if (defined($prop{C}) && $prop{C})
      {
	eval { local $SIG{PIPE} = 'IGNORE'; close($s); }
      }
    $prop{C}=0;
}

sub detach 
{
    my ($self) = @_;

    &DESTROY($self);

    bless $self, "destroyed Festival";
}

sub DESTROY
{
    my ($self) = @_;

    print "disconnect\n";
    disconnect $self;
}

sub request
{
    my ($self, $scheme, $handler, @info) = @_;
    my ($host, $port, $s) = @$self;

    print $s "$scheme\n";

    if (defined($handler))
	{
	return handle_results($s, $handler, @info);
	}
}

sub wait_for_result

{
    my ($self, $time) = @_;
    my ($host, $port, $s) = @$self;

    return waitforsomething($s, $time);
}

sub result_waiting

{
    my ($self) = @_;
    my ($host, $port, $s) = @$self;

    return waitforsomething($s, 0);
}

sub get_result

{
    my ($self) = @_;
    my ($host, $port, $s);

    if (ref($self))
	{
	($host, $port, $s) = @$self;
	}
    else
	{
	$s = $self;
	}

    my ($type) = '';

    if (myread_n($s, $type, 3) != 3)
	{
	$speech_error = "Error reading type - $!";
	return undef;
	}

    chomp $type;
    return ($type, 'void')
	if $type eq $OK || $type eq $ERROR;

    my ($data) = '';

    if (myread_upto($s, $data, $end_key) < 0)
	{
	$speech_error = "Error reading data - $!";
	return undef;
	}

    return ($type, $data);
}

sub handle_results
{
    my ($s, $handler, @info) = @_;
    my ($nres)=0;
    my ($state);

    while (1)
	{
	my ($type, $data) = get_result $s;
	
	if (!defined($type))
	    {
	    return undef;
	    }
	
	$state = &$handler($type, $data, @info);

	if ($type eq $OK)
	    {
	    $state=$nres;
	    last;
	    }
	elsif ($type eq $ERROR)
	    {
	    $state=-1;
	    last;
	    }
	$nres++;
	}
    return $state;
}

# simple look-ahead IO

$Speech::Festival::buffer='';
$Speech::Festival::bend=0;

sub waitforsomething
{
    my ($s, $time) = @_;

    if (length($buffer) > 0)
	{
	return 1;
	}

    my ($rin, $rout) = '';
    vec($rin, fileno($s), 1) = 1;

    return select($rout = $rin, undef, undef, $time);
}

sub myread_n
{
    my ($s, $b, $n) = @_;

    while ($bend < $n)
	{
	my ($nr) = sysread($s, $buffer, 1000-$bend, $bend);
	$bend += $nr
	    if defined($nr);
	}

    $_[1] = substr($buffer, 0, $n);
    $buffer = substr($buffer, $n);
    $bend -= $n;
    return $n;
}

sub myread_upto
{
    my ($s, $b, $key) = @_;

    my ($checkfrom, $keyat) = 0;

    while (($keyat=index($buffer, $key, $checkfrom)) <0)
	{
	$checkfrom = $bend-length($key)
	    if $bend > length($key);

	my ($nr) = sysread($s, $buffer, 10000, $bend);
	$bend += $nr;
	}

    $_[1] = substr($buffer, 0, $keyat);
    $buffer = substr($buffer, $keyat+length($key));
    $bend -= $keyat+length($key);
    return length($_[1]);
}

# parse scheme

$Speech::Festival::scheme_token = '^\\s*(("([^\\]"|[^"]|\s)*")|([-a-zA-Z0-9_+]+)|(\')|(\()|(\)))\\s*';

sub parse_scheme
  {
    my ($text) = @_;

    my ($scheme);

    if ($text eq '')
      {
	return (undef, "");
      }
    elsif ($text =~ /$scheme_token/om)
      {
	my ($tok, $str, $strcont, $atom, $sq, $open, $close, $tail) = 
	  ($1, $2, $3, $4, $5, $6, $7, $');

#	print "XXX", join("//", ($tok, $str, $strcont, $atom, $sq, $open, $close, $tail)), "\n";

	if (defined($str))
	  {
	    return ($str, $tail);
	  }
	elsif (defined($atom))
	  {
	    return ($atom, $tail);
	  }
	elsif (defined($sq))
	  {
	    my ($quoted, $ttail) = parse_scheme($tail);

	    return ([ 'quote', $quoted ], $ttail);
	  }
	elsif (defined($open))
	  {
	    my ($list) = [];

	    while (1)
	      {
		my ($item, $ttail) = parse_scheme($tail);

		$tail = $ttail;

		last
		  if !defined($item) || $item eq ')';

		push(@$list, $item);
	      }
	    
	    return ($list, $tail);
	  }
	elsif (defined($close))
	  {
	    return ($close, $tail);
	  }
      }

    return (undef, substr($text,1));
  }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Speech::Festival - Communicate with a festival server process.

=head1 SYNOPSIS

  use Festival;
  $festival = new Festival -host => 'serverhost', -port => 1314;

  conn $festival;
  disconnect $festival;

  request $festival '(some scheme)';
  request $festival '(some scheme)', \&result_handler, $args, $for, $handler;

  if (result_waiting $festival) { # process it }
  wait_for_result $festival, $timeout;
  ($type, $data) = get_result $festival;

=head1 DESCRIPTION

This package provides a simple interface to an instance of the
festival speech synthesis system running as a server on some
machine. If you want a simple speech-ouput module using this interface
see L<Speech::Synthesis>.

Since festival can return an unpredictable number of results from a
single request, and since it is useful to process them as they arrive,
something a little more complex than a simple remote-procedure-call
interface is needed.

There are basicly three ways to organise your application's
interaction with festival. In the simplest cases you can pass a result
handling procedure along with your request. For more control you can
process one value at a time by using L<result_waiting|/result_waiting>
to poll for results or L<wait for result|/wait_for_result> to block
until a result is available.

In any case results consist of a type and some data. The types are

=over 4

=item $Speech::Festival::SCHEME

The data is a Scheme expression, for instance a number or a list.

=item $Speech::Festival::WAVE

The data is a waveform. what format this is in willbe determined by
what you have previously told festival.

=item $Speech::Festival::OK

All the results for this request have been sent. No data.

=item $Speech::Festival::ERROR

Festival has reported an error. No data. Unfortunatly festival doesn't
sen any information about the error, so for details you will have to
check the server's log.

=back

A single festival session (between calls to L<conn|/conn> and
L<disconnect|/disconnect>) talks to a single Scheme interpreter in festival, and
hence state will be remembered between requests.

=over 4

=item $festival = B<new> Festival 'serverhost', 1314;

Create a new festival session which will connect to the given host and
port. If ommitted these default to I<localhost> and I<1314>.

=item   B<conn> $festival;

Connect to festival. Returns true if all is well, false otherwise. In
the event of an error the variable I<$speech_error> conatains a
description of it.

=item   B<disconnect> $festival;

Disconnect from festival. The connection mat be reopened later with
L<conn|/conn>, but any state will have been lost.

=item   B<request> $festival '(some scheme)';

Send the given Scheme to festival. You should use
L<result_waiting|/result_waiting>, L<wait_for_result|/wait_for_result>
and L<get_result|/get_result> to process the results of the request.

=item   B<request> $festival '(some scheme)', \&result_handler, $args, $for, $handler;

Send the given Scheme to festival asking it to call I<&result_handler>
on each result returned. The handler is called as: 

=back

	result_handler($type, $data, $args, $for, $handler)

=over 4

=item   if (B<result_waiting> $festival) { # process it }

Look to see if there are any results waiting to be processed. This
only guarantees that the start of the result has arrived, so a
subsequent call to L<get_result|/get_result> may not return instantly, but should
not block for an extended time.

=item   B<wait_for_result> $festival, $timeout;

Blocks until festival sends a result. Timeout is in seconds, if can be
omitted, in which case the call waits for an unbounded time. Returns
false if he call timed out, true if there is a request waiting. Again,
this only guarantees that a result has started to arrive.

=item   ($type, $data) = get_result $festival;

Reads a single result. 

=back

=head1 EXAMPLES

The code below does some arithmatic the hard way.

    use Speech::Festival;
    $festival = new Speech::Festival -host => 'festival-server.mynet';

    conn $festival 
	 || die "can't talk to festival - $speech_error";

    request $festival '(+ 123 456)', 
	    sub {
		my ($type, $data) = @_;

		print "Scheme Result=$data"
			if $type eq $Speech::Festival::SCHEME;
		print "ERROR!\n"
		        if $type eq $Speech::Festival::ERROR;
	    };

=head1 AUTHOR

Richard Caley, R.Caley@ed.ac.uk

=head1 SEE ALSO

L<Speech::Synthesis>, L<Speech::Festival::Synthesis>, perl(1), festival(1), Festival Documentation

=cut











