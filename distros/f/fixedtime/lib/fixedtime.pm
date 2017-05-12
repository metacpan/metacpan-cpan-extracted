package fixedtime;
use 5.010;    # this is a user-defined pragma and needs perl 5.10 or higher
use warnings;
use strict;

our $VERSION = 0.05;

=head1 NAME

fixedtime - lexical pragma to fix the epoch offset for time related functions

=head1 SYNOPSIS

    use Test::More 'no_plan';

    use constant EPOCH_OFFSET => 1204286400; # 29 Feb 2008 12:00:00 GMT

    {
        use fixedtime epoch_offset => EPOCH_OFFSET;

        my $fixstamp = time;
        is $fixstamp, EPOCH_OFFSET, "Fixed point in time ($fixstamp)";
        is scalar gmtime, "Fri Feb 29 12:00:00 2008",
           "@{[ scalar gmtime ]}";

        no fixedtime;
        isnt time, EPOCH_OFFSET, "time() is back to normal";
    }

    isnt time, EPOCH_OFFSET, "time() is back to normal";

=head1 DESCRIPTION

This pragma demonstrates the new perl 5.10 user-defined lexical pragma
capability. It uses the C<$^H{fixedtime}> hintshash entry to store the
epochoffset. Whenever C<$^H{fixedtime}> is undefined, the praga is
assumed not to be in effect.

The C<fixedtime> pragma affects L<time()>, L<gmtime()> and
L<localtime()> only when called without an argument.

=head2 use fixedtime [epoch_offset => epoch_offset];

This will enable the pragma in the current lexical scope. When the
B<epoch_offset> argument is omitted, C<CORE::time()> is taken. While
the pragma is in effect the epochoffset is not changed.

B<Warning>: If you use a variable to set the epoch offset, make sure
it is initialized at compile time.

    my $epoch_offset = 1204286400;
    use fixedtime epoch_offset => $epoch_offset; # Will not work as expected

You will need something like:

    use constant EPOCH_OFFSET => 1204286400;
    use fixedtime epoch_offset => EPOCH_OFFSET;

=begin private

=head2 fixedtime->import( [epoch_offset => EPOCH_OFFSET] )

C<import()> is called on compile-time whenever C<use fixedtime> is called.

Saves the status of the pragma (an epoch offset) in $^H{fixedtime}.

=end private

=cut

sub import   {
    shift;
    my %args = @_;
    # we do not care about autoviv
    $^H{fixedtime} = $args{epoch_offset} // CORE::time;
}

=head2 no fixedtime;

This will disable the pragma in the current lexical scope.

=begin private

=head2 fixedtime->unimport

C<unimport()> is called on compile time whenever C<no fixedtime> is called.

Stores undef as the pragma status to mean that it is not in effect.

=end private

=cut

sub unimport { $^H{fixedtime} = undef }

=begin private

=head2 fixedtime::epoch_offset

C<epoch_offset()> returns the runtime status of the progma.

=end private

=cut
 
sub epoch_offset {
    my $ctrl_h = ( caller 1 )[10];
    return $ctrl_h->{fixedtime};
}

# redefine the time related functions
# this works because:
#   * pragma in effect     -> fixedtime::epoch_offset() is defined
#   * pragma not in effect -> fixedtime::epoch_offset() is not defined
#   * the // makes sure that for undef CORE::time is used
# NB: for gmtime and localtime:
#       when an epoch offset is passed, normal operation is in effect
BEGIN {
    *CORE::GLOBAL::time = sub {
        return fixedtime::epoch_offset() // CORE::time;
    };

    *CORE::GLOBAL::gmtime = sub (;$) {
        my $stamp = shift // fixedtime::epoch_offset() // CORE::time;
        CORE::gmtime( $stamp );
    };

    *CORE::GLOBAL::localtime = sub (;$) {
        my $stamp = shift // fixedtime::epoch_offset() // CORE::time;
        CORE::localtime( $stamp );
    };
}

1;

__END__

=head1 SEE ALSO

L<perlpragma>

=head1 AUTHOR AND COPYRIGHT

(c) MMVIII All rights reserved, Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
