package UNIVERSAL::Acme;

$VERSION = '0.01';

my %ORIG;
sub import {
    my @SAVE = grep !/[A-Z]/, keys %UNIVERSAL::;
    $ORIG{$_} = \&{'UNIVERSAL::'.$_} for @SAVE;
    delete $UNIVERSAL::{$_} for @SAVE;
}

{ package UNIVERSAL;
  sub AUTOLOAD {
      (my $al = $AUTOLOAD) =~ s/.*:://;
      if ($IN_UA) {
          if (exists $ORIG{$al}) {
              goto &{$ORIG{$al}};
          } else {
              local *UNIVERSAL::AUTOLOAD;
              goto &$AUTOLOAD;
          }
      } else {
          local $IN_UA = 1;
          eval { $_[0]->$al(@_[1..$#_]) }
      }
  }
}

1;
__END__

=head1 NAME

UNIVERSAL::Acme -- Because it's a METHOD, hoser.

=head1 SYNOPSIS

  use UNIVERSAL::Acme;
  UNIVERSAL::thing($obj, 'whatever');  # calls $obj->thing('whatever')

=head1 DESCRIPTION

Tired of people who refuse to call functions as methods?  Show 'em
good with C<UNIVERSAL::Acme>.

=head1 SEE ALSO

L<UNIVERSAL::can>, L<UNIVERSAL::isa>, L<UNIVERSAL::ref>.

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Sean O'Rourke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
