package VideoLan::Client;

use warnings;
use strict;
use Net::Telnet;

=head1 NAME

VideoLan::Client - interact with VideoLan Client using telnet connection

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';


=head1 SYNOPSIS

C<use VideoLan::Client;>

see METHODS section below

=head1 DESCRIPTION

VideoLan::Client allows you to lauchn vlc and control it using vlc connections. VideoLan::Client offer simple I/O methods.
VideoLan::Client require Net::Telnet.

=head1 METHODS

In the calling sequences below, square brackets B<[]> represent
optional parameters.

=over 4

=item B<new> - create a new VideoLan::Client object

    $obj = new VideoLan::Client();
    $obj = new VideoLan::Client ([HOST => $host,]
                    [PORT => $port,]
                    [TIMEOUT => $timeout,]
                    [PASSWD => $passwd,]
                    [DEBUG => $debug_file,]
                    );

This is the constructor for VideoLan::Client objects.

=back

=cut

sub new {
    my $class = shift;
    my $self = {};
    my %args;
    
    if(@_){
        (%args) =@_; 
    }
    $self->{HOST}    = 'localhost';
    $self->{PORT}    = '4212';
    $self->{TIMEOUT} = 10;
    $self->{PASSWD}  = 'admin';
    $self->{DEBUG} = undef;
    $self->{TELNET}  = undef;
    
    foreach (keys (%args)){
        $self->{$_} = $args{$_};
    }
    
    bless ($self, $class);
    return $self;
}

=over 4

=item host 

The default I<host> is C<"localhost">

=back

=cut

sub host {
    my $self = shift;
    if (@_) { $self->{HOST} = shift }
    return $self->{HOST};
}

=over 4

=item port

The default I<port> is C<4212>

=back

=cut

sub port {
    my $self = shift;
    if (@_) { $self->{PORT} = shift }
    return $self->{PORT};
}

=over 4

=item timeout

The default I<timeout> is C<10> secondes

=back

=cut

sub timeout  {
    my $self = shift;
    if (@_) { $self->{TIMEOUT} = shift }
    return $self->{TIMEOUT};
}

=over 4

=item passwd

The default I<passwd> is C<admin> secondes

=back

=cut

sub passwd {
    my $self = shift;
    if (@_) { $self->{PASSWD} = shift }
    return $self->{PASSWD};
}

=over 4

=item debug 

The default I<debug> is undef.
if debug is set to $file, $file will contains the telnet connection log.
debug have to be set before the B<login> method

=back

=cut

sub debug {
    my $self = shift;
    if (@_) { $self->{DEBUG} = shift }
    return $self->{DEBUG};
}

=over 4

=item B<login> - Initiate the connection with vlc

    $val = $ojb->login;

If succed return 1, else return 0.

=back

=cut

sub login {
    my $self = shift;
    my $retour;
    $self->{TELNET} = new Net::Telnet (Timeout => $self->{TIMEOUT}, Prompt => "/> /", Port => $self->{PORT}, Errmode    => 'return');
    if(defined($self->{DEBUG})) {
        $self->{TELNET}->input_log($self->{DEBUG});
    }
    return 0 if (!$self->{TELNET}->open($self->{HOST}));
    return 0 if (!$self->{TELNET}->waitfor("/Password:/"));
    return 0 if (!$self->{TELNET}->put($self->{PASSWD} . "\n"));
    return 0 if (!$self->{TELNET}->waitfor("/> /"));
    return 1;
}

=over 4

=item B<logout> - Close the connection with vlc

    $obj->logout;

=back

=cut

sub logout {
    my $self = shift;
    $self->{TELNET}->put("exit\n");
    $self->{TELNET}->close;
}

=over 4

=item B<shutdown> - Stop the vlc and close the connection.

    $obj->shutdown;

=back

=cut

sub shutdown {
    my $self = shift;
    $self->{TELNET}->put("shutdown\n");
    $self->{TELNET}->close;
}

