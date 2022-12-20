use strict;
use warnings;

package Util::H2O::More;
use parent q/Exporter/;

our $VERSION = q{0.1};

our @EXPORT_OK = (qw/baptise opt2h2o h2o o2h h3o o3h/);

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

# flags to keys
sub opt2h2o(@) {
    my @getopt_def = @_;
    my @flags_only = map { m/([^=|\s]+)/g; $1 } @getopt_def;
    return @flags_only;
}

# return a dereferences hash (non-recursive); reverse of `h2o'
sub o2h($) {

    # makes internal package name more generic for baptise created references
    $Util::H2O::_PACKAGE_REGEX = qr/::_[0-9A-Fa-f]+\z/;
    my $ref = Util::H2O::o2h @_;
    if ( ref $ref ne q{HASH} ) {
        die qq{Could not fully remove top-level reference. Probably an issue with \$Util::H2O_PACKAGE_REGEX\n};
    }
    return $ref;
}

# traverses a all ARRAY and HASH references in a data structure reference,
# looking for HASH references to bless using h2o; basically it's C<h2o -recurse>
# on performance enhancing drugs

## Notes on implementation
# * Interface - should accept all things h2o does [what about default accessors?]
# * All hash refs should get accessors (what about default accessors?)
# * all arrays to get an vmethod that returns all elements in it
# * anything not ARRAY or HASH should be untouched

sub h3o($);    # forward declaration to get rid of "too early" warning

sub h3o($) {
    my $thing = shift;
    my $isa   = ref $thing;
    if ( $isa eq q{ARRAY} ) {

        # uses lexical scop of the 'if' to a bless $thing (an ARRAY ref)
        # and assigns to it some virtual methods for making dealing with
        # the "lists of C<HASH> references easier, as a container
        no strict 'refs';
        my $a2o_pkg = sprintf( qq{%s::_a2o_%d}, __PACKAGE__, int rand 100_000 );    # internal a2o
        bless $thing, $a2o_pkg;

        # add vmethod to wrap around things
        my $GET    = sub { my ( $self, $i ) = @_; return $self->[$i]; };
        my $ALL    = sub { my $self = shift; return @$self; };
        my $SCALAR = sub { my $self = shift; return scalar @$self; };

        # 'push' will apply "h3o" to all elements pushed
        my $PUSH = sub { my ( $self, @i ) = @_; h3o \@i; push @$self, @i; return \@i };

        # 'pop' intentionally does NOT apply "o3h" to anything pop'd
        my $POP = sub { my $self = shift; return pop @$self };

        # 'unshift' will apply "h3o" to all elements unshifted
        my $UNSHIFT = sub { my ( $self, @i ) = @_; h3o \@i; unshift @$self, @i; return \@i };

        # 'shift' intentionally does NOT apply "o3h" to anything shift'd
        my $SHIFT = sub { my $self = shift; return shift @$self };
        *{"${a2o_pkg}::get"}     = $GET;
        *{"${a2o_pkg}::all"}     = $ALL;
        *{"${a2o_pkg}::scalar"}  = $SCALAR;
        *{"${a2o_pkg}::push"}    = $PUSH;
        *{"${a2o_pkg}::pop"}     = $POP;
        *{"${a2o_pkg}::unshift"} = $UNSHIFT;
        *{"${a2o_pkg}::shift"}   = $SHIFT;

        foreach my $element (@$thing) {
            h3o $element;
        }
    }
    elsif ( $isa eq q{HASH} ) {
        foreach my $keys ( keys %$thing ) {
            h3o( $thing->{$keys} );
        }

        # package level wrapper, so this can be monkey patched
        # if so desired, per documentation
        h2o $thing;
    }
    return $thing;
}

# includes internal dereferencing so to be compatible
# with the behavior of Util::H2O::o2h
sub o3h($);    # forward declaration to get rid of "too early" warning

