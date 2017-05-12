package Trace::Mask::TryTiny;
use strict;
use warnings;

use Try::Tiny 0.03;
use Trace::Mask::Util qw/update_mask/;

sub mask_try_tiny {
    try {
        my @caller = caller(0);

        my $level = 1;
        while (my @deep = caller($level)) {
            last if $deep[3] eq __PACKAGE__ . '::mask_try_tiny';
            $level++;
        }

        update_mask($caller[1], $caller[2], '*', {hide => $level});
        die "should not see this";
    }
    catch {
        my @caller = caller(0);

        my $level = 1;
        while (my @deep = caller($level)) {
            last if $deep[3] eq __PACKAGE__ . '::mask_try_tiny';
            $level++;
        }

        update_mask($caller[1], $caller[2], '*', {hide => $level});
    }
    finally {
        my @caller = caller(0);

        my $level = 1;
        while (my @deep = caller($level)) {
            last if $deep[3] eq __PACKAGE__ . '::mask_try_tiny';
            $level++;
        }

        update_mask($caller[1], $caller[2], '*', {hide => $level});
    };
}

mask_try_tiny();

1;

__END__

=pod

=head1 NAME

Trace::Mask::Try::Tiny - Trace::Mask tools for masking Try::Tiny in traces

=head1 DESCRIPTION

This module can be used to apply L<Trace::Mask> behavior to Try::Tiny so that
it is hidden in L<Trace::Mask> compliant stack traces.

=head1 SYNOPSIS

    use Trace::Mask::TryTiny;
    use Trace::Mask::Carp qw/cluck/;

    try {
        cluck "Try::Tiny is not in this trace";
        die "ignore me";
    }
    catch {
        cluck "Try::Tiny is not in this trace";
    }
    finally {
        cluck "Try::Tiny is not in this trace";
    };

=head1 NO CONFIGURATION

There is no configuration, and no import options. This module is very simple,
it adds the correct entries to C<%Trace::Mask::MASKS>. It runs C<Try::Tiny> and
uses caller to determine how many fames should be hidden in each call
dynamically.

=head1 SOURCE

The source code repository for Trace-Mask can be found at
F<http://github.com/exodist/Trace-Mask>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
