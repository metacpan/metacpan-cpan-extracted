#!/usr/bin/perl

use WWW::AUR::Login;
use POSIX;
use warnings;
use strict;

# Prints a brief usage message and exits.
sub usage
{
    print STDERR "usage: aurup.pl [[category] [file] ...]\n";
    exit 2;
}

# Attempts to login with the provided user and password.
# Returns undef if provided user/pass are wrong.
# Exits the program for any other error.
sub newlogin
{
    my($user, $pass) = @_;
    my $L = eval { WWW::AUR::Login->new($user, $pass) };
    if($L){ 
        return $L;
    }elsif($@ =~ /bad username or password/){
        print STDERR "error: login failed: bad username or password\n";
        return undef;
    }else{
        print STDERR "error: login failed: $@";
        exit 2;
    }
}

# Prints a message to screen and prompts the user for input from STDIN.
sub prompt
{
    my $ln = '';
    while(length $ln == 0){
        print @_;
        $ln = <STDIN>;
        chomp $ln;
    }
    return $ln;
}

# Turn echo "on" or "off".
sub echo
{
    my($state) = @_;
    my $t = POSIX::Termios->new();
    $t->getattr(0);
    my $lflag = $t->getlflag;
    if($state eq 'on'){
        $t->setlflag($lflag | POSIX::ECHO);
    }elsif($state eq 'off'){
        $t->setlflag($lflag & ~POSIX::ECHO);
    }else{
        die "invalid parameter: $state";
    }
    $t->setattr(0, &POSIX::TCSANOW);
}

# Login to the AUR. Read a username/password from STDIN and
# create a WWW::AUR::Login object. Exit the program if we
# are unable to login.
sub login
{
    for (1 .. 3) {
        my $user = prompt("Username: ");
        echo('off');
	my $pass = prompt("Password: ");
        echo('on');
        print "\n";
        if(my $L = newlogin($user, $pass)){
            return $L;
        }
    }

    ## Give up after 3 tries to login.
    print "Aborting.\n";
    exit 1;
}

if(@ARGV < 2){
    usage();
}

my $L = login();
while(@ARGV){
    my $cat = shift;
    my $path = shift;
    $L->upload($path, $cat);
}
