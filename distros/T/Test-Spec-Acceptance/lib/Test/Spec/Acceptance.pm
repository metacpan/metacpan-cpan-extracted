package Test::Spec::Acceptance;

# ABSTRACT: Aliases for acceptance-like testing using Test::Spec
use parent qw(Exporter);
use Test::Spec;

our $VERSION = '0.02';

our @ACCEPTANCE_EXPORT = qw( Feature Scenario Given When Then And );
our @EXPORT = (
    @Test::Spec::EXPORT,
    @Test::Spec::ExportProxy::EXPORT,
    @ACCEPTANCE_EXPORT,
);
our @EXPORT_OK = (
    @Test::Spec::EXPORT_OK,
    @Test::Spec::ExportProxy::EXPORT_OK,
    @ACCEPTANCE_EXPORT,
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub import {
    my $class = shift;
    my $callpkg = caller;

    strict->import;
    warnings->import;

    if (@_) {
        $class->export_to_level(1, $callpkg, @_);
        return;
    }

    eval qq{
        package $callpkg;
        use parent 'Test::Spec::Acceptance';
        # allow Test::Spec usage errors to be reported via Carp
        our \@CARP_NOT = qw($callpkg);
    };
    die $@ if $@;

    Test::Spec->export_to_level(1, $callpkg);
    $class->export_to_level(1, $callpkg);
}

BEGIN {
    *Feature = \&Test::Spec::describe;
    *Scenario = \&Test::Spec::describe;
    *Given = \&Test::Spec::it;
    *When = \&Test::Spec::it;
    *Then = \&Test::Spec::it;
    *And = \&Test::Spec::it;
}

1;

=head1 NAME

Test::Spec::Acceptance - Write tests in a declarative specification style

=head1 SYNOPSIS

    use Test::Spec::Acceptance;    # Also loads Test::Spec

    Feature "Test::Spec::Acceptance tests module" => sub {
        Scenario "Usage example" => sub {
            my ($number, $accumulated);

            Given "a relevant number" => sub {
                $number = 42;
            };
            When "we add 0 to it" => sub {
                $accumulated = $number + 0
            };
            When "we add 0 again" => sub {
                $accumulated = $number + 0
            };
            Then "it does not change it's value" => sub {
                is($accumulated, 42);
            };
        };
    };

    runtests;

=head1 DESCRIPTION

This is a shameless wrapper around L<Test::Spec>. It does everything L<Test::Spec> does, plus it aliases some exported names to make acceptance-style tests more legible.

I understand this is a bit silly and this is not how C<Test::Spec> is intended to work (using tests without any assertion) but I just think it's nice and more readable. I've had good experiencies expressing some tests this way.

The new keywords are:

=over 4

=item Feature

An alias for C<describe()>.

=item Scenario

An alias for C<describe()>.

=item Given

An alias for C<it()>.

=item When

An alias for C<it()>.

=item Then

An alias for C<it()>.

=item And

An alias for C<it()>.

=back

=head1 SEE ALSO

Please, see the excellent L<Test::Spec>.

=cut
