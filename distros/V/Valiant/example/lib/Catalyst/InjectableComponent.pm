package Catalyst::InjectableComponent;

use Sub::Exporter 'build_exporter';
use Class::Method::Modifiers qw(install_modifier);

require Role::Tiny;

our @DEFAULT_ROLES = (qw(Catalyst::ComponentRole::Injects));
our @DEFAULT_EXPORTS = (qw(tags));

sub default_roles { @DEFAULT_ROLES }
sub default_exports { @DEFAULT_EXPORTS }

sub import {
  my $class = shift;
  my $target = caller;

  foreach my $default_role ($class->default_roles) {
    next if Role::Tiny::does_role($target, $default_role);
    Role::Tiny->apply_roles_to_package($target, $default_role);
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

    foreach my $export (@all_exports) {
      my $method = \&{"${target}::__init_${export}"};
      if(my $found = delete $opts{$export}) {
        %opts = $method->($target, $attr, \%opts, $found);
      }
    } 
    return $orig->($attr, %opts);
  } if $target->can('has');
}

package Catalyst::ComponentRole::Injects;

use Moo::Role;

sub _to_class {
  my $proto = shift;
  return ref($proto) ? ref($proto) : $proto;
}

sub _to_array {
  my $args = shift;
  return ref($args) ? @$args : ($args);
}

sub COMPONENT {
  my ($class, $app, $args) = @_;
  $args = $class->merge_config_hashes($class->config, $args);
  return bless $args, $class;
}

sub ACCEPT_CONTEXT {
  my ($self, $c) = shift, shift;
  my %args = (%$self, @_);
  return ref($self)->new(%args);
}

my $_tags = +{};

sub __init_tags {
  my ($class, $attr, $opts, $args) = @_;
  my @tags = _to_array($args);
  $class->__add_tag($attr, $_) for @tags;
  return %{$opts};
}

sub __add_tag {
  my ($class, $attr, $tag) = @_;
  my $varname = "${class}::_tags";

  no strict "refs";
  push @{$$varname->{$attr}}, $tag;
  return %{ $$varname };
}

sub tags {
  my $class = _to_class(shift);
  my $varname = "${class}::_tags";

  if(@_) {
    my $attr = shift;
    my @tags = _to_array(shift);
    $class->__add_tag($attr, $_) for @tags;
  }

  no strict "refs";
  return %{ $$varname };
}

sub tags_for_attribute {
  my $class = _to_class(shift);
  my $varname = "${class}::_tags";

  no strict "refs";
  return @{ $$varname->{shift} };
}

sub attribute_has_tags {
  my $class = _to_class(shift);
  my $varname = "${class}::_tags";

  no strict "refs";
  return exists($$varname->{shift}) ? 1:0;
}

sub attributes_with_tag {
  my $class = _to_class(shift);
  my $tag_to_match = shift;
  my $varname = "${class}::_tags";

  my @matched = ();
  my %tags = $class->tags;
  foreach my $attr (keys %tags) {
    my @tags = $tags{$attr};
    push @matched, $attr if grep { $_ eq $tag_to_match } @tags;
  }

  return @matched;
}


 
1;
