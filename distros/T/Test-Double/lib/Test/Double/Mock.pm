package Test::Double::Mock;

use strict;
use warnings;
use Class::Monadic qw(monadic);
use Scalar::Util qw(weaken);
use Test::Double::Mock::Expectation;

{
    my %MOCKS = ();
    sub wrap {
        my ($class, $instance) = @_;
        $MOCKS{$instance} ||= $class->new(
            package  => ref($instance),
            instance => $instance,
        );
        weaken($instance);
        return $MOCKS{$instance};
    }

    sub reset_all {
        %MOCKS = ();
    }

    sub verify_result_all {
        my $all_result;
        for my $instance (values %MOCKS) {
            for (@{$instance->{expectations}}) {
                my $result = $_->verify_result;
                $all_result->{$_->{method}} = $result;
            }
        }
        return $all_result;
    }

    sub verify_all {
        for my $instance (values %MOCKS) {
            $_->verify for @{$instance->{expectations}};
        }
    }
}

sub new {
    my ($class, %args) = @_;
    bless { %args, expectations => [] }, $class;
}

sub expects {
    my ($self, $method) = @_;

    my $expectation = Test::Double::Mock::Expectation->new(
        package => $self->{package},
        method  => $method,
    );

    monadic($self->{instance})->add_methods($method => $expectation->behavior);
    push @{ $self->{expectations} }, $expectation;

    return $expectation;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Test::Double::Mock - Mock object

=head1 METHODS

=over 4

=item expects($name)

Returns L<Test::Double::Mock::Expectation> object.

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Double>, L<Test::Double::Mock::Expectation>

=cut
