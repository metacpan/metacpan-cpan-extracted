package ModulinoH2O;

use strict;
use warnings;

use Getopt::Long qw();
use Util::H2O::More qw/baptise opt2h2o/;

my @opt_spec = qw/
    name=s
    water=s@
/;

sub new {
    my $class = shift;
    my %opts  = @_;

    return baptise \%opts, $class, opt2h2o(@opt_spec);
}

sub new_with_options {
    my ( $class, $argv ) = @_;
    $argv = \@ARGV unless defined $argv;

    # Make a fresh object for every parse.  Keeping one lexical H2O object and
    # parsing into it repeatedly would allow values from an earlier invocation
    # to survive into a later one in the same interpreter.
    my $self = $class->new;

    Getopt::Long::GetOptionsFromArray( $argv, $self, @opt_spec )
        or die qq{bad options\n};

    # "name=s" means --name requires a string when --name is present.  It does
    # not mean --name itself is mandatory, so required-option validation remains
    # application logic.  Use definedness so a legitimate value such as "0"
    # is not rejected as false.
    die qq{Missing --name\n} unless defined $self->name;

    return $self;
}

sub time_of_day {
    my ( $self, $hour ) = @_;
    $hour = (localtime)[2] unless defined $hour;

    my %hours = (
         5 => q{morning},
        12 => q{afternoon},
        17 => q{evening},
        21 => q{night},
    );

    for ( sort { $b <=> $a } keys %hours ) {
        return $hours{$_} if $hour >= $_;
    }

    return q{night};
}

sub run {
    my ( $self, $hour ) = @_;

    printf qq{Good %s, %s!\n}, $self->time_of_day($hour), $self->name;

    if ( defined $self->water and @{ $self->water } ) {
        print qq{What kind of water would you like?\n};
        print qq{- $_\n} for @{ $self->water };
    }

    return;
}

1;

__END__

=head1 NAME

ModulinoH2O - test fixture showing a Util::H2O::More modulino

=head1 METHODS

=head2 new

Creates a fresh object that inherits from this package and has accessors for the
command-line option specification.

=head2 new_with_options

Creates a fresh object, parses an argv array reference with Getopt::Long, and
performs application-level validation of the required C<--name> option.

=head2 time_of_day

Returns a day-period label.  An optional hour is accepted to make the method
deterministic in unit tests.

=head2 run

Prints the greeting and any selected water values.

=cut

