use 5.008008;
use strict;
use warnings;

package portable::loader;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use portable::lib;

use Module::Pluggable (
	search_path => ['portable::loader'],
	sub_name    => '_plugins',
	require     => 1,
);

{
	my @loaders;
	sub loaders {
		my $me = shift;
		@loaders;
	}
	sub add_loader {
		my $me = shift;
		for my $loader (@_) {
			$loader->init($me) if $loader->can('init');
			push @loaders, $loader;
		}
	}
}

{
	my %extensions;
	sub extensions {
		%extensions;
	}
	sub register_extension {
		$extensions{$_[1]} = $_[2] || caller;
	}
}

sub _croak {
	my $me = shift;
	my ($msg, @args) = @_;
	require Carp;
	Carp::croak(sprintf($msg, @args));
}

sub _read {
	my $me = shift;
	my ($collection) = @_;
	for my $loader ($me->loaders) {
		my ($fn, $loaded) = $loader->load($collection);
		return ($fn, $loaded) if $loaded;
	}
	$me->_croak('Could not load portable collection %s', $collection);
}

{
	my $i = 0;
	sub _mint_prefix {
		++$i;
		"portable::collection::Collection$i";
	}
}

sub load {
	my $me = shift;
	my ($collection) = @_;

	my $file = $me->find_collection($collection);
	$me->_croak("Could not load collection $collection")
		unless defined $file;
	
	# method call preserving caller
	my $next = $me->can('load_from_filename');
	@_ = ($me, $file);
	goto $next;
}

sub find_collection {
	my $me = shift;
	my ($collection) = @_;
	my %exts = $me->extensions;
	DIR: for my $dir (@portable::INC) {
		EXT: for my $ext (sort keys %exts) {
			my $qualified = "$dir/$collection.$ext";
			return $qualified if -f $qualified;
		}
	}
	return;
}

sub load_from_filename {
	my $me = shift;
	my ($filename, $handler) = @_;
	
	return $portable::INC{$filename}
		if $portable::INC{$filename};
	
	unless (defined $handler) {
		my %exts = $me->extensions;
		for my $ext (sort keys %exts) {
			my $qext = quotemeta $ext;
			if ($filename =~ /$qext\z/) {
				$handler = $exts{$ext};
			}
		}
		$me->_croak("Could not find plugin to load file $filename")
			unless $handler;
	}
	
	my $hashref = $handler->parse($filename);
	$hashref->{____source____} = $filename;
	
	# method call preserving caller
	my $next = $me->can('load_from_hashref');
	@_ = ($me, $hashref);
	goto $next;
}

sub load_from_hashref {
	require MooX::Press;
	'MooX::Press'->VERSION('0.011');
	my $me = shift;
	my %opts = %{ $_[0] };
	$opts{prefix} ||= $me->_mint_prefix;
	$opts{factory_package} ||= $opts{prefix};
	$opts{caller} ||= caller;
	'MooX::Press'->import(%opts);
	my $return = $opts{factory_package} || $opts{caller};
	if ($opts{____source____}) {
		$portable::INC{$opts{____source____}} = $return;
	}
	$return;
}

# init
__PACKAGE__->add_loader($_) for __PACKAGE__->_plugins;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

portable::loader - load classes and roles which can be moved around your namespace

=head1 SYNOPSIS

Define some classes:

  ## Nature.portable
  ##
  version = 1.0
  toolkit = "Moo"
  
  [class:Tree.has]
  leaf = { is = "lazy", type = "ArrayRef[Leaf]" }
  
  [class:Tree.can]
  add_leaf = {{{
    my $self = shift;
    push @{ $self->leaf }, @_;
    return $self; # for chaining
  }}}
  _build_leaf = {{{
    return [];
  }}}
  
  [class:Leaf.has]
  colour = { type = "Str", default = "green" }
  
  [class:Maple]
  extends = "Tree"

Use the classes:

  ## script.pl
  ##
  use portable::lib '/var/lib/portable-libs';
  use portable::alias 'Nature';
  
  my $tree  = Nature->new_maple;
  $tree->add_leaf( Nature->new_leaf );
  
  # 'Nature' isn't really a Perl package.
  # It's just a sub that returns a string.

=head1 DESCRIPTION

The intent of portable::loader is for classes and roles to be portable around
your namespace. The idea is for classes and roles to not know their package
names and not care about their package names. And for them to also not know
or care about the package names of their "friends".

(When I say their friends, I'm talking about a user-agent object which needs
to be able to consume HTTP request objects and return HTTP response objects,
maybe write to a cookie jar object, etc.)

Typically in Perl code, package names are the one thing that is hard-coded
everywhere and this can make things like dependency injection, and API
versioning really difficult to do. Like if you need to make some major
changes to your class's API, do you create an entirely new package with
a different namespace, then wait for your consumers to update? Or do
you keep the old namespace and deal with breakages.

What if instead of doing this:

  use YourAPI::Tree;
  use YourAPI::Leaf;
  
  my $tree = YourAPI::Tree->new;
  $tree->add_leaf(YourAPI::Leaf->new);

People could do this?

  use portable::loader;
  my $api = portable::loader->load("YourAPI");
  
  my $tree = $api->new_tree;
  $tree->add_leaf($api->new_leaf);

The class names are not hard-coded anywhere. They are not even hard-coded
in the definitions of the Leaf and Tree classes.

And there's very little runtime overhead in doing this!

=head2 Writing a portable library

=head3 Syntax

