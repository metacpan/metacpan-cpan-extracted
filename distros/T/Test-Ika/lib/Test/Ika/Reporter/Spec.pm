package Test::Ika::Reporter::Spec;
use strict;
use warnings;
use utf8;
use Scope::Guard ();
use Term::ANSIColor qw/colored/;
use Term::Encoding ();

sub new {
    my $class = shift;
    my $args  = shift;

    $|++;
    my $term_encoding = Term::Encoding::term_encoding();
    binmode *STDOUT, ":encoding($term_encoding)";
    binmode *STDERR, ":encoding($term_encoding)";

    print "\n";

    return bless {
        failed => 0,
        describe => [],
        results => [],
        color => (exists $args->{color} ? $args->{color} : 1),
    }, $class;
}

sub color {
    my ($self, $color, @args) = @_;

    return @args unless $self->{color};
    return Term::ANSIColor::colored($color, @args);
}

sub describe {
    my ($self, $name) = @_;
    push @{$self->{describe}}, $name;
    print(('  ' x @{$self->{describe}}) . "$name\n");
    return Scope::Guard->new(sub {
        pop @{$self->{describe}};
    });
}

sub it {
    my ($self, $name, $test, $results, $exception) = @_;

    print ('  ' x (@{$self->{describe}}+1));
    if ($test > 0) {
        print( $self->color( ['green'], "\x{2713} " ) );
    }
    elsif ($test < 0) {
        print( $self->color( ['yellow'], "\x{2713} " ) );
    }
    else {
        # not ok
        print( $self->color( ['red'], "\x{2716} " ) );
    }
    print( $self->color( ["BRIGHT_BLACK"], $name ) );
    if (!$test) {
        my $failed = ++$self->{failed};
        printf(" (FAILED - %d)", $failed);
        push @{$self->{results}}, [$results, $exception];
    }
    print("\n");
}

sub finalize {
    my $self = shift;
    if ($self->{finalized}++) {
        die "Do not finalize twice.";
    } else {
        print "\n";

        for my $i (0..$self->{failed}-1) {
            printf "  %s)\n", $i+1;
            my $indent = ' ' x 4;
            if (defined(my $msg = $self->{results}->[$i]->[0])) {
                $msg =~ s{\n(?!\z)}{\n$indent}sg;
                print $indent . $msg;
            }
            if (defined(my $err = $self->{results}->[$i]->[1])) {
                $err =~ s{\n(?!\z)}{\n$indent}sg;
                print $indent . $self->color(['red', 'bold'], 'Exception: ') . $self->color(['red'], $err);
            }
        }
        print "\n";
    }
}

1;
__END__

=head1 NAME

Test::Ika::Reporter::Spec - Reporter like RSpec

=head1 SYNOPSIS

    Test::Ika->set_reporter('Spec');

=head1 DESCRIPTION

This module displays pretty output like RSpec.

=head1 SEE ALSO

L<Test::Ika>

