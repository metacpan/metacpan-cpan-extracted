package Test2::Plugin::IOEvents::Base;
use strict;
use warnings;

our $VERSION = '0.000009';

use Test2::Plugin::OpenFixPerlIO;
use IO::Handle;

sub diagnostics { 0 }
sub stream_name { 'UNKNOWN' }

sub PUSHED {
    my ($class, $mode, $handle) = @_;
    $handle->autoflush(1);
    bless {}, $class;
}

sub FLUSH {
    my $self = shift;
    my ($handle) = @_;
    $handle->flush;
}

my $LOADED = 0;
sub WRITE {
    my ($self, $buffer, $handle) = @_;

    $LOADED ||= $INC{'Test2/API.pm'} && Test2::API::test2_init_done();

    my $caller = caller;

    # Test2::API not loaded (?)
    if ($self->{no_event} || !$LOADED || $caller->isa('Test2::Formatter') || $caller->isa('Test2::Plugin::IOMuxer::Layer')) {
        print $handle $buffer;
        return length($buffer);
    }

    my ($ok, $error, $sent);
    {
        local ($@, $?, $!);
        $ok = eval {
            local $self->{no_event} = 1;
            my $ctx = Test2::API::context(level => 1);
            $ctx->send_event('Output', message => $buffer, diagnostics => $self->diagnostics, stream_name => $self->stream_name);
            $sent = 1;
            $ctx->release;

            1;
        };
        $error = $@;
    }
    return length($buffer) if $ok;

    # Make sure we see the output
    print $handle $buffer unless $sent;

    # Prevent any infinite loops
    local $self->{no_event} = 1;
    die $error;

    # In case of __DIE__ handler?
    return length($buffer);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOEvents::Base - The PerlIO::via:: base class used by IOEvents
for output lines.

=head1 SOURCE

The source code repository for Test2-Plugin-IOSync can be found at
F<http://github.com/Test-More/Test2-Plugin-IOSync/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
