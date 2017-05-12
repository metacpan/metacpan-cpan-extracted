package User::AccountChecker;

use warnings;
use strict;

use FindBin qw($Bin $Script);

=head1 NAME

User::AccountChecker - I<Tools for user account checking in an Unix environment>

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

S<I<Provides an interface to check current user account.>
I<Useful for shell scripting.>>

A little code snippet :

    use User::AccountChecker;

    my $uuac = User::AccountChecker->new();
    # need to identify current user
    die("You are not allowed to continue.\n") unless($uuac->isuser('root'));
    
    # check if root user
    if ($uuac->isroot) {
        print("You are root.\n");
    } else {
        print("You are not root.\n");
    }
    
    # need root permissions for a shell command
    my $shellcommand = $uuac->shellrootcmd("cat /etc/shadow");
    # if current user is root, $shellcommand == "cat /etc/shadow" 
    # otherwise, $shellcommand == "sudo cat /etc/shadow", and
    # $ENV{'SUDO_ASKPASS'} if ssh-askpass is installed
    
    # force a script to be runned as root
    $uuac->runasroot(@ARGV);
    # $uuac->isroot() should be true
    
    # need root permissions to continue
    $uuac->musttoberoot();
    print("if you see this message then you get root permissions.\n");

=head1 SUBROUTINES/METHODS

=head2 new

C<User::AccountChecker-E<gt>new()>

I<Constructor>

=over 4

=item

return new instance of User::AccountChecker

=back

=cut

sub new {
    my ($this) = shift;
    return bless({}, $this);
}

=head2 isuser

C<$object-E<gt>isuser($name)>

I<Checks if the current user is B<C<$name>>.>

=over 4

=item

S<param        string        B<C<$name>>        the name of the user account to check>

=item

return true if the current user is B<C<$name>>, false otherwise

=back

=cut

sub isuser {
    my ($this, $name) = @_;
    return ($name eq getpwuid($<)) ? 1 : 0;
}

=head2 isroot

C<$object-E<gt>isroot()>

I<Checks if the current user is root.>

=over 4

=item

return true if the current user is root, false otherwise

=back

=cut

sub isroot {
    my ($this) = shift;
    return $this->isuser("root");
}

=head2 musttoberoot

C<$object-E<gt>musttoberoot()>

S<I<Requires the current user to be logged as root.>
I<Dies if the current user is not root.>>

=cut

sub musttoberoot {
    my ($this) = shift;
    unless ($this->isroot) {
        die("You must to be logged as root.");
    }
}

=head2 shellrootcmd

C<$object-E<gt>shellrootcmd($command)>

S<I<Checks for ssh-askpass linux command and initialize B<C<$ENV{'SUDO_ASKPASS'}>> if it is founded.>
I<Adds sudo at the beginning of a command, or at the beginning of each piped commands.>>

=over 4

=item

S<param        string        B<C<$command>>        the command to wich add sudo>

=item

return B<C<$command>> with sudo prefix if the current user isn't root, else return B<C<$command>>

=back  

=cut

sub shellrootcmd {
    my ($this, $cmd) = @_;
    # current user is root    
    return $cmd if ($this->isroot);
    # current user is not root    
    # ask pass
    my $askpass =  `which ssh-askpass`;
    chomp($askpass);
    if (-e $askpass) {
        $ENV{'SUDO_ASKPASS'} = $askpass;
    }
    $cmd =~ s/(&&|\|)/$1 sudo/ig;
    return 'sudo '.$cmd;
}

=head2 runasroot

C<$object-E<gt>runasroot($commandargs)>

I<Forces a script to be runned as root>

=over 4

=item

S<param        array        B<C<$commandargs>>        the command arguments (eg. @ARGV)>

=back

=cut

sub runasroot {
    my ($this, @args) = @_;
    if (!$this->isroot()) {
        my $sargs   = (@args > 0) ? ' '.join(' ', @args) : '';
        my $cmd     = $this->shellrootcmd('su -c "'.$Bin.'/'.$Script.$sargs.'"');
        chomp($cmd);      
        system($cmd);
        exit 0;
    }
}

=head1 AUTHOR

Eric Villard, C<< <evi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-User at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=User>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc User::AccountChecker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=User>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/User>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/User>

=item * Search CPAN

L<http://search.cpan.org/dist/User/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Eric Villard.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of User::AccountChecker
