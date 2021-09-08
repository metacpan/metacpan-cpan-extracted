package Valiant::Params;

use Sub::Exporter 'build_exporter';
use Class::Method::Modifiers qw(install_modifier);

require Moo::Role;

our @DEFAULT_ROLES = (qw(Valiant::Util::Ancestors Valiant::Params::Role));
our @DEFAULT_EXPORTS = (qw(param params));

sub default_roles { @DEFAULT_ROLES }
sub default_exports { @DEFAULT_EXPORTS }

sub import {
  my $class = shift;
  my $target = caller;

  foreach my $default_role ($class->default_roles) {
    next if Moo::Role::does_role($target, $default_role);
    Moo::Role->apply_roles_to_package($target, $default_role);
  }

  my @all_exports = $class->default_exports;
  push @all_exports, $target->extra_exports
    if $target->can('extra_exports');

  my %cb = map {
    $_ => $target->can($_);
  } @all_exports;
  
  my $exporter = build_exporter({
    into_level => 1,
    exports => [
      map {
        my $key = $_; 
        $key => sub {
          sub { return $cb{$key}->($target, @_) };
        }
      } keys %cb,
    ],
  });

  $class->$exporter(@all_exports);

  install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;

    my $method = \&{"${target}::param"};
 
    if(my $options = delete $opts{param}) {
      $options = [] if $options == 1;
      @options = ref($options) eq 'ARRAY' ? @$options : %$options;
      $method->($attr, @options);
    }
      
    return $orig->($attr, %opts);
  } if $target->can('has');
}

