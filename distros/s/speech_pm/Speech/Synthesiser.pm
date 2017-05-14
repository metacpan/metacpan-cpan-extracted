
package Speech::Synthesiser;

$VERSION = '1.0';

use strict "subs";
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     );

*synth_error = *main::synth_error;

sub new 
{
    my ($class, %props) = @_;

    my ($type) = (defined($props{-type})
		  ? "Speech::$props{-type}::Synthesiser"
		  : "Speech::Dummy::Synthesiser");

    eval "use $type;"
      unless $type eq "Speech::Dummy::Synthesiser";

    die "$@"
      if $@;

    my ($self) = $type->new(\%props);

    my ($waveimp) = $props{-waveimp} || "Audio::FileWave";
    my ($waveargs) = $props{-waveargs} || [];

    wavetype $self $waveimp, @waveargs;

    $self;
}

sub set
  {
    my ($self, $key, $val) = @_;
  }

sub start
  {
    my ($self) = @_;
    
    0;
  }

sub stop
  {
    my ($self) = @_;

    0;
  }

sub wavetype
  {
    my ($self, $waveimp, @args) = @_;

    $self->set('WaveImp', $waveimp);
    $self->set ('WaveArgs', [@args]);
    
    eval "use $waveimp;";

    die $@
	if $@;

  }

sub voice_list 
  {
    my ($self) = @_;

    return ("default");
  }

sub voice
  {
    my ($self, $voice) = @_;
  }

sub voice_description
  {
    my ($self, $voice) = @_;
    return "Default voice."
  }

sub speak
  {
    my ($self, $text) = @_;

    print STDOUT "Imagine I just said '$text'\n";
    return 1;
  }

sub synth_description
  {
    my ($self) = @_;

    print STDOUT "This is some synthesiser or other.\n";

    return 1;
}

package Speech::Dummy::Synthesiser;

@ISA=( "Speech::Synthesiser" );

sub new
  {
    my ($class, @args) = @_;

    $self = [];

    bless $self, $class;
  }

sub start 
  {
    return 1;
  }


1;

__END__

=head1 NAME

Speech::Synthesiser - Generic speech syntheiser interface

=head1 SYNOPSIS

  use Speech::Synthesiser;
  $synth = new Speech::Synthesiser 
		-type => 'SynthName',
                # other args
		;

  start $synth;
  stop $synth;

  @voices = voice_list $synth;
  voice $synth "myvoice";

  intro $synth;
  speak $synth $text;

=head1 DESCRIPTION

L<Speech::Synthesiser> provides a simple way to add speech to a perl
application. It is a generic class which can be used to talk to any
speech synthesiser given a suitable interface module.

Actual sound output is provided by an auiliary class, by default
L<Audio::FileWave> which runs an external program to play sound,
but you can replace it with another class if you have a better way of
playing sounds (eg a perl extension providing sound output), see the
documentation for L<Speech::FileWave> for the interface an
alternative should provide should implement.

If you do use L<Speech::FileWave> you may need to set up the command
it uses to play sounds, see the documentation for
L<Audio::FileWave/set_play_command>.

=over 4

=item $synth = B<new> Speech::Synthesiser -type => 'SynthName', ARGS;

Create a synthesiser of the named type. Looks for a package
C<Speech::SynthName::Synthesiser>. All arguments are passed to the
creation function for that class.

The following arguments have special meaning to the
C<Speech::Synthesiser> C<new> method.

=over 4

=item -waveimp CLASS

CLASS is the name of a perl package which implements wave
playing. If not given it defaults to C<Audio::FileWave>.

=item -waveargs [ @ARGS ]

@ARGS are passed to the C<new> method of the wave class. For
C<Audio::FileWave> this defaults to C<( "riff" )>.

=back

=item B<start> $synth;

Do whatever is ncecessary to prepar ethe synthesiser fo work. Returns
true if all is well, false otherwise. In the event of an error the
variable I<$synth_error> conatains a description of it.

=item B<stop> $synth;

Close down the synthesiser, releasing any resources it holds. The
synthesiser may be restarted with L</start>, but any state may
have been lost.

=item @voices = B<voice_list> $synth;

Return a list of the voices available from this synthesiser.

=item B<voice> $synth "myvoice";

Select a voice.

=item B<voice_description> $synth;

Returns a description of the voice.

=item B<synth_description> $synth;

Synthesize a description of the synthesiser,

=item B<speak> $synth $text;

Speak the given text. Not much more to be said really:-).

=back

=head1 EXAMPLE

The following should talk to you, all else being equal. Uses the
festival synthesiser, so you will need to run a festival server on the
named machine.

    use Speech::Synthesiser;

    $synth = new Speech::Synthesiser 
		-type => 'Festival',
		-host => 'festival-server.mynet';

    start $synth 
	 || die "can't talk to festival - $synth_error";

    speak $synth "We are perl, prepare for assimilation.";

=head1 AUTHOR

Richard Caley, R.Caley@ed.ac.uk

=head1 SEE ALSO

L<Speech::Festival>, L<Speech::Festival::Synthesiser>,
L<Audio::FileWave>, perl(1), festival(1), Festival Documentation

=cut