=over 4

=item B<cmd> - lauchn a command to vlc and return the output

    @val = $obj->cmd('commande');

=back

=cut

sub cmd {
    my $self = shift;
    my $cmd = shift;
    my @retour = $self->{TELNET}->cmd($cmd . "\n");
    #~ $self->{TELNET}->waitfor("/> /");
    return @retour;
}

=over 4

=item B<add_broadcast_media> - add a broadcast media to vlc

    $obj->add_broadcast_media($name,$input,$output);

input and output use the syntaxe of vlc input/output

=back

=cut

sub add_broadcast_media {
    my $self = shift;
    my ($name,$input,$output) = @_;
    $self->cmd('new ' . $name . ' broadcast enabled');
    $self->cmd('setup ' . $name . ' input ' . $input);
    $self->cmd('setup ' . $name . ' output ' . $output);
}

=over 4

=item B<load_config_file> - load on config file in vlc

    $obj->load_config_file($file)

=back

=cut

sub load_config_file {
    my $self = shift;
    my $file = shift;
    $self->cmd('load ' . $file);
}

=over 4

=item B<save_config_file> - save the running config on a file

    $obj->save_config_file($file)

=back

=cut

sub save_config_file {
    my $self = shift;
    my $file = shift;
    $self->cmd('save ' . $file);
}

=over 4

=item B<media_play> - Play a media

    $obj->media_play($name)

=back

=cut

sub media_play {
    my $self = shift;
    my $media = shift;
    $self->cmd('control ' . $media . ' play');
}

=over 4

=item B<media_stop> - Stop playing a media

    $obj->media_stop($name)

=back

=cut

sub media_stop {
    my $self = shift;
    my $media = shift;
    $self->cmd('control ' . $media . ' stop');
}



=over 4

=item B<launchvlc> - lauchn a vlc with telnet interface

    $val = lauchnvlc;

Work only if the host is C<localhost>. Will only work on *NIX where nohup commande exist and vlc command is in path. lauchnvlc method is not support actually, just in test.

=back

=cut

sub launchvlc {
    my $self = shift;
    if($self->{HOST} eq 'localhost'){
        my $cmd = 'nohup vlc --intf telnet --telnet-port ' . $self->{PORT} . ' --telnet-password ' . $self->{PASSWD} . ' >/dev/null &';
        my $retour = system($cmd);
        sleep 2;
        return $retour;
    }else{
        return 0;
    }
}
=head1 SEE ALSO

=over 2

=item VLC : VideoLan Client

S<http://www.videolan.org/>

=item Net::Telnet

S<http://search.cpan.org/~jrogers/Net-Telnet-3.03/lib/Net/Telnet.pm>

=back

=head1 EXAMPLES

This example connect to a running vlc, lauchn the help commande and logout.

    use VideoLan::Client;
    my $vlc = VideoLan::Client->new( HOST =>'192.168.1.10', PORT => '35342', PASSWD => 'mdp_test');
    $vlc->login();
    my @help = $vlc->cmd("help");
    $vlc->logout();

This example connect to a running vlc and shutdown it

    use VideoLan::Client;
    my $vlc = VideoLan::Client->new( PASSWD => 'mdp_test');
    $vlc->login;
    my @help = $vlc->shutdown;
    $vlc->logout;

=head1 SEE ALSO

=over 2

=item VLC : VideoLan Client

S<http://www.videolan.org/>

=item Net::Telnet

S<http://search.cpan.org/~jrogers/Net-Telnet-3.03/lib/Net/Telnet.pm>

=back

=head1 AUTHOR

Cyrille Hombecq, C<< <elliryc at cpan.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-videolan-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VideoLan-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VideoLan::Client

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VideoLan-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VideoLan-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VideoLan-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/VideoLan-Client>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Cyrille Hombecq, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of VideoLan::Client
