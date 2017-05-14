

package Audio::FileWave;

$Audio::FileWave::tmpname="/tmp/${$}fwv0000000";

%Audio::FileWave::command
    = (
       "DEFAULT" => "na_play WAVE"
       );

sub import
{
    my ($class) = @_;
}

sub new
{
    my ($class, $data, $type) = @_;
    my ($file) = $tmpname++;

    $type ||= 'riff';

    my ($self) = [$file, $type];

    local(*WV);

    open(WV, ">$file") ||
	return "can't write to $file - $!";

    syswrite(WV, $data, length($data));

    close(WV);

    bless $self, $class;
}

sub set_play_command
{
    my ($class, $type, $command) = @_;

    $command{$type} = $command;
}

sub free
{
    my ($self) = @_;

    &DESTROY($self);

    bless $self, "Freed ".ref($self);
}

sub DESTROY
{
    my ($self) = @_;
    my ($file) = @$self;
    unlink($file);

}


sub play
{
    my ($self) = @_;
    my ($file, $type) = @$self;

    my ($command) = $command{$type};
    $command = $command{DEFAULT}
       unless defined($command);

    $command =~ s/WAVE/$file/g;

    system($command);
}

1;

__END__

=head1 NAME

Audio::FileWave - Simple waveform abstraction for use with Audio::TTS

=head1 SYNOPSIS

    $wave = new Audio::FileWave $type, $data;

    set_play_command Audio::FileWave $type $command;

    play $wave;

    free $wave;

=head1 DESCRIPTION

This is a simple class which represents a waveform. It is designed for
use by the L<Festival::TTS|Festival::TTS> module, if you want to play waveforms some
other way you need to supply another class which implements this
interface.

This class maintains a table mapping file types to play commands. When the
command is called the string `I<WAVE>' is replaced by the filename of
the data. If you don't set up a command for the waveform type
L<Festival::TTS|Festival::TTS> requests, the default command `I<na_play WAVE>' is
used. The L<na_play|na_play> command is part of the I<Edinburgh Speech Tools> and
so if you have festival you should also have it.

=over 4

=item B<set_play_command> Festival::FileWave $type $command;

Sets the play command to be used for files of the given type. 

=item  $wave = B<new> Festival::FileWave $type, $data;

Create a waveform from the given data which is of type $type. Actually
saves it to a file.

=item B<free> $wave;

Free the resources used for the waveform. (unlinks the file).

=item B<play> $wave;

Play the waveform. Calls the command associated with the file type. 

=back

=head1 AUTHOR

Richard Caley, R.Caley@ed.ac.uk

=head1 SEE ALSO

L<Festival::TTS>, perl(1), festival(1), Festival Documentation

=cut
