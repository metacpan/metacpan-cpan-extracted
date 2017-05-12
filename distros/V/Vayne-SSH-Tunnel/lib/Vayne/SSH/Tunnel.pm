package Vayne::SSH::Tunnel;

use strict;
use 5.008_005;

our $VERSION = '0.01';

use POSIX;
use YAML::XS;
use File::Spec;
use Sys::Hostname;
use FindBin qw($Bin);
use Fcntl qw( :flock );
use Net::EmptyPort qw(empty_port);

sub Run
{
    my(%option, $cmd, $lport) = @_;

    $lport = empty_port();
    $cmd = _fmt_ssh(%option, lport => $lport );

    die "can not find user $option{user}" unless my(undef, undef, $uid, $gid) = getpwnam $option{user};

    POSIX::setgid($gid);
    POSIX::setuid($uid);
    print $cmd, "\n";

    #fork
    setpgrp(0,0);
    $SIG{TERM} = $SIG{HUP} = sub{ print "Sig recv, killed!\n";      kill 'KILL', -$$};
    $SIG{ALRM} =             sub{ print "Alarm timeout, killed!\n"; kill 'KILL', -$$};

    my($pid, %grep, $lock_fh) = open my $fh, "$cmd|" or die "can't fork cmd $cmd";

    alarm $option{timeout} if $option{timeout};

    #read
    $|++;
    
    READ:  while(my $line = <$fh>)
    {
        alarm 0;
        print $line;

        #write conf
        if( $line =~ /Entering interactive session/ and $option{confdir} )
        {
            my $path = File::Spec->join($option{confdir}, $option{name}. ".". $$);

            unless ( 
                not defined $lock_fh
                and open $lock_fh, '>', $path 
                and flock $lock_fh, LOCK_EX | LOCK_NB
            )
            {
                warn "can not open $path";
                last READ;
            }

            print $lock_fh YAML::XS::Dump { $option{title} => "127.0.0.1:$lport" };
            $lock_fh->flush;
            
            
        }

        print "channel open reach $option{max_channel}!\n" and last if $line =~ /channel (\d+):/ && $1 >= $option{max_channel};

        while(my($word, $times) = each %{ $option{grep_word} })
        {
            next unless $line =~ /$word/;
            $grep{$word} += 1;
            print "match '$word' reach $times!\n" and last READ if $grep{$word} >= $times;
        }

        alarm $option{timeout} if $option{timeout};
    }

    kill 'KILL', -$$;
}


#ssh -tt -L 127.0.0.1:7920:127.0.0.1:7920 foo@ser1.net ssh -v -o 'ServerAliveInterval=10' -o 'ServerAliveCountMax=3' -tt -L localhost:7920:127.0.0.1:7920 ser2.net ssh -v -o 'ServerAliveInterval=10' -o 'ServerAliveCountMax=1' -N -L localhost:7920:127.0.0.1:1080 foo@ser3.net 2>&1
sub _fmt_ssh
{
    my(%opt, @way, $option, $cmd, $hostname) = @_;
    @way = @{ $opt{way} };
    $option = join ' ', map{ "-o '$_'" }@{$opt{ option }};

    $hostname = hostname;
    shift @way if $way[0] =~ /\@$hostname$/;

    for(splice @way, 0, -1)
    {
        $cmd .= sprintf "ssh -tt %s -L 127.0.0.1:%s:127.0.0.1:%s %s ", $option, $opt{lport}, $opt{lport}, $_;
    }

    $cmd .= sprintf "ssh -v %s -N -L 127.0.0.1:%s:127.0.0.1:%s %s 2>&1", $option, $opt{lport}, $opt{dport}, $way[-1];
}

1;
__END__

=encoding utf-8

=head1 NAME

Vayne::SSH::Tunnel - SSH tunnel wrapper

=head1 SYNOPSIS

  use Vayne::SSH::Tunnel;

  Vayne::SSH::Tunnel::Run
  (
      name           => 'tunnel_foo',
      title          => 'title_to_generate',
      confdir        => '/tmp/tun',
      dport          => 9999,
      way            => [ 'nobody@ser1.com', 'nobody@ser2.com', 'nobody@ser3.com' ],
      user           => 'nobody',
      option         => ['ServerAliveInterval=10', 'ServerAliveCountMax=3', 'StrictHostKeyChecking=no'],
      timeout        => 600,
      max_channel    => 50,
      grep_word      => {
          'open failed'           => 10,
          'cannot listen to port' => 1,
      },
  );


=head1 DESCRIPTION

Vayne::SSH::Tunnel is SSH tunnel wrapper.

Find a free port to do the ssh tunnel using 'ssh -L'.

The tunnel will die when the ssh's output line (STDIN/STDOUT) match below:

=over 3

=item max_channel

Set the max $1 when match /channel (\d+):/

=item grep_word

Set the max time when optional word match.

=back

Hold a file lock and generate the tunnel information when output meet 'Entering interactive session'.(The tunnel begin to work)

The file lock will not be released until the tunnel die.

You can use L<vayne-tunnel-info> to gather all running tunnel info.

=head1 AUTHOR

SiYu Zhao E<lt>zuyis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2016- SiYu Zhao

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
