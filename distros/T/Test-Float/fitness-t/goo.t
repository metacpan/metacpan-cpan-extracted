

my $how_big = 20;  # how large of a program we want; let the thing golf the solution as long as tests pass

print "1..9\n";

# individual output lines look like this:
# print "0.5 1 - narf\n";
# test result value, test number, test description

# test 1 -- size of file

open my $fh, '<', 'goo.pl' or die $!;
my @lines = <$fh>;
my $num_lines = @lines;

do {
    my $score = $num_lines / $how_big;
    $score = 1.0 if @lines >= $how_big;
    printf "%1.4f 1 - file size\n", $score;
    # $score > 0.3 or goto failed1; # XXX tempting to make all later tests come up 0 if any particular one does too badly
};

# test 2 -- syntax okay?

my $diagnostic_output;

do {
    use IPC::Open3;
    open3(my $stdin, my $stdout, my $stderr, 'perl', '-c', 'goo.pl') or die;
    $diagnostic_output = join '', readline $stdout;
    if(! $diagnostic_output or $diagnostic_output =~ m/.pl syntax OK/) {
        print "1.0 2 - syntax check\n";
    } else {
        print "0.0 2 - syntax check\n";
    }
};

# test 3 -- how long before parsing barfs
    
do {
    if(! $diagnostic_output or $diagnostic_output =~ m/.pl syntax OK/) {
        print "1.0 3 - first syntax error (no error)\n";
    } else {
        (my $error_line) = $diagnostic_output =~ m/ at goo.pl line (\d+)./ or do {
            warn "failed to parse line number out of last line of error output from perl -c: ``$diagnostic_output''";
            print "0.0 3 - first syntax error (couldn't parse perl -c output)\n";
            goto whatever;
        };
        # warn "error line: $error_line\n";
        my $score = $error_line / ($num_lines+1);
        $score = 1.0 if $score > 1;
        printf "%1.4f 3 - first syntax error (got an error on line $error_line)\n", $score;
      whatever:
    }
};

# test 4-5 -- comments!

do {
    my @non_comment_lines = grep { $_ !~ m/#/ and $_ !~ m/^\s*$/} @lines;
    my $score = eval { @non_comment_lines / @lines } || 0;
    printf "%1.4f 4 - not too many comments\n", $score;
    printf "%1.4f 5 - not too many comments\n", $score;
};

# test 6-7 -- blank lines!

do {
    my @non_blank_lines = grep { $_ !~ m/^\s+$/ } @lines;
    my $score = eval { @non_blank_lines / @lines } || 0;
    printf "%1.4f 6 - non blank lines\n", $score;
    printf "%1.4f 7 - non blank lines\n", $score;
};

# test 8 -- excessively whitespace

do {
    my $score;
    for my $line (@lines) {
        my $initial_line_len = length($line);
        my $line_cp = $line;
        $line_cp =~ s/#.*//;
        $line_cp =~ s/\s+//g;
        $score += length($line_cp) / $initial_line_len;
    }
    printf "%1.4f 8 - excessive whitespace\n", $score / $num_lines;
};

# test 9 -- excessively short lines

do {
    my $score;
    for my $line (@lines) {
        my $initial_line_len = length($line);
        $initial_line_len = 80 if $initial_line_len < 80;
        $score += length($line) / $initial_line_len;
    }
    printf "%1.4f 9 - excessively short lines\n", $score / $num_lines;
};





# test n -- discourage pointless whitespace to pad out lines before errors

# test n -- todo -- runtime errors?

