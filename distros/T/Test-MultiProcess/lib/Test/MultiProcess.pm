package Test::MultiProcess;

use strict;
use warnings;

use POSIX;
use Cache::FastMmap;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	run_forked
);

our $VERSION = '0.01';

our $RESULT_CACHE_FILE = '/tmp/mu1tiproc.tmp';

our $children;
our %children;

$SIG{CHLD} = \&WAITER;
$SIG{INT}  = \&HUNTSMAN;
$SIG{ALRM} = sub { die "server timeout" };

sub run_forked {
    my %params = @_;
    my $code = $params{code};
    my $forks = $params{forks} || 1;
    
    my $cache = Cache::FastMmap->new( share_file => $RESULT_CACHE_FILE, expire_time => 0, unlink_on_exit => 0, init_file => 1 );

    for (1 .. $forks) {
        make_new_child($code);
    }
    
    for my $pid (keys %children) {
        while (waitpid($pid,0) != -1) {}
    }   

    my $results = $cache->get('results');
    
    return $results;
}

sub WAITER {
    $SIG{CHLD} = \&WAITER;
    my $pid = wait;
    $children--;
    delete $children{$pid};
    #1 until (-1 == waitpid(-1, WNOHANG));
}
   
# SIGINT handler
sub HUNTSMAN {
    local($SIG{CHLD}) = 'IGNORE';
    kill 'INT' => keys %children;
    exit;
}

sub make_new_child {
    my $code = shift;
    
    my $pid;
    my $sigset;
 
    # block sig for fork
    $sigset = POSIX::SigSet->new(SIGINT);
    sigprocmask(SIG_BLOCK, $sigset) or die "Can't block SIGINT for fork: $!\n";
    die "fork: $!" unless defined ($pid = fork);

    if ($pid)
    {
        sigprocmask(SIG_UNBLOCK, $sigset) or die "Can't unblock SIGINT for fork: $!\n";
        $children{$pid} = 1;
        $children++;
        return;
    } else {
        $SIG{INT} = 'DEFAULT';
        sigprocmask(SIG_UNBLOCK, $sigset) or die "Can't unblock SIGINT for fork: $!\n";
        
        my $cachel = Cache::FastMmap->new( share_file => $RESULT_CACHE_FILE, expire_time => 0, unlink_on_exit => 0 );
        my $returned = &$code;
        $cachel->get_and_set('results', sub { ++${$_[1]}{$returned}; return $_[1]; });

        exit;
    }
}


1;
__END__

=head1 NAME

Test::MultiProcess - Run identical code in multiple fork'ed processes

=head1 SYNOPSIS

  use Test::MultiProcess;
  my $results = run_forked(
    code => sub { },
    forks => 10
  );
  

=head1 DESCRIPTION

This module provides a single function, run_forked, which takes a coderef and a number of times to fork for the given code. The obvious use here is testing code that does something that could encounter problems while running simultaneously in multiple processes or threads: stress testing, concurreny testing, locking testing, and so on.

Each forked processes runs the code provided. That code should return a string value. Returned values get written to a shared mmap cache, which are returned by the run_forked() function. The returned structure is a hashref with the string values as keys, and values representing the number of times the string was returned.

See the tests in t/ for examples.

Note that I don't necessary believe this is the ideal way to perform certain types of testing. This module is in no way thorough, but it does provide a simple way to run code in many processes simultaneously. And nothing more.

=head2 EXPORT

run_forked()

=head1 SEE ALSO

fork();

=head1 AUTHOR

Danny Brian, E<lt>dbrian@conceptuary.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Danny Brian

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
