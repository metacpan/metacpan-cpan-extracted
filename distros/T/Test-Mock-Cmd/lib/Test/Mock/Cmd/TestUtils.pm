package Test::Mock::Cmd::TestUtils;

use strict;
use warnings;

sub do_in_fork {
    my ( $code, @args ) = @_;
    my $pid = fork();
    if ( not defined $pid ) {
        die "Could not fork: $!";
    }
    elsif ( $pid == 0 ) {
        $code->(@args);
        exit 1;
    }
    else {
        waitpid( $pid, 0 );    # parent
    }
}

sub test_more_is_like_return_42 {
    my ( $got, $expected, $name ) = @_;
    ref($expected) eq 'Regexp' ? Test::More::like( $got, $expected, $name ) : Test::More::is( $got, $expected, $name );
    return 42;
}

# use Test::Output; # rt 72976
# The Perl::Critic test failures will go away when this temp workaround goes away
sub tmp_stdout_like_rt_72976 {
    my ( $func, $regex, $name ) = @_;
    my $output = '';
    {
        unlink "tmp.$$.tmp";

        no warnings 'once';
        open OLDOUT, '>&STDOUT' or die "Could not dup STDOUT: $!";    ## no critic
        close STDOUT;

        open STDOUT, '>', "tmp.$$.tmp" or die "Could not redirect STDOUT: $!";

        # \$output does not capture system()
        # open STDOUT, '>', \$output or die "Could not redirect STDOUT: $!";

        $func->();
        open STDOUT, '>&OLDOUT' or die "Could not restore STDOUT: $!";    ## no critic

        open my $fh, '<', "tmp.$$.tmp" or die "Could not open temp file: $!";
        while ( my $line = <$fh> ) {
            $output .= $line;
        }
        close $fh;

        unlink "tmp.$$.tmp";
    }

    # use Data::Dumper;diag(Dumper([$output,$regex,$name]));
    Test::More::like( $output, $regex, $name );
}

1;

__END__

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011 cPanel, Inc. C<< <copyright@cpanel.net>> >>. All rights reserved.

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself, either Perl version 5.10.1 or, at your option, 
any later version of Perl 5 you may have available.
