package Test::Ika::Reporter::TAP;
use strict;
use warnings;
use utf8;
use parent qw/Test::Builder::Module/;
use Scope::Guard ();

sub new {
    my $class = shift;
    return bless {describe => []}, $class;
}

sub describe {
    my ($self, $name) = @_;

    push @{$self->{describe}}, $name;
    return Scope::Guard->new(sub {
        pop @{$self->{describe}};
    });
}

sub exception {
    my ($self, $name) = @_;
    $name =~ s/\n\Z//;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $builder = __PACKAGE__->builder;
    $builder->ok(0, "Error: $name");
}

sub it {
    my ($self, $name, $test, $output, $error) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 9;

    my $builder = __PACKAGE__->builder;
    {
        $builder->ok($test, '(' . join("/", @{$self->{describe}}) . ') ' . $name);
    }

    if ($output) {
        if ($test) {
            $builder->note($output);
        } else {
            $builder->diag($output);
        }
    }

    if ($error) {
        $builder->diag("Error: $error");
    }
}

sub finalize {
    my $self = shift;
    if ($self->{finalized}++) {
        Carp::croak("Do not finalize twice.");
    } else {
        my $builder = __PACKAGE__->builder;
        $builder->done_testing;
    }
}

1;
__END__

=head1 NAME

Test::Ika::Reporter::TAP - TAP

=head1 SYNOPSIS

    Test::Ika->set_reporter('TAP');

=head1 DESCRIPTION

This reporter displays a testing result as TAP(Test Anything Protocol).

=head1 SEE ALSO

L<Test::Ika>

