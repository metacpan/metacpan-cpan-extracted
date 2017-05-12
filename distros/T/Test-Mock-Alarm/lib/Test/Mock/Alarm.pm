package Test::Mock::Alarm;

use strict;
use warnings;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(set_alarm restore_alarm);

BEGIN {
    our $VERSION = '0.13';
    *CORE::GLOBAL::alarm = \&Test::Mock::Alarm::mocked_alarm;
}

my $_alarm;

sub mocked_alarm {
    if ( defined $_alarm && ref($_alarm) eq 'CODE' ) {
        return $_alarm->(shift);
    }
    else {
        return CORE::alarm(shift);
    }
}

sub set_alarm {
    $_alarm = shift;

    return;
}

sub restore_alarm {
    undef $_alarm;

    return;
}

1;

__END__

=head1 NAME

Test::Mock::Alarm - Mock perl's built-in alarm function

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    # make this the first include
    use Test::Mock::Alarm qw(set_alarm restore_alarm);

    # trigger any alarm of 15 seconds
    set_alarm( sub { die 'alarm' if (shift == 15) } );

    # this will alarm
    foo();

    # reset it back to normal
    restore_alarm();

    # now this will not
    foo();

    # a simplified function with an alarm
    sub foo {
        eval {
            alarm(15);
            bar();     # I take less than 15 seconds
            alarm(0);
        };
        if ( $@ ) {
            print "The alarm was triggered.\n";
        }
    }

=head1 DESCRIPTION

C<Test::Mock::Alarm> is a simple interface that lets you replace perl's built-in C<alarm()> function
with whatever you'd like, allowing you to trigger alarms to test your alarm handling code.

=head1 SUBROUTINES/METHODS

=over 3

=item set_alarm

This will replace the built-in C<alarm()> with whatever you'd like. Almost always, this will look
something like:

    # all alarms of 60 seconds will die with 'alarm'
    set_alarm( sub { die 'alarm' if ( shift == 60 ) } );

or

    # all alarms called from within 'Module::function' will die with 'alarm' 
    set_alarm( sub { die 'alarm' if ( (caller(3))[3] eq 'Module::function' ) } );

These are just two examples but they should be able to handle most of your alarm testing.

=cut

=item restore_alarm

Once you've finished testing, you can return C<alarm()> back to normal with this.

    # fascinating abuse with alarm()
    
    restore_alarm();
    
    # it's back to normal

=cut

=item mocked_alarm

C<Test::Mock::Alarm> uses this to replace perl's internal C<alarm()>.

=cut

=back

=head1 DEPENDENCIES

None

=head1 BUGS AND LIMITATIONS

Having a series of alarms with identical timeouts, like the following, is something that would be
difficult to trigger with this module's current approach.

    while ($condition) {
        alarm($timeout);
        do_something();
        alarm(0);
    }

There may be bugs that exist and other alarm situations that this may not work in - so far it's
managed to work where I've needed it.

=head1 AUTHOR

Jeremy Jack < jeremy@rocketscientry.com >

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=cut
