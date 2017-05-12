use 5.006001;
use strict;
use warnings;

package Types::LoadableClass;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Type::Library
	-base,
	-declare => qw(
		ModuleName LoadableClass LoadableRole
		ClassIsa ClassDoes ClassCan
	);

use Type::Utils -all;
use Types::Standard qw( StrMatch RoleName );

use Module::Runtime qw($module_name_rx is_module_name);
use Class::Load qw(load_optional_class is_class_loaded);

declare ModuleName,
	as StrMatch[ qr/\A$module_name_rx\z/ ],
	message {
		"'$_' is not a valid module name";
	};

declare LoadableClass,
	as ModuleName,
	where {
		load_optional_class($_)
	}
	inline_as {
		(undef, "Class::Load::load_optional_class($_)");
	}
	message {
		ModuleName->validate($_) or "'$_' could not be loaded";
	};

declare LoadableRole,
	as intersection([ LoadableClass, RoleName ]),
	message {
		LoadableClass->validate($_) or "'$_' is not a loadable role";
	};

declare ClassIsa,
	as LoadableClass,
	constraint_generator => sub {
		my @bases = @_ or return ClassIsa;
		return sub {
			$_[0]->isa($_) && return !!1 for @bases;
			return !!0;
		};
	},
	inline_generator => sub {
		my @bases = @_;
		return sub {
			my $var = $_[1];
			return (
				undef,
				sprintf(
					'(%s)',
					join(
						' or ',
						map(sprintf('%s->isa(%s)', $var, B::perlstring($_)), @bases),
					),
				),
			);
		};
	};

declare ClassDoes,
	as LoadableClass,
	constraint_generator => sub {
		my @roles = @_ or return ClassDoes;
		return sub {
			$_[0]->DOES($_) || return !!0 for @roles;
			return !!1;
		};
	},
	inline_generator => sub {
		my @roles = @_;
		return sub {
			my $var = $_[1];
			return (
				undef,
				sprintf(
					'do { my $method = %s->can("DOES")||%s->can("isa"); %s } ',
					$var,
					$var,
					join(
						' and ',
						map(sprintf('%s->$method(%s)', $var, B::perlstring($_)), @roles),
					),
				),
			);
		};
	};

declare ClassCan,
	as LoadableClass,
	constraint_generator => sub {
		my @methods = @_ or return ClassCan;
		return sub {
			$_[0]->can($_) || return !!0 for @methods;
			return !!1;
		};
	},
	inline_generator => sub {
		my @methods = @_;
		return sub {
			my $var = $_[1];
			return (
				undef,
				map(sprintf('%s->can(%s)', $var, B::perlstring($_)), @methods),
			);
		};
	};

__PACKAGE__->meta->add_coercion({
	name               => 'ExpandPrefix',
	type_constraint    => ModuleName,
	coercion_generator => sub {
		my ($self, $target, $prefix) = @_;
		Types::TypeTiny::StringLike->assert_valid($prefix);
		return (
			StrMatch[qr{\A-.+}],
			qq{ do { (my \$tmp = \$_) =~ s{\\A-}{$prefix\::}; \$tmp } },
		);
	}
});

1;

__END__

=pod

=encoding utf-8

=for stopwords Mannsåker

=head1 NAME

Types::LoadableClass - type constraints with coercion to load the class

=head1 SYNOPSIS

   package MyClass;
   use Moose;  # or Mouse, or Moo, or whatever
   use Types::LoadableClass qw/ LoadableClass /;
   
   has foobar_class => (
      is       => 'ro',
      required => 1,
      isa      => LoadableClass,
   );
   
   MyClass->new(foobar_class => 'FooBar'); # FooBar.pm is loaded or an
                                           # exception is thrown.

=head1 DESCRIPTION

A L<Type::Tiny>-based clone of L<MooseX::Types::LoadableClass>.

This is to save yourself having to do this repeatedly...

  my $tc = subtype as ClassName;
  coerce $tc, from Str, via { Class::Load::load_class($_); $_ };

