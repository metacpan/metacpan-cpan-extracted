#!/usr/bin/perl

use strict;
use warnings;
use File::Path qw(make_path);
use File::Slurp;
use IPC::System::Simple qw(system);
use Term::ANSIColor;
use JSON;

# NOT finished

my $key_path     = "$ENV{HOME}/.ssh/id_rsa.pub";
my $private_key  = "$ENV{HOME}/.ssh/id_rsa";

# Local folders
my $log_dir      = "../remote_logs";
my $output_dir   = "../logs";
make_path($log_dir)  unless -d $log_dir;
make_path($output_dir) unless -d $output_dir;

my @targets = (
    { ip => 'ipAddr',  user => 'username' },
 
);

# Step 1: Ensure SSH key exists
unless (-e $key_path) {
    print colored("No SSH key found, generating...\n", 'yellow');
    system("ssh-keygen -t rsa -b 4096 -f $private_key -N ''");
}

# Step 2: Loop over each target
for my $host (@targets) {
    my ($ip, $user) = ($host->{ip}, $host->{user});
    my $remote      = "$user\@$ip";
    my $remote_path = "/var/log/apache2/access_log";
    my $local_log   = "$log_dir/${ip}_access.log";

    print colored("\nConnecting to $remote...\n", 'cyan');

    # Accept fingerprint if new
    print colored("Accepting host fingerprint for $ip if needed...\n", 'magenta');
    system("ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 $remote 'echo ok' >/dev/null 2>&1");

    # Test for key-based auth
    my $test = system("ssh -o BatchMode=yes -o ConnectTimeout=5 $remote 'echo ok' >/dev/null 2>&1");

    if ($test != 0) {
        print colored("No key access — using ssh-copy-id...\n", 'yellow');
        system("ssh-copy-id $remote");
    } else {
        print colored("Key-based SSH OK\n", 'green');
    }

    # Step 3: Copy access_log
    print colored("Copying $remote_path to $local_log...\n", 'blue');
    system("scp $remote:$remote_path $local_log") == 0
        or die colored("Failed to copy access_log from $ip\n", 'red');

    # Step 4: Run detect.pl locally
    print colored("Running detect.pl on $local_log...\n", 'white');
    system("perl ../bin/detect.pl --logfile $local_log") == 0
        or warn colored("detect.pl failed for $ip\n", 'red');
}
