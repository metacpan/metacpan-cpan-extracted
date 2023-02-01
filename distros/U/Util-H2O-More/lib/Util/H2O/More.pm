use strict;
use warnings;

package Util::H2O::More;
use parent q/Exporter/;

our $VERSION = q{0.2.8};

our @EXPORT_OK = (qw/baptise opt2h2o h2o o2h d2o o2d o2h2o ini2h2o h2o2ini Getopt2h2o/);

use Util::H2O ();

use feature 'state';

# quick hack to export h2o, uses proper
# Util::H2O::h2o called with full namespace
sub h2o {
    return Util::H2O::h2o @_;
}

# maintains basically a count to create non-colliding
# unique $pkg names (basically what Util::H2O::h2o does
# if $pkg is not specified using -class
# monatomically increasing uuid
sub _uuid {
    state $uuid = 0;
    return ++$uuid;
}

# non-recursive option
sub baptise ($$@) {
    my ( $ref, $pkg, @default_accessors );
    my $pos0 = shift;

    # check pos0 for '-recurse'
    if ( $pos0 eq q{-recurse} ) {
        ( $ref, $pkg, @default_accessors ) = @_;
    }
    else {
        $ref = $pos0;
        ( $pkg, @default_accessors ) = @_;
    }

    my $self;
    my $real_pkg = sprintf qq{%s::_%s}, $pkg, _uuid;

    # uses -isa to inherit from $pkg; -class to bless with a package name
    # derived from $pkg
    if ( $pos0 eq q{-recurse} ) {
        $self = h2o -recurse, -isa => $pkg, -class => $real_pkg, $ref, @default_accessors;
    }
    else {
        $self = h2o -isa => $pkg, -class => $real_pkg, $ref, @default_accessors;
    }

    return $self;
}

# preconditioner for use with Getopt::Long flags; returns just the flag name given
# a list of option descriptors, e.g., qw/option1=s option2=i option3/;

# Getopts to keys
sub opt2h2o(@) {
    my @getopt_def = @_;
    my @flags_only = map { m/([^=|\s]+)/g; $1 } @getopt_def;
    return @flags_only;
}

# wrapper around opt2h2o (yeah!)
sub Getopt2h2o(@) {
  my ($ARGV_ref, $defaults, @opts) = @_;
  $defaults //= {};
  my $o = h2o $defaults, opt2h2o(@opts);
  require Getopt::Long;
  Getopt::Long::GetOptionsFromArray( $ARGV_ref, $o, @opts ); # Note, @ARGV is passed by reference
  return $o;
}

# general form of method used to give accessors to Config::Tiny in Util::H2O's
# POD documentation
sub o2h2o ($) {
    my $ref = shift;
    return h2o -recurse, { %{$ref} };
}

# more specific helper app that uses Config::Tiny->read and o2h2o to get a config
# object back from an .ini; requries Config::Tiny
sub ini2h2o ($) {
    my $filename = shift;
    require Config::Tiny;
    return o2h2o( Config::Tiny->read($filename) );
}

# write out the INI file
sub h2o2ini ($$) {
    my ( $config, $filename ) = @_;
    require Config::Tiny;
    return Config::Tiny->new( Util::H2O::o2h $config)->write($filename);
}

# return a dereferences hash (non-recursive); reverse of `h2o'
sub o2h($) {
    $Util::H2O::_PACKAGE_REGEX = qr/::_[0-9A-Fa-f]+\z/;    # makes internal package name more generic for baptise created references
    my $ref = Util::H2O::o2h @_;
    if ( ref $ref ne q{HASH} ) {
        die qq{Could not fully remove top-level reference. Probably an issue with \$Util::H2O_PACKAGE_REGEX\n};
    }
    return $ref;
}

sub d2o($);    # forward declaration to get rid of "too early" warning
sub a2o($);

