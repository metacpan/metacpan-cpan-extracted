package Test::Ika::Reporter::Test;
use strict;
use warnings;
use utf8;
use Scope::Guard;

sub new {
    my $class = shift;
    return bless {
        describe => [],
        report => [],
    }, $class;
}

sub report { $_[0]->{report} }

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

    push @{$self->{report}}, [exception => $name];
}

sub it {
    my ($self, $name, $test) = @_;

    push @{$self->{report}}, ['it', $name, $test, [@{$self->{describe}}]];
}

sub finalize {
    my $self = shift;
    if ($self->{finalized}++) {
        Carp::croak("Do not finalize twice.");
    }
}

1;
__END__

=head1 NAME

Test::Ika::Reporter::Test - testing tester

=head1 SYNOPSIS

    Test::Ika->set_reporter('Test');

=head1 DESCRIPTION

This module captures testing result in Test::Ika.

You can get a result from $test->result() method.

