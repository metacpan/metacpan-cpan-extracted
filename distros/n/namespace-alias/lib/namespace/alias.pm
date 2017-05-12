use strict;
use warnings;

package namespace::alias;

use 5.008001;
use XSLoader;
use Class::MOP;
use B::Hooks::OP::Check;
use B::Hooks::EndOfScope;

our $VERSION = '0.02';

XSLoader::load(__PACKAGE__, $VERSION);

sub import {
    my ($class, $package, $alias) = @_;

    Class::MOP::load_class($package);

    ($alias) = $package =~ /(?:::|')(\w+)$/
        unless defined $alias;

    my $file = (caller)[1];

    my $hook = $class->setup($file => sub {
        my ($str) = @_;

        if ($str =~ s/^$alias\b/$package/) {
            return $str;
        }

        return;
    });

    on_scope_end {
        $class->teardown($hook);
    };
}

1;

__END__

=head1 NAME

namespace::alias - Lexical aliasing of namespaces

=head1 SYNOPSIS

  use namespace::alias 'My::Company::Namespace::Customer';

  # plain aliasing of a namespace
  my $cust = Customer->new;  # My::Company::Namespace::Customer->new

  # namespaces relative to the alias
  my $pref = Customer::Preferred->new;  # My::Company::Namespace::Customer::Preferred->new

  # getting the expansion of an alias
  my $customer_class = Customer;

  # also works for packages relative to the alias
  my $preferred_class = Customer::Preferred;

  # calling a function in an aliased namespace
  Customer::some_func()

=head1 DESCRIPTION

This module allows you to load packages and use them with a shorter name within
a lexical scope.

This is how you load a module and install an alias for it:

  use namespace::alias 'Some::Class';

This will load C<Some::Class> and install the alias C<Class> for it. You may
also specify the name of the alias explicitly:

  use namespace::alias 'Some::Class', 'MyAlias';

This will load C<Some::Class> and install the alias C<MyAlias> for it.

After installing the alias, every method or function call using it will be
expanded to the full namespace. Addressing namespaces relative to the aliased
namespace is also possible:

  MyAlias::Bar->new; # this expands to Some::Class::Bar->new

Aliases may also used as barewords. They will expand to a string with the full namespace:
To load a module and install an alias for it, do

  my $foo = MyAlias;       # 'Some::Class'
  my $bar = MyAlias::Bar;  # 'Some::Class::Bar'

This also means that function calls to aliased namespaces B<need> to be
followed with parens. If they aren't, they're expanded to strings instead.

  MyAlias::some_func();
  MyAlias::Bar::some_func();

Also note that the created aliases are lexical and available at compile-time
only. They may also shadow existing packages for the scope they are installed in:

  {
      package Foo::Bar;
      sub baz { 0xaffe }

      package Baz;
      sub baz { 42 }
  }

  Baz::baz(); # 42

  {
      use namespace::alias 'Foo::Bar', 'Baz';
      Baz::baz(); # 0xaffe
  }

  Baz::baz(); # 42

=head1 BUGS

Subroutine calls without parentheses around the argument list (e.g.,
C<Baz::baz> rather than C<Baz::baz()>), on names that work through
aliases, generally don't work on Perls prior to 5.11.2.  From Perl
5.11.2 onwards, aliases match the behaviour of ordinary package names
much better.

=head1 SEE ALSO

=over 4

=item L<aliased>

=back

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

With contributions from:

=over 4

=item Robert 'phaylon' Sedlacek E<lt>rs@474.atE<gt>

=item Steffen Schwigon E<lt>ss5@renormalist.netE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009  Florian Ragwitz

Licensed under the same terms as perl itself.

=cut