sub d2o($) {
    my $thing = shift;
    my $isa   = ref $thing;
    if ( $isa eq q{ARRAY} ) {
        a2o $thing;
        foreach my $element (@$thing) {
            d2o $element;
        }
    }
    elsif ( $isa eq q{HASH} ) {
        foreach my $keys ( keys %$thing ) {
            d2o( $thing->{$keys} );
        }

        # package level wrapper, so this can be monkey patched
        # if so desired, per documentation
        h2o $thing;
    }
    return $thing;
}

# blesses ARRAY ref as a container and gives it some virtual methods
# useful in the context of containing HASH refs that get objectified
# by h2o
sub a2o($) {
    no strict 'refs';

    my $array_ref = shift;

    # uses lexical scop of the 'if' to a bless $array_ref (an ARRAY ref)
    # and assigns to it some virtual methods for making dealing with
    # the "lists of C<HASH> references easier, as a container

    my $a2o_pkg = sprintf( qq{%s::__a2o_%d::vmethods}, __PACKAGE__, int rand 100_000_000 );    # internal a2o

    bless $array_ref, $a2o_pkg;

    ## add vmethod to wrap around array_refs

    # return item at index INDEX
    my $GET = sub { my ( $self, $i ) = @_; return $self->[$i]; };
    *{"${a2o_pkg}::get"} = $GET;

    # return rereferenced ARRAY
    my $ALL = sub { my $self = shift; return @$self; };
    *{"${a2o_pkg}::all"} = $ALL;

    # returns value returned by the 'scalar' keyword
    my $SCALAR = sub { my $self = shift; return scalar @$self; };
    *{"${a2o_pkg}::scalar"} = $SCALAR;

    # 'push' will apply "d2o" to all elements pushed
    my $PUSH = sub { my ( $self, @i ) = @_; d2o \@i; push @$self, @i; return \@i };
    *{"${a2o_pkg}::push"} = $PUSH;

    # 'pop' intentionally does NOT apply "o2d" to anyarray_ref pop'd
    my $POP = sub { my $self = shift; return pop @$self };
    *{"${a2o_pkg}::pop"} = $POP;

    # 'unshift' will apply "d2o" to all elements unshifted
    my $UNSHIFT = sub { my ( $self, @i ) = @_; d2o \@i; unshift @$self, @i; return \@i };
    *{"${a2o_pkg}::unshift"} = $UNSHIFT;

    # 'shift' intentionally does NOT apply "o2d" to anyarray_ref shift'd
    my $SHIFT = sub { my $self = shift; return shift @$self };
    *{"${a2o_pkg}::shift"} = $SHIFT;

    return $array_ref;
}

# includes internal dereferencing so to be compatible
# with the behavior of Util::H2O::o2h
sub o2d($);    # forward declaration to get rid of "too early" warning

sub o2d($) {
    my $thing = shift;
    return $thing if not $thing;
    my $isa = ref $thing;
    if ( $isa =~ m/^Util::H2O::More::__a2o/ ) {
        my @_thing = @$thing;
        $thing = \@_thing;
        foreach my $element (@$thing) {
            $element = o2d $element;
        }
    }
    elsif ( $isa =~ m/^Util::H2O::_/ ) {
        foreach my $key ( keys %$thing ) {
            $thing->{$key} = o2d $thing->{$key};
        }
        $thing = Util::H2O::o2h $thing;
    }
    return Util::H2O::o2h $thing;
}

1;

__END__

=head1 NAME

Util::H2O::More - provides C<baptise>, a drop-in replacement for
C<bless>; like if C<bless> created accessors for you. This module
also provides additional methods built using C<h2o> or C<o2h> from
L<Util::H2O> that allow for the incremental addition of I<OOP> into
existing or small scale Perl code without having to fully commit
to a Perl I<OOP> framework or compromise one's personal Perl style.

