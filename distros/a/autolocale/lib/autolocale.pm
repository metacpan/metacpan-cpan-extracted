package autolocale;
use strict;
use warnings;
use 5.010000;
use POSIX qw(setlocale LC_ALL);

our $VERSION = '0.07';

my $wiz = wizard(
    set => sub {
        my $hinthash = ( caller(0) )[10];
        return unless $hinthash->{"autolocale"};
        my $arg = shift;
        if ( ref $arg ne 'SCALAR' ) {
            die q{You must store scalar data to %ENV};
        }
        my $locale = ${$arg};
        return unless $locale;
        setlocale( LC_ALL, $locale );
        return;
    }
);

BEGIN {
    use strict;
    use warnings;
    if ( eval { require Variable::Magic; 1 } ) {
        Variable::Magic->import(qw/wizard cast/);
    }
    else {
        # Fallback Pure-Perl mode when can't use Variable::Magic
        {
            package # Hiding package
            autolocale::Tie::Scalar;
            require Tie::Scalar;
            our @ISA = qw(Tie::StdScalar);

            sub STORE {
                my ( $self, $value ) = @_;
                ${$self} = $value;
                @_ = ( \$value );
                goto $wiz;
            }
        }

        *wizard = sub {
            my ( undef, $handler ) = @_;
            return $handler;
        };

        *cast = sub (\$$) {
            my $target = shift;
            tie $$target, 'autolocale::Tie::Scalar';
        };
    }
}

sub import {
    $^H{"autolocale"} = 1;
    cast $ENV{"LANG"}, $wiz;
}

sub unimport {
    $^H{"autolocale"} = 0;
}

1;
__END__

=head1 NAME

autolocale - auto call setlocale() when set $ENV{"LANG"}

=head1 SYNOPSIS

  use autolocale;
  
  $ENV{"LANG"} = "C"; # locale is "C"
  {
      local $ENV{"LANG"} = "en_US";# locale is "en_US"
  }
  # locale is "C"
  
  no autolocale; # auto setlocale disabled
  $ENV{"LANG"} = "en_US"; # locale is "C"

=head1 DESCRIPTION

autolocale is pragma module that auto call setlocale() when set $ENV{"LANG"}.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
