package testcases::Base::Errors;
use strict;
use Error qw(:try);
use base qw(testcases::Base::base);

sub test_everything {
    my $self=shift;

    use XAO::Errors qw(XAO::Base);
    use XAO::Errors qw(XAO::Objects);
    use XAO::Errors qw(XAO::Base);

    my $rc='Did not get to throwing at all';
    my $text;
    try {
        throw XAO::E::Base "test - message";
    } catch XAO::E::Base with {
        my $e=shift;
        $text="$e";
        $rc=undef;
    } otherwise {
        my $e=shift;
        $text="$e";
        $rc="Caught wrong exception (" . ref($e) . ")";
    };
    $self->assert(!$rc,$rc);
    $self->assert($text =~ /^XAO::Base::test - message/,
                  "Exception text is wrong ($text)");
}

1;