C<Util::H2O::More> now provides a wrapper method now, C<d2o>
that will find and I<objectify> all C<HASH> refs contained in
C<ARRAY>s at any level, no matter how deep. This ability is
very useful for dealing with modern services that return C<ARRAY>s
of C<HASH>, traditional L<DBI> queries, and other modules that can
provide C<LIST>s of C<HASH> refs,  such as L<Web::Scraper>.

=head1 SYNOPSIS 

It is easy to create an I<OOP> module using C<baptise> instead of
C<bless>, which means it includes accessors (thanks to C<Util::H2O::h2o>).
In most cases, C<baptise> can be used as a drop-in replacement for
C<bless>.

Below is an example of a traditional Perl OOP class constructor
using C<baptise> to define a set of default accessors, in addition
to any that are created by virtue of the C<%opts> passed.

    use strict;
    use warnings;
    
    package Foo::Bar;

    # exports 'h2o' also
    use Util::H2O::More qw/baptise/;
      
    sub new {
      my $pkg    = shift;
      my %opts   = @_;
      
      # replaces bless, defines default constructures and creates
      # constructors based on what's passed into %opts
      
      my $self = baptise \%opts, $pkg, qw/bar haz herp derpes/;
       
      return $self;
    }
     
    1;

Then on a caller script,

    use strict;
    use warnings;
     
    use Foo::Bar;
     
    my $foo = Foo::Bar->new(some => q{thing}, else => 4);
     
    print $foo->some . qq{\n};
     
    # set bar via default accessor
    $foo->bar(1);
    print $foo->bar . qq{\n};
    
    # default accessors also available from the class defined
    # above,
    #   $foo->haz, $foo->herp, $foo->derpes
    
    # and from the supplied tuple,
    #   $foo->else

For more examples, please look at the classes created for the unit
tests contained in C<t/lib>.

NB: There are other useful methods, so please read all of the POD.
This section simply covers C<baptise>, which was the first method
based on C<Util::H2O::h2o> presented in this module. 

=head1 DESCRIPTION

The primary method, C<baptise>, essentially provides the same
interface as the core keyword C<bless> with an additional I<slurpy>
third parameter where one may specify a list of default accessors.

Ultimately C<h2o> provides a very compelling approach that allows
one to incrementally add I<OOP> into their Perl. At the very least
it makes dealing with C<HASH> references much easier, and without
the committment to a full Perl I<OOP> framework. Perl is meant to
be I<multi-paradigm>, which means that it should be easy to mix the
best of different methods into one glorious creation. L<Util::H2O>,
and by extension, C<Util::H2O::More>; seeks to accomplish making it
possible for I<OOP> concepts.

C<Util::H2O::h2o> is a deceptively powerful tool that, above all, makes
it I<easy> and I<fun> to add accessors to I<ad hoc> C<HASH>references
that many Perl developers like to use and that get returned,
I<unblessed> by many popular modules. For example, L<HTTP::Tiny>,
L<Web::Scraper>, and the more common I<select%> methods L<DBI>
flavors implement. In particular, any L<JSON> returned by a
L<HTTP::Tiny> web request is not just ublessed, but still serialized.
Yet another great example is the configuration object returned by
the very popular module, L<Config::Tiny>.

Still more useful utilities may be built upon C<h2o>, e.g.; C<d2o>
which is able to handle data structures that contain C<HASH> references
buried or nested arbitrarily within C<ARRAY> references.

For example, C<d2o> cleans things up very nicely for dealing with
web APIs:

  my $response = h2o HTTP::Tiny->get($JSON_API_URL);
  die if not $response->success; 
  my $JSON_data_with_accessors = d2o JSON::decode_json $response->content;

Finally, and what started this module; the usage pattern of C<h2o>
begs it to be able to support being used as a I<drop in> replacement
for C<bless>.  But is does a fine job as serving
as the I<basis> for a I<better bless>.

=head1 METHODS

=head2 C<baptise REF, PKG, LIST>

