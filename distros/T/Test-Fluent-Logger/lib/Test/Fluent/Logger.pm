package Test::Fluent::Logger;
use 5.008001;
use strict;
use warnings;
no warnings qw/redefine/;

our $VERSION = "0.03";

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/get_fluent_logs clear_fluent_logs/;
our @EXPORT_OK = qw/is_active activate deactivate/;

use Fluent::Logger;

my $original__post = Fluent::Logger->can('_post');

my $is_active;
my @fluent_logs;

sub is_active () {
    return $is_active;
}

sub import {
    Test::Fluent::Logger->export_to_level(1, @_);

    activate();

    *Fluent::Logger::_post = sub {
        if ($is_active) {
            my ($self, $tag, $msg, $time) = @_;
            push @fluent_logs, {
                message    => $msg,
                time       => $time,
                tag_prefix => $self->tag_prefix || "",
            };
        } else {
            $original__post->(@_);
        }
    };
}

sub unimport {
    deactivate();
}

sub activate () {
    $is_active = 1;
}

sub deactivate () {
    $is_active = 0;
}

sub clear_fluent_logs () {
    @fluent_logs = ();
}

sub get_fluent_logs () {
    return @fluent_logs;
}

1;
__END__

=encoding utf-8

=for stopwords fluentd

=head1 NAME

Test::Fluent::Logger - A mock implementation of Fluent::Logger for testing

=head1 SYNOPSIS

    use Test::More;
    use Test::Fluent::Logger; # Enable the function of this library just by using
                              # (Activate intercepting the fluentd log payload)

    use Fluent::Logger;

    my $logger = Fluent::Logger->new(
        host       => '127.0.0.1',
        port       => 24224,
        tag_prefix => 'prefix',
    );

    $logger->post("tag1", {foo => 'bar'}); # Don't post to fluentd, it puts the log content on internal stack
    $logger->post("tag2", {buz => 'qux'}); # ↑Either

    # Get internal stack (array)
    my @fluent_logs = get_fluent_logs;
    is_deeply \@fluent_logs, [
        {
            'tag_prefix' => 'prefix',
            'time' => '1485443191.94598',
            'message' => {
                'foo' => 'bar'
            }
        },
        {
            'tag_prefix' => 'prefix',
            'time' => '1485443191.94599',
            'message' => {
                'buz' => 'qux'
            }
        }
    ];

    # Clear internal stack (array)
    clear_fluent_logs;

    @fluent_logs = get_fluent_logs;
    is_deeply \@fluent_logs, [];

=head1 DESCRIPTION

Test::Fluent::Logger is a mock implementation of Fluent::Logger for testing.

This library intercepts the log payload of fluentd and puts that on stack.
You can pickup log[s] from stack and it can be used to testing.

=head1 FUNCTIONS

=head2 C<get_fluent_logs(): Array[HashRef]>

Get fluentd logs from stack as array.

Item of the array is hash reference. The hash reference is according to following format;

    {
        'tag_prefix' => 'prefix',
        'time' => '1485443191.94599', # <= timestamp
        'message' => {
            'buz' => 'qux'
        }
    }

=head2 C<clear_fluent_logs()>

Clear stack of fluentd logs.

=head2 C<activate()>

Activate intercepting the log payload.

=head2 C<deactivate()>

Deactivate intercepting the log payload.

=head1 SEE ALSO

=over 4

=item L<Fluent::Logger>

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

