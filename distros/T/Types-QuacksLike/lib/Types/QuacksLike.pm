package Types::QuacksLike;
use strict;
use warnings;

our $VERSION = '0.001001';
$VERSION =~ tr/_//d;

use Type::Library -base;
use Types::Standard qw(ClassName Object);

BEGIN {
  if ("$]" >= 5.010_000) {
    require mro;
    *_linear_isa = \&mro::get_linear_isa;
  }
  else {
    local $@;
    # we don't care about order so we can ignore c3
    eval <<'END_CODE' or die $@;
      sub _linear_isa($;$) {
        my $class = shift;
        my @check = ($class);
        my @lin;

        my %found;
        while (defined(my $check = shift @check)) {
          push @lin, $check;
          no strict 'refs';
          unshift @check, grep !$found{$_}++, @{"$check\::ISA"};
        }

        return \@lin;
      }
END_CODE
  }
}

BEGIN {
  local $@;
  if (eval { require Sub::Util; defined &Sub::Util::subname }) {
    *_stash_name = sub {
      my $name = Sub::Util::subname($_[0]);
      $name =~ s{::[^:]+\z}{};
      $name;
    };
  }
  else {
    require B;
    *_stash_name = sub {
      my ($coderef) = @_;
      ref $coderef or return;
      my $cv = B::svref_2object($coderef);
      $cv->isa('B::CV') or return;
      $cv->GV->isa('B::SPECIAL') and return;
      $cv->GV->STASH->NAME;
    };
  }
}

sub _methods_from_package {
  my $package = shift;
  no strict 'refs';
  my $does
    = $package->can('does') ? 'does'
    : $package->can('DOES') ? 'DOES'
    : undef;
  my $stash = \%{"${package}::"};
  return
    grep {
      my $code = \&{"${package}::$_"};
      my $code_stash = _stash_name($code) or next;

      /\A\(/
      or $code_stash eq $package
      or $code_stash eq 'constant'
      or $does && $package->$does($code_stash)
    }
    grep {
      my $entry = $stash->{$_};
      defined $entry && ref $entry ne 'HASH' && exists &{"${package}::$_"};
    } keys %$stash;
}

sub _methods_of {
  my $package = shift;
  my @methods;
  if ($INC{'Moo/Role.pm'} && Moo::Role->is_role($package)) {
    @methods = Moo::Role->methods_provided_by($package);
  }
  elsif ($INC{'Role/Tiny.pm'} && Role::Tiny->is_role($package)) {
    @methods = Role::Tiny->methods_provided_by($package);
  }
  elsif ($INC{'Class/MOP.pm'} and my $meta = Class::MOP::class_of($package)) {
    # classes
    if ($meta->can('get_all_method_names')) {
      @methods = $meta->get_all_method_names;
    }
    # roles
    elsif ($meta->can('get_method_list')) {
      @methods = $meta->get_method_list;
    }
    # packages
    elsif ($meta->can('list_all_symbols')) {
      @methods = $meta->list_all_symbols('CODE');
    }
  }
  else {
    my $moo_method;
    if ($INC{'Moo.pm'}) {
      $moo_method = Moo->can('is_class') ? 'is_class' : '_accessor_maker_for';
    }

    my %s;
    for my $isa (@{_linear_isa($package)}) {
      if ($moo_method && Moo->$moo_method($isa)) {
        push @methods, grep !$s{$_}++, keys %{ Moo->_concrete_methods_of($isa) };
      }
      else {
        push @methods, grep !$s{$_}++, _methods_from_package($isa);
      }
    }
  }

  return grep !/\A_/, sort @methods;
}

my $meta = __PACKAGE__->meta;
my $class_name = ClassName;

$meta->add_type({
  name    => "QuacksLike",
  parent  => Object,
  constraint_generator => sub {
    my @packages = map $class_name->assert_return($_), @_;
    return Object unless @packages;

    my %s;
    my @methods = sort grep !$s{$_}++, map _methods_of($_), @packages;

    require Type::Tiny::Duck;
    return Type::Tiny::Duck->new(
      methods      => \@methods,
      display_name => sprintf('QuacksLike[%s]', join q[,], map qq{"$_"}, @packages),
    );
  },
});

1;
__END__

=head1 NAME

Types::QuacksLike - Check for object providing all methods from a class or role

=head1 SYNOPSIS

  use Types::QuacksLike -all;

  {
    package MyClass;
    use Moo;
    sub my_method {}
  }

  my $duck_type = QuacksLike["MyClass"]; # same as HasMethods["my_method"];

=head1 DESCRIPTION

Check for object providing all methods from a class or role.

=head1 TYPES

=head2 QuacksLike[ $package ]

Generates a L<Type::Tiny::Duck> type requiring all of the methods that exist in
the given package.  Supports roles from L<Moose>, L<Moo>, and L<Role::Tiny>,
and classes from L<Moose>, L<Moo>, or standard perl. Methods beginning with an
underscore are considered private, and are not included.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2019 the Types::QuacksLike L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
