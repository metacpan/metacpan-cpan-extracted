use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

package Some::Class;

sub apply(&@) {
  my $code = shift;
  $code->() foreach @_;
}

package main;

# sanity: Some::Class::apply() works correctly
{
  my @data = ('a', 'b');

  Some::Class::apply { $_ = uc } @data;
  is_deeply( \@data, ['A', 'B'] );
}

{
  my $warning = '';
  local $SIG{__WARN__} = sub { $warning = shift };

  my $guard = mock_guard('Some::Class', {
    apply => sub {
      my ($code) = shift;
      foreach (@_) {
        $_ = "$_ $_";
        $code->();
      }
    },
  });
  unlike( $warning, qr/prototype mismatch/i, 'no prototype mismatch errors' );

  my @data = ('a', 'b');

  Some::Class::apply { $_ = uc($_); 0 } @data;
  is_deeply( \@data, ['A A', 'B B'] );
}

done_testing;
