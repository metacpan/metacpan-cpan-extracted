use Speech::Festival;

package Speech::Festival::Synthesiser;

use strict "subs";
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     );

@ISA = qw(Speech::Festival);

sub new 
{
    my ($class, $args) = @_;

    my ($host) = $$args{-host} || "localhost";
    my ($port) = $$args{-port} || 1314;

    my ($self) = Speech::Festival->new($host, $port);

    bless $self, $class;
}

sub set
  {
    my ($self, $key, $val) = @_;
    my ($host, $port, $s, $props) = @$self;
    $$props{$key} = $val;
  }

sub start
  {
    my ($self) = @_;
    my ($host, $port, $s, $props) = @$self;
    
    my ($res) = Speech::Festival::conn($self);

    print "connected\n";
    
    if ($res)
      {
	request $self "(Parameter.set 'Wavefiletype 'riff)", \&shandler;
	request $self "(tts_return_to_client)", \&shandler;
      }
    
    $res;
  }

sub stop
  {
     my ($self) = @_;
     Speech::Festival::disconnect($self);
  }

sub wavetype
  {
    my ($self, $waveimp, @args) = @_;

    if ($waveimp eq 'Audio::FileWave' && $#args < 0)
      {
	@args = ("riff");
      }

    $self->set('WaveImp', $waveimp);
    $self->set('WaveArgs', [@args]);
    
    eval "use $waveimp;";

    die $@
	if $@;

  }

sub voice_list 
  {
    my ($self) = @_;

    my (@res) = ();

    request $self "(voice.list)", \&ret_lp_handler, \@res;

    my ($scheme) = Speech::Festival::parse_scheme($res[0]);

    # @res = split(/\s+/, ($res[0] =~ /\(\s*(.*?)\s*\)/)[0]);

    return @$scheme;
  }

sub voice
  {
    my ($self, $voice) = @_;

    return request $self "(voice_$voice)", \&shandler;
  }

sub voice_description
  {
    my ($self, $voice) = @_;
    
    my ($res) = [];

    request $self "(voice.description '$voice)", \&ret_lp_handler, $res;

    return Speech::Festival::parse_scheme($$res[0]);
  }

sub speak
{
    my ($self, $text) = @_;
    my ($host, $port, $s, $props) = @$self;

    my ($imp, $args) = ( 
			$$props{WaveImp},
			$$props{WaveArgs}
		       );

    $text =~ s/\\/\\\\/g;
    $text =~ s/"/\\"/g;

    my ($scheme) = '(tts_text "' . $text . '" "text")';

    my ($n) = request $self $scheme, \&whandler, $imp, $args;

    $n--
      if $n>0;

    return $n;
}

sub synth_description
{
    my ($self) = @_;
    my ($host, $port, $s, $props) = @$self;

    my ($imp, $args) = ( 
			$$props{WaveImp},
			$$props{WaveArgs}
		       );

    my ($n) = request $self '(intro)', \&whandler, $imp, $args;

    $n--
      if $n>0;

    return $n;
}


sub shandler
{
    my ($type, $data, @info) = @_;

    chomp $data;
    print "shandler got $type:",substr($data,0,10),"\n"
      if defined($main::verbose) && $main::verbose>0;
}

sub whandler
{
    my ($type, $data, $imp, $args) = @_;

    chomp $data;
    print "whandler got $type:",substr($data,0,10),"\n"
      if defined($main::verbose) && $main::verbose>0;

    if ($type eq $Speech::Festival::WAVE)
	{
	my ($wave) = $imp->new($data, @$args);

	play $wave;
	}
}

sub ret_lp_handler
{
    my ($type, $data, $res) = @_;

    chomp $data;
    print "ret_lp_handler got $type:",substr($data,0,10),"\n"
      if defined($main::verbose) && $main::verbose>0;

    if ($type eq $Speech::Festival::SCHEME)
	{
	  push(@$res, $data);
	}
}
1;

__END__

=head1 NAME

Speech::Festival::Synthesiser - Simple text-to-speech using festival.

=head1 SYNOPSIS

  use Speech::Speech::Festival::Synthesiser;
  $festival = new Speech::Festival::Synthesiser 'serverhost', 1314;

  start $festival;
  stop $festival;

  @voices = voice_list $festival;
  voice $festival "myvoice";
  voice_description $festival;

  synth_description $festival;
  speak $festival $text;

=head1 DESCRIPTION

L<Speech::Festival::Synthesiser> provides a simple way to add speech
to a perl application. It is a sub-class of L<Speech::Festival> and so
you can use any of the methods in that class to manipulate festival if
necessary.

This package conform to the interface defined by
L<Speech::Synthesiser> and so provides a synthesiser for use throughthat interface.

Actual sound output is provided by an auiliary class, by default
L<Audio::FileWave> which runs an external program to play sound,
but you can replace it with another class if you have a better way of
playing sounds (eg a perl extension providing sound output), see the
documentation for L<Audio::FileWave> for the interface an
alternative should provide should implement.

If you do use L<Audio::FileWave> you may need to set up the command
it uses to play sounds, see the documentation for
L<Audio::FileWave/set_play_command>.

=over 4

=item $festival = B<new> Speech::Festival::Synthesiser -host => 'serverhost', -port => 1314, ...

Create a new festival session which will connect to the given host and
port. If ommitted these default to I<localhost> and I<1314>. 

=item B<start> $festival;

Connect to festival and inistilise the session. Returns true if all is
well, false otherwise. In the event of an error the variable
I<$festival_error> conatains a description of it.

=item B<stop> $festival;

Disconnect from festival. The connection may be reopened later with
L</start>, but any state will have been lost.

=item @voices = B<voice_list> $festival;

Return a list of the voices available from this server.

=item B<voice> $festival "myvoice";

Select a voice.

=item B<voice_description> $festival;

Returns the description of the current voice.

=item B<synth_description> $festival;

Synthesize the standard festival introductory text.

=item B<speak> $festival $text;

Speak the given text.

=back

=head1 AUTHOR

Richard Caley, R.Caley@ed.ac.uk

=head1 SEE ALSO

L<Speech::Synthesiser>, L<Speech::Festival>, L<Audio::FileWave>, perl(1), festival(1), Festival Documentation

=cut