Takes the same first 2 parameters as C<bless>; with the addition
of a list that defines a set of default accessors that do not
rely on the top level keys of the provided hash reference.

The B<-recurse> option:

Like C<baptise>, but creates accessors recursively for a nested
hash reference. Uses C<h2o>'s C<-recurse> flag.

Note: The accessors created in the nested hashes are handled
directly by C<h2o> by utilizing the C<-recurse> flag. This means
that they will necessarily be blessed using the unchangable
behavior of C<h2o>, which maintains the name space of C<Util::H2O::_$hash>
even if C<h2o> is passed with the C<-isa> and C<-class> flags,
which are both utilized to achieve the effective outcome of
C<baptise> and C<bastise -recurse>.

=head2 C<Getopt2h2o REF, REF, LIST>

Wrapper around the idiom enabled buy C<opt2h2o>. It even will C<require>
C<Getopts::Long>. Usage:

  use Util::H2O::More qw/Getopt2h2o/;
  my $opts_ref = Getopt2h2o \@ARGV, { n => 10 }, qw/f=s n=i/;

The first argument is the a refernece to the C<@ARGV> array (or equivalent),
the second argument is the initial state of the hash to be objectified by
C<h2o>, the rest of the arguments is an array containing the C<Getopt::Long>
argument description.

This methods was created because even C<opt2h2o> was too much typing :-).

=head2 C<opt2h2o LIST>

Handy function for working with C<Getopt::Long>, which takes a list of options
meant for C<Getopt::Long>; and extracts the flag names so that they may be
used to create default accessors without having more than one list. E.g.,

    use Getopt::Long qw//;
    my @opts = (qw/option1=s options2=s@ option3 option4=i o5|option5=s/);
    my $o = h2o {}, opt2h2o(@opts);
    Getopt::Long::GetOptionsFromArray( \@ARGV, $o, @opts ); # Note, @ARGV is passed by reference
    
    # now options are all available as accessors, e.g.:
    if ($o->option3) {
      do_the_thing();
    }

Note: default values for options may still be placed inside of the anonymous
hash being I<objectified> via C<h2o>. This will work perfectly well with
C<baptise> and friends.

    use Getopt::Long qw//;
    my @opts = (qw/option1=s options2=s@ option3 option4=i o5|option5=s/);
    my $o = h2o { option1 => q{foo} }, opt2h2o(@opts);
    Getopt::Long::GetOptionsFromArray( \@ARGV, $o, @opts ); # Note, @ARGV is passed by reference 

    # ...
    # now $o can be used to query all possible options, even if they were
    # never passed at the commandline 

=head2 C<ini2h2o FILENAME>

Takes the name of a file, uses L<Config::Tiny> to open it, then gives it
accessors using internally, C<o2h2o>, described below.

Given some configuration file using INI:

  [section1]
  var1=foo
  var2=bar
  
  [section2]
  var3=herp
  var4=derp

We can parse it with L<Config::Tiny> and objectify it with C<h2o>:

  use Util::H2O::More qw/ini2h2o/;
  my $config = ini2h2o qq{/path/to/my/config.ini}
  # ... $config now has accessors based Config::Tiny's read of config.ini

=head2 C<h2o2ini REF, FILENAME>

Takes and object created via C<ini2h2o> and writes it back out to C<FILENAME>
in the proper I<INI> format, using L<Config::Tiny>.

Given the example in C<ini2h2o>, we can go a step further and writ eout a new
configuration file after reading it and modifying a value.

  use Util::H2O::More qw/ini2h2o h2o2ini/;

  my $config = ini2h2o q{/path/to/my/config.ini}

  # update $config, write it out as a different file
  $config->section1->var1("some new value");
  h2o2ini $config, q{/path/to/my/other-config.ini};

=head2 C<o2h2o REF>

Primarily inspired by L<Util::H2O>'s example for adding accessors to an
reference that has already been blessed by another package. The motivating
example is one that shows how to add accessors to a L<Config::Tiny> object.