sub o3h($) {
    my $thing = shift;
    no warnings 'prototype';
    return $thing if not $thing;
    my $isa = ref $thing;
    if ( $isa eq q{ARRAY} ) {
        my @_thing = @$thing;
        foreach my $element (@_thing) {
            $element = o3h($element);
        }
    }
    elsif ( $isa eq q{HASH} ) {
        my %_thing = %$thing;
        foreach my $key ( keys %_thing ) {
            $_thing{$key} = o3h( $_thing{$key} );
        }
        $thing = Util::H2O::o2h \%_thing;
    }
    return Util::H2O::o2h $thing;
}

1;

__END__

=head1 NAME

Util::H2O::More - provides C<baptise>, a drop-in replacement for
C<bless>; like if C<bless> created accessors for you. This module
also provides additional methods built using C<h2o> or C<o2h> from
L<Util::H2O>.

C<Util::H2O::More> also provides a wrapper method now, C<h3o>
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

=head2 Why Was This Created?

The really short answer: because C<h2o> doesn't play nice
inside of the traditional Perl OOP constructor (C<new>) idiom.
This is not C<h2o>'s fault. This is my fault for wanting to use
it to do something it was never meant to do.

Implied above is that I wanted to maintain the usage pattern of
C<bless>, but extend it to include the generation of accessors.
I wanted a I<better bless>.

The long answer...

C<h2o> is a deceptively powerful tool that, above all, makes
it I<easy> and I<fun> to add accessors to I<ad hoc> hash references
that many Perl developers like to use and that get emitted,
I<unblessed> by many popular modules. For example, C<HTTP::Tiny>,
C<Web::Scraper>, and the more common I<select%> methods C<DBI>
flavors implement. In particular, any C<JSON> returned by a
C<HTTP::Tiny> web request is not just ublessed, but still serialized.

Still more useful utilities may be built upon C<h2o>, e.g.; C<h3o>
which is able to handle data structures that contain C<HASH> references
buried or nested arbitrarily within C<ARRAY> references.

For example, C<h3o> cleans things up very nicely for dealing with
web APIs:

  my $response = h2o HTTP::Tiny->get($JSON_API_URL);
  die if not $response->success; 
  my $JSON_data_with_accessors = h3o JSON::decode_json $response->content;

Finally, and what started this module; the usage pattern of C<h2o>
begs it to be able to support being used as a I<drop in> replacement
for C<bless>.  But is does a fine job as serving
as the I<basis> for a I<better bless>.

=head1 METHODS

=over 4

=item C<baptise $hash_ref, $pkg, LIST>

Takes the same first 2 parameters as C<bless>; with the addition
of a list that defines a set of default accessors that do not
rely on the top level keys of the provided hash reference.

=item C<baptise -recurse, $hash_ref, $pkg, LIST>

Like C<baptise>, but creates accessors recursively for a nested
hash reference. Uses C<h2o>'s C<-recurse> flag.

Note: The accessors created in the nested hashes are handled
directly by C<h2o> by utilizing the C<-recurse> flag. This means
that they will necessarily be blessed using the unchangable
behavior of C<h2o>, which maintains the name space of C<Util::H2O::_$hash>
even if C<h2o> is passed with the C<-isa> and C<-class> flags,
which are both utilized to achieve the effective outcome of
C<baptise> and C<bastise -recurse>.

=item C<opt2h2o LIST>

Handy function for working with C<Getopt::Long>, which takes
a list of options meant for C<Getopt::Long>; and extracts the
flag names so that they may be used to create default accessors
without having more than one list. E.g.,

    use Getopt::Long qw//;
    my @opts = (qw/option1=s options2=s@ option3 option4=i o5|option5=s/);
    my $o = h2o {}, opt2h2o(@opts);
    Getopt::Long::GetOptionsFromArray( \@ARGV, $o, @opts ); # Note, @ARGV is passed by reference
    
    # now options are all available as accessors, e.g.:
    if ($o->option3) {
      do_the_thing();
    }

Note: default values for options may still be placed inside
of the anonymous hash being I<objectified> via C<h2o>. This
will work perfectly well with C<baptise> and friends.

    use Getopt::Long qw//;
    my @opts = (qw/option1=s options2=s@ option3 option4=i o5|option5=s/);
    my $o = h2o { option1 => q{foo} }, opt2h2o(@opts);
    Getopt::Long::GetOptionsFromArray( \@ARGV, $o, @opts ); # Note, @ARGV is passed by reference 

    # ...
    # now $o can be used to query all possible options, even if they were
    # never passed at the commandline 