Despite the abstract for this module, C<LoadableClass> doesn't actually
have a coercion, so no need to use C<< coerce => 1 >> on the attribute.
Rather, the class gets loaded as a side-effect of checking that it's
loadable.

=head2 Type Constraints

=over

=item C<< ModuleName >>

A subtype of C<Str> (see L<Types::Standard>) representing a string that
is a valid Perl package name (according to L<Module::Runtime>).

=item C<< LoadableClass >>

A subtype of C<ModuleName> that names a module which is either already
loaded (according to L<Class::Load>), or can be loaded (by
L<Class::Load>).

=item C<< LoadableRole >>

A subtype of C<LoadableClass> that names a module which appears to be
a role rather than a class.

(Because this type constraint is designed to work with Moose, Mouse,
Moo, or none of the above, it can't rely on the features of any
particular implementation of roles. Therefore is needs to use a
heuristic to detect whether a loaded package represents a role or not.
Curently this heuristic is the absence of a method named C<new>.)

=item C<< ClassIsa[`a] >>

A subtype of C<LoadableClass> which checks that the class is a subclass
of a given base class:

   ClassIsa["MyApp::Plugin"]

Multiple base classes may be provided. A class only needs to satisfy one
isa to pass the type constraint check.

   ClassIsa["MyApp::Plugin", "YourApp::Plugin"]

=item C<< ClassDoes[`a] >>

A subtype of C<LoadableClass> which checks that the class performs a
given role. (This uses L<UNIVERSAL/"DOES">.) If multiple roles are
given, the class must perform all of them.

   ClassDoes["MyApp::Role::Loadable", "MyApp::Role::Dumpable"]

=item C<< ClassCan[`a] >>

A subtype of C<LoadableClass> which checks that the class provides
particular methods:

   ClassCan[ qw( new load dump ) ]

=back

=head2 Type Coercions

The following named coercion can be exported:

=over

=item C<< ExpandPrefix[`a] >>

A coercion to expand class name abbreviations starting with a dash using
a given prefix.

   my $type = LoadableClass->plus_coercions(ExpandPrefix["Foo"]);
   say $type->coerce( "-Bar" );    # Foo::Bar
   say $type->coerce(  "Baz" );    # Baz

=back

If accepting class names from somewhere, it can be useful to provide a
"default namespace" to avoid Really::Long::Package::Names::Everywhere.
Here's an example of how you can do that:

   use strict; use warnings; use feature qw( say );
   
   package MyApp {
      use Moose;
      use Types::LoadableClass qw( ClassDoes ExpandPrefix );
      use Types::Standard qw( ArrayRef StrMatch );
      
      my $plugin_class = (
         ClassDoes["MyApp::Role::Plugin"]
      ) -> plus_coercions (
         ExpandPrefix[ "MyApp::Plugin" ]
      );
      
      has plugins => (
         is     => 'ro',
         isa    => ArrayRef[ $plugin_class ],
         coerce => 1,
      );
   }
   
   my $app = MyApp->new(
      plugins => [qw( -Foo -Bar MyApp::Baz )],
   );
   
   say for @{ $app->plugins };   # MyApp::Plugin::Foo
                                 # MyApp::Plugin::Bar
                                 # MyApp::Baz

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-LoadableClass>.

=head1 SEE ALSO

L<Types::Standard>, L<MooseX::Types::LoadableClass>, L<Class::Load>,
L<Module::Runtime>.

=head1 AUTHOR

Dagfinn Ilmari Mannsåker E<lt>ilmari@ilmari.orgE<gt>.

Improvements, packaging, and additions by Toby Inkster
E<lt>tobyink@cpan.orgE<gt>.

The C<ClassIsa>, C<ClassDoes>, and C<ClassCan> types are based on
L<suggestions|https://rt.cpan.org/Ticket/Display.html?id=91802> by
Benct Philip Jonsson.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Dagfinn Ilmari Mannsåker,
Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