=head2 C<o2h REF>

Uses C<Util::H2O::o2h>, so behaves identical to it.  A new hash reference
is returned, unlike C<h2o> or C<baptise>. See C<Util::H2O>'s POD for
a lot more information.

This method complements C<h2o> or C<baptise> very well in the sitution,
e.g., when one is dealing with an ad hoc object that then needs to be
sent as a serialzied JSON string. It's convenient to be able to get
the un<bless>'d data structure most JSON encoding methods are expecting.

B<Implementation note:>

Access to C<Util::H2O::o2h>, but adjusts C<$Util::H2O::_PACKAGE_REGEX> to
accept package names that are generated by C<baptise>. This effectively
is an I<unbless>.

B<Historical Note:>

C<Util::H2O::More::o2h> preceded C<Util::H2O::o2h>, and the author
of the latter added it after seeing it's usefulness in cases where
the ability to get a pure C<HASH> reference after having I<objectified>
was useful. A good example is the standard dislike C<JSON> modules'
C<encode_json> method implementations have for blessed references;
this also affects environments like L<Dancer2> or L<Mojo> that
employ automatic serialization steps beyond route handlers. Returning
a blessed reference would cause the underlying serialization routines
to warn or C<die> without using C<o2h> to return a pure C<HASH>
reference.

=head2 C<d2o REF>

This method is basically a wrapper around C<h2o> that will traverse
an arbitrarily complex Perl data structure, applying C<h2o> to any
C<HASH> references along the way.

A common usecase where C<d2o> is useful is a web API call that returns
some list of C<HASH> references contained inside of an C<ARRAY> reference. 

For example,

  my $array_of_hashes = JSON::decode_json $json;
  d2o $array_of_hashes;
  my $co = $array_of_hashes->[3]->company->name;

Here, C<$array_of_hashes> is an C<ARRAY> reference that contains a set
of elements that are C<HASH> references; a pretty common situation when
dealing with records from an API or database call.  C<[3]>, refers the
4th element, which is a C<HASH> reference. This C<HASH> reference has
an accessor via C<d2o>, and this returns another C<HASH> that has an
accessor called C<name>.

The structure of C<$array_of_hashes> is based on JSON, e.g., that is of
the form:

  [
    {
      "id": 1,
      "name": "Leanne Graham",
      "username": "Bret",
      "email": "Sincere@april.biz",
      "address": {
        "street": "Kulas Light",
        "suite": "Apt. 556",
        "city": "Gwenborough",
        "zipcode": "92998-3874",
        "geo": {
          "lat": "-37.3159",
          "lng": "81.1496"
        }
      },
      "phone": "1-770-736-8031 x56442",
      "website": "hildegard.org",
      "company": {
        "name": "Romaguera-Crona",
        "catchPhrase": "Multi-layered client-server neural-net",
        "bs": "harness real-time e-markets"
      }
    },
    {
      "id": 2,
      "name": "Ervin Howell",
      "username": "Antonette",
      "email": "Shanna@melissa.tv",
      "address": {
        "street": "Victor Plains",
        "suite": "Suite 879",
        "city": "Wisokyburgh",
        "zipcode": "90566-7771",
        "geo": {
          "lat": "-43.9509",
          "lng": "-34.4618"
        }
      },
      "phone": "010-692-6593 x09125",
      "website": "anastasia.net",
      "company": {
        "name": "Deckow-Crist",
        "catchPhrase": "Proactive didactic contingency",
        "bs": "synergize scalable supply-chains"
      }
    },
    ...
  ]

  (* froms, https://jsonplaceholder.typicode.com/users)

=head3 C<h2o>'s C<-array> Modifier

As of version 0.20 of L<Util::H2O>, C<h2o> has now a C<-arrays> modifier 
that does something very similar to C<d2o>, which was released shortly after
C<-arrays> was released in L<Util::H2O>. Had the author of this module known
about it, he would not have created C<d2o>. Nonetheless, C<d2o> does some
things C<-arrays> doesn't do (and similarly, when C<o2h -arrays> versus 
C<o2d>).

