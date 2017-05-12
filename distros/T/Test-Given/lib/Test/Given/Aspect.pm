package Test::Given::Aspect;
use strict;
use warnings;

use Test::Given::Context qw(define_var);

sub new {
  my ($class, $sub, $name, $package) = @_;
  my $self = {
    real_sub    => $sub,
    var_name    => $name,
    var_package => $package,
  };
  $self->{wrapped_sub} = wrap_sub($self);
  bless $self, $class;
}

sub wrap_sub {
  my ($self) = @_;
  my $sub = $self->{real_sub};
  my $name = $self->{var_name};
  if ( defined $name ) {
    my $package = "$self->{var_package}::";
    if ( $name =~ s/^\@// ) {
      return sub {
        define_var($package, $name, [ $sub->() ]);
      }
    }
    elsif ( $name =~ s/^\%// ) {
      return sub {
        define_var($package, $name, { $sub->() });
      }
    }
    elsif ( $name =~ s/^\&// ) {
      return sub {
        define_var($package, $name, $sub->());
      }
    }
    $name =~ s/^\$//;
    return sub {
      define_var($package, $name, \$sub->());
    }
  }
  return $sub;
}

sub apply { shift->{wrapped_sub}->() };

package Test::Given::Given;
use parent 'Test::Given::Aspect';

package Test::Given::When;
use parent 'Test::Given::Aspect';

package Test::Given::Done;
use parent 'Test::Given::Aspect';

1;