=item C<o2h REF>

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

=item C<h3o REF>

This method is basically a wrapper around C<h2o> that will traverse
an arbitrarily complex Perl data structure, applying C<h2o> to any
C<HASH> references along the way.

A common usecase where C<h3o> is useful is a web API call that returns
some list of C<HASH> references contained inside of an C<ARRAY> reference. 

For example,

  my $array_of_hashes = JSON::decode_json $json;
  h3o $array_of_hashes;
  my $co = $array_of_hashes->[3]->company->name;

Here, C<$array_of_hashes> is an C<ARRAY> reference that contains a set
of elements that are C<HASH> references; a pretty common situation when
dealing with records from an API or database call.  C<[3]>, refers the
4th element, which is a C<HASH> reference. This C<HASH> reference has
an accessor via C<h3o>, and this returns another C<HASH> that has an
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
    {
      "id": 3,
      "name": "Clementine Bauch",
      "username": "Samantha",
      "email": "Nathan@yesenia.net",
      "address": {
        "street": "Douglas Extension",
        "suite": "Suite 847",
        "city": "McKenziehaven",
        "zipcode": "59590-4157",
        "geo": {
          "lat": "-68.6102",
          "lng": "-47.0653"
        }
      },
      "phone": "1-463-123-4447",
      "website": "ramiro.info",
      "company": {
        "name": "Romaguera-Jacobson",
        "catchPhrase": "Face to face bifurcated interface",
        "bs": "e-enable strategic applications"
      }
    }
  ]

  (* froms, https://jsonplaceholder.typicode.com/users)



C<ARRAY> B<vmethods>

It is still somewhat inconvenient, though I<idiomatic>, to refer to C<ARRAY>
elements directly as in the example above. However, it is still inconsistent
with idea of C<Util::H2O>. So, C<h3o> leans into its I<heavy> nature by adding
some "virtual" methods to C<ARRAY> containers.

=over 8

=item C<all>

Returns a LIST of all items in the C<ARRAY> container.
 
  my @items = $root->some-barray->all;

=item C<get INDEX>

Given an C<ARRAY> container from C<h3o>, returns the element at the given
index. See C<push> example below for a practical example.

=item C<push LIST>

Pushes LIST onto ARRAY attached to the vmethod called; also applies the
C<h3o> method to anything I<pushed>.

  my @added = $root->some->barray->push({ foo => 1 }, {foo => 2});
  my $one   = $root->some->barray->get(0)->foo; # returns 1 via "get"
  my $two   = $root->some->barray->get(1)->foo; # returns 2 via "get"

=item C<pop>

Pop's an element from C<ARRAY> container available after applying C<h3o> to
a structure that has C<ARRAY> refs at any level.

  my $item = $root->some-barray->pop;

=item C<unshift LIST>

Similar to C<push>, just operates on the near end of the C<ARRAY>.

=item C<shift>

Similar to C<pop>, just operates on the near end of the C<ARRAY>.

=item C<scalar>

Returns the number of items in the C<ARRAY> container, which is more
convenient that doing,

  my $count = scalar @{$root->some->barray->all}; 

=back

=item C<o3h REF>

Does for data structures I<objectified> with C<h3o> what C<o2h> does
for objects created with C<h2o>.

=back

=head1 EXTERNAL METHODS

=over 4

=item C<h2o>

Because C<Util::H2O::More> exports C<h2o> as the basis for its
operations, C<h2o> is also available without needing to qualify
its full name space.

=back

=head1 DEPENDENCIES

Requires C<Util::H2O> because this module is effectively a wrapper
around C<h2o>.

It also uses the C<state> keyword, which is only available in perls
>= 5.10.

=head1 BUGS

No. I mean maybe. Buyer beware.

=head1 LICENSE AND COPYRIGHT 

Perl/perl

=head1 ACKNOWLEDGEMENTS

Thank you to HAUKEX for creating L<Util::H2O> and hearing me out
on its usefulness for some unintended use cases.

=head1 AUTHOR

Oodler 577 L<< <oodler@cpan.org> >> 