The biggest difference seems to be that C<h2o> doesn't bless the C<ARRAY> 
containers or provide virtual methods. Be advised, however, C<-arrays>
is probably sufficient for the use case C<d2o> was originally create for;
i.e., to more easily I<objectify> complicated data structures obtained from
things like JSON returned from web APIs. the virtual methods added to C<ARRAY>s
is not something one would expect form C<h2o>, which strives to provide a
I<lite> or I<tiny> touch. The vmethods do make iterating over the C<ARRAY>s
easier, though.

=head2 C<o2d REF>

Does for data structures I<objectified> with C<d2o> what C<o2h> does
for objects created with C<h2o>. It only removes the blessing from
C<Util::H2O::> and C<Util::H2O::More::__a2o> references.

=head2 C<a2o REF>

Used internally.

Used internally to give I<virual methods> to C<ARRAY> ref containers
potentially holding C<HASH> references.

C<a2o> is not intended to be useful outside of the context of C<d2o>,
but it's exposed in case it is, anyway.

=head2 C<ARRAY> container I<vmethods>

It is still somewhat inconvenient, though I<idiomatic>, to refer to C<ARRAY>
elements directly as in the example above. However, it is still inconsistent
with idea of C<Util::H2O>. So, C<d2o> leans into its I<heavy> nature by adding
some "virtual" methods to C<ARRAY> containers.

=head3 C<all>

Returns a LIST of all items in the C<ARRAY> container.
 
  my @items = $root->some-barray->all;

=head3 C<get INDEX>

Given an C<ARRAY> container from C<d2o>, returns the element at the given
index. See C<push> example below for a practical example.

=head3 C<push LIST>

Pushes LIST onto ARRAY attached to the vmethod called; also applies the
C<d2o> method to anything I<pushed>.

  my @added = $root->some->barray->push({ foo => 1 }, {foo => 2});
  my $one   = $root->some->barray->get(0)->foo; # returns 1 via "get"
  my $two   = $root->some->barray->get(1)->foo; # returns 2 via "get"

Items that are C<push>'d are returned for convenient assignment.

=head3 C<pop>

Pops an element from C<ARRAY> container available after applying C<d2o> to
a structure that has C<ARRAY> refs at any level.

  my $item = $root->some-barray->pop;

=head3 C<unshift LIST>

Similar to C<push>, just operates on the near end of the C<ARRAY>.

Items that are C<shift>'d are returned for convenient assignment.

=head3 C<shift>

Similar to C<pop>, just operates on the near end of the C<ARRAY>.

=head3 C<scalar>

Returns the number of items in the C<ARRAY> container, which is more
convenient that doing,

  my $count = scalar @{$root->some->barray->all}; 


=head1 EXTERNAL METHODS

=head2 C<h2o>

Because C<Util::H2O::More> exports C<h2o> as the basis for its
operations, C<h2o> is also available without needing to qualify
its full name space.

=head1 DEPENDENCIES

=head2 L<Util::H2O>

Requires C<Util::H2O> because this module is effectively a wrapper
around C<h2o>.

It also uses the C<state> keyword, which is only available in perls
>= 5.10.

While some methods are designed to work with external modules, e.g.,
C<opt2h2o> is meant to work with L<Getopt::Long>; at this time there
are no dependencies for such methods required by C<Util::H2O::More>
itself.

=head1 BUGS

No. I mean maybe. Buyer beware.

=head1 LICENSE AND COPYRIGHT 

Perl/perl

=head1 ACKNOWLEDGEMENTS

Thank you to HAUKEX for creating L<Util::H2O> and hearing me out
on its usefulness for some unintended use cases.

=head1 AUTHOR

Oodler 577 L<< <oodler@cpan.org> >> 
