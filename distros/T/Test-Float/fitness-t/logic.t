
print "1..6\n";

# print "0.5 1 - narf\n";

use IPC::Open3;

my @output;

eval {
    my $pid;
    $SIG{ALRM} = sub { kill 9, $pid; die "alarm" };
    $SIG{CHLD} = sub { wait };
    alarm 3;
    $pid = open3(my $stdin, my $stdout, my $stderr, 'perl', 'goo.pl') or die;
    # my $pid = open3(my $stdin, my $stdout, my $stderr, 'perl', 'seq.pl') or die;
    push @output, map { chomp; $_ } scalar readline $stdout for 1..4;
    close $stdin or die $!;
    close $stdout or die $!;
    # waitpid $pid, 0 or die $!;
    # !( $? >> 8 ) or die $?;
    # warn "output: @output";
    # 1 2 3 5 8 13
};
alarm 0;

# warn "error: $@" if $@;

# printf "%1.4f 1 - didn't blow up\n", ! $@;
printf "%1.4f 1 - didn't blow up\n", ! ($? >> 8);
 
printf "%1.4f 2 - first result\n", $output[0] eq '1';
printf "%1.4f 3 - second result\n", $output[1] eq '2';
printf "%1.4f 4 - second result\n", $output[2] eq '3';
printf "%1.4f 5 - second result\n", $output[3] eq '5';

printf "ok 6 - not a total loss or things freak out\n";
