=head1 NAME

YottaDB::Lock - run sections under a M-lock

=head1 SYNOPSIS

 use YottaDB::Lock;

 y_locked {
     ... code ...
 } [timeout,] mvar [,sub1 [,sub2 [,...]]]

=head1 DESCRIPTION

This module allows you to run a piece of code under a M-lock.

=over 4

=cut

package YottaDB::Lock;

use YottaDB ":all";

use base Exporter;

$VERSION = 0.0;
@EXPORT = qw/y_locked/;


our $default_timeout = 60.0;

# __is_number is not a real check; we just
# need it to differentiate between a M-Variable
# (local/global) and a number (timeout)

sub __is_number ($) {
        my $x = shift;
        defined $x && $x =~ /^[0-9.]+/;
}


sub new ($@) {
        my ($class, @args) = @_;
        bless \@args, $class;
}

sub lock ($) {
        my $self = shift;
        my $timeout;
        if (__is_number $self->[0]) {
                $timeout = shift @$self;
        } else {
                $timeout = $default_timeout;
        }
        y_lock_incr $timeout, @$self;
}

sub unlock ($) {
        my $self = shift;
        y_lock_decr @$self;
}

=item y_locked BLOCK [timeout,] mvar [,sub1 [,sub2 [,...]]]

Execute the given BLOCK while holding the lock mvar...
The lock is released when the block exits.
Timeout is in seconds.

=cut

sub y_locked (&@) {
        my $code = shift;
        my $lock = new YottaDB::Lock @_;

        $lock->lock or die "unable to aquire lock";
        eval { &$code; };
        {
                local $@;
                $lock->unlock;
        }
        die if $@;
}

=back

=head1 SEE ALSO

L<YottaDB>

=head1 AUTHOR

 Stefan Traby <stefan@hello-penguin.com>

=cut

1;
__END__