Portable libraries are conceptually any hashref suitable for passing to
L<MooX::Press>. A structure something like this:

  {
    version => 1.0,
    toolkit => "Moo",
    "class:Tree" => {
      has => [
        "leaf" => { is => "lazy", type => "ArrayRef[Leaf]" },
      ],
      can => [
        "add_leaf" => sub {
          my $self = shift;
          push @{ $self->leaf }, @_;
          return $self; # for chaining
        },
        "_build_leaf" => sub {
          return [];
        },
      ],
    },
    "class:Leaf" => {
      has => [
        "colour" => { type => "Str", default => "green" },
      ],
    },
    "class:Maple" => {
      extends => "Tree",
    },
  }

You could save that as "Nature.portable.pl" and portable::loader would
be able to load it.

But although a library is conceptually a hashref, it can be written in
other syntaxes. It could be written in JSON, if L<JSON::Eval> is used to
inflate coderefs in the JSON:

  {
    "version": 1.0,
    "toolkit": "Moo",
    "class:Tree": {
      "has": [
        "leaf": { "is": "lazy", "type": "ArrayRef[Leaf]" }
      ],
      "can": [
        "add_leaf": {
          "$eval": "sub { my $self = shift; push @{ $self->leaf }, @_; return $self; }" 
        },
        "_build_leaf: {
          "$eval": "sub { return []; }"
        }
      ]
    },
    "class:Leaf": {
      "has": [
        "colour": { "type": "Str", "default": "green" }
      ],
    },
    "class:Maple": {
      "extends": "Tree"
    }
  }

If this is saved at "Nature.portable.json", portable::loader should
be able to load it.

The default format that L<portable::loader> uses though, is L<TOML>,
an INI-like file format. L<portable::loader> adds an extension to
TOML allowing C<< {{{ ... }}} >> to represent a coderef with Perl
code inside. (The parsing is kind of naive, so don't expect nested
coderefs to work and that kind of thing!

  version = 1.0
  toolkit = "Moo"
  
  [class:Tree.has]
  leaf = { is = "lazy", type = "ArrayRef[Leaf]" }
  
  [class:Tree.can]
  add_leaf = {{{
    my $self = shift;
    push @{ $self->leaf }, @_;
    return $self; # for chaining
  }}}
  _build_leaf = {{{
    return [];
  }}}
  
  [class:Leaf.has]
  colour = { type = "Str", default = "green" }
  
  [class:Maple]
  extends = "Tree"

=head3 Design considerations

When writing a library, the key thing to remember is that you don't
know the final package names of any of your classes and roles.

You can refer to other classes and roles from your library in type
constraints, and that should "just work".

Also, you can instantiate other classes in your methods using:

  [class:Maple.can]
  grow_red_leaf = {{{
    my $self = shift;
    my $leaf = $self->FACTORY->new_leaf(colour => "red");
    push @{ $self->leaf }, $leaf;
    return $self;
  }}}

The C<< $self->FACTORY >> method gives you something with a bunch
of C<< new_* >> methods for instantiating other objects from your
library.

You could even do this when defining the Leaf class:

  [class:Leaf.factory]
  new_leaf = {{{
    my ($factory, $class) = (shift, shift);
    return $class->new(@_);
  }}}
  new_red_leaf = {{{
    my ($factory, $class) = (shift, shift);
    return $class->new(colour => "red", @_);
  }}}

And then your Maple class can do this:

  [class:Maple.can]
  grow_red_leaf = {{{
    my $self = shift;
    my $leaf = $self->FACTORY->new_red_leaf;
    push @{ $self->leaf }, $leaf;
    return $self;
  }}}

The aim being for your Maple class to know as little as possible about how
to build a leaf other than "I can get one from the factory".

This makes it easy to override behaviour using L<Class::Method::Modifiers>
to wrap the C<new_red_leaf> method of the factory.

=head2 Loading a library

portable::loader maintains its own version of C<< @INC >> to locate libraries
from: C<< @portable::INC >>.

You can use L<portable::lib> to push directories onto it:

  use portable::lib '/var/lib/portable-libs';

Or you can manipulate C<< @portable::INC >> directly; it's just an array of
strings. You should C<< use portable::lib >> first though because portable::lib
will push some default directories onto C<< @portable::INC >> before it loads.

Once you've set your search paths, you can load a library like this:

  use portable::loader;
  my $lib = portable::loader->load($libname);

portable::loader will search for "$libname.portable.pl",
"$libname.portable.json", "$libname.portable.toml", or "$libname.portable"
(which will be assumed to be TOML). Other formats can be supported through
plugins. (API will eventually be documented.)

It will be parsed, loaded, classes built, etc, and a string will be returned
which can be used 

If more than one is found, only one will be loaded. The order in which they
are checked is currently not guaranteed, but the precedence of directories
in C<< @portable::INC >> will be respected.

There are also C<load_from_filename> and C<load_from_hashref> methods
if you already know the exact filename you want to load, or already have a
hashref.

=head3 Using portable::alias

This:

  use portable::alias "Foo";

Is roughly equivalent to this:

  use portable::loader;
  use constant "Foo" => portable::loader->load("Foo");

This:

  use portable::alias "VeryLongName" => "ShortName";

Means this:

  use constant "ShortName" => portable::loader->load("VeryLongName");

So you can do:

  my $thing = Foo->new_someclass(%args);

The "constant" exported by portable::alias isn't really a constant though.
It accepts arguments. You can do:

  my $thing = Foo("SomeClass")->new(%args);
  
  my $type_constraint = Foo("SomeClass");
  my $type_constraint = Foo("SomeRole");

Using L<portable::alias> is a cleaner-looking alternative to using
portable::loader in a lot of cases.

=head2 Using a library

Use the factory returned by portable::loader to create objects, then use the
objects according to the library's documentation.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=portable-loader>.

=head1 SEE ALSO

L<MooX::Press>, L<JSON::Eval>, L<TOML>, L<Type::Tiny>, L<Moo>, L<Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

