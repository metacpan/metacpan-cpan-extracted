package autobox::Transform;

use strict;
use warnings;
use 5.010;
use parent qw/autobox/;

our $VERSION = "1.031";

=head1 NAME

autobox::Transform - Autobox methods to transform Arrays and Hashes

=head1 CONTEXT

L<autobox> provides the ability to call methods on native types,
e.g. strings, arrays, and hashes as if they were objects.

L<autobox::Core> provides the basic methods for Perl core functions
like C<uc>, C<map>, and C<grep>.

This module, C<autobox::Transform>, provides higher level and more
specific methods to transform and manipulate arrays and hashes, in
particular when the values are hashrefs or objects.



=head1 SYNOPSIS

    use autobox::Core;  # map, uniq, sort, join, sum, etc.
    use autobox::Transform;

=head2 Arrays

    # use autobox::Core for ->map etc.

    # filter (like a more versatile grep)
    $book_locations->filter(); # true values
    $books->filter(sub { $_->is_in_library($library) });
    $book_names->filter( qr/lord/i );
    $book_genres->filter("scifi");
    $book_genres->filter({ fantasy => 1, scifi => 1 }); # hash key exists

    # order (like a more succinct sort)
    $book_genres->order;
    $book_genres->order("desc");
    $book_prices->order([ "num", "desc" ]);
    $books->order([ sub { $_->{price} }, "desc", "num" ]);
    $log_lines->order([ num => qr/pid: "(\d+)"/ ]);
    $books->order(
        [ sub { $_->{price} }, "desc", "num" ] # first price
        sub { $_->{name} },                    # then name
    );

    # group (aggregate) array into hash
    $book_genres->group;       # "Sci-fi" => "Sci-fi"
    $book_genres->group_count; # "Sci-fi" => 3
    $book_genres->group_array; # "Sci-fi" => [ "Sci-fi", "Sci-fi", "Sci-fi"]

    # Flatten arrayrefs-of-arrayrefs
      $authors->map_by("books") # ->books returns an arrayref
      # [ [ $book1, $book2 ], [ $book3 ] ]
      $authors->map_by("books")->flat;
      # [ $book1, $book2, $book3 ]

    # Return reference, even in list context, e.g. in a parameter list
    $book_locations->filter()->to_ref;

    # Return array, even in scalar context
    @books->to_array;

    # Turn paired items into a hash
    @titles_books->to_hash;


=head2 Arrays with hashrefs/objects

    # $books and $authors below are arrayrefs with either objects or
    # hashrefs (the call syntax is the same). These have methods/hash
    # keys like C<$book->genre()>, C<$book->{is_sold_out}>,
    # C<$book->is_in_library($library)>, etc.

    $books->map_by("genre");
    $books->map_by([ price_with_tax => $tax_pct ]);

    $books->filter_by("is_sold_out");
    $books->filter_by([ is_in_library => $library ]);
    $books->filter_by([ price_with_tax => $rate ], sub { $_ > 56.00 });
    $books->filter_by("price", sub { $_ > 56.00 });
    $books->filter_by("author", "James A. Corey");
    $books->filter_by("author", qr/corey/i);

    # grep_by is an alias for filter_by
    $books->grep_by("is_sold_out");

    $books->uniq_by("id");

    $books->order_by("name");
    $books->order_by(name => "desc");
    $books->order_by(price => "num");
    $books->order_by(price => [ "num", "desc" ]);
    $books->order_by(name => [ sub { uc($_) }, "desc" ]);
    $books->order_by([ price_with_tax => $rate ] => "num");
    $books->order_by(
        author => "str",             # first by author
        price  => [ "num", "desc" ], # then by price, most expensive first
    );
    $books->order_by(
        author                      => [ "desc", sub { uc($_) } ],
        [ price_with_tax => $rate ] => [ "num", "desc" ],
        "name",
    );


    $books->group_by("title"),
    # {
    #     "Leviathan Wakes"       => $books->[0],
    #     "Caliban's War"         => $books->[1],
    #     "The Tree-Body Problem" => $books->[2],
    #     "The Name of the Wind"  => $books->[3],
    # },

    $authors->group_by([ publisher_affiliation => "with" ]),
    # {
    #     'James A. Corey with Orbit'     => $authors->[0],
    #     'Cixin Liu with Head of Zeus'   => $authors->[1],
    #     'Patrick Rothfuss with Gollanz' => $authors->[2],
    # },

    $books->group_by_count("genre"),
    # {
    #     "Sci-fi"  => 3,
    #     "Fantasy" => 1,
    # },

    my $genre_books = $books->group_by_array("genre");
    # {
    #     "Sci-fi"  => [ $sf_book_1, $sf_book_2, $sf_book_3 ],
    #     "Fantasy" => [ $fantasy_book_1 ],
    # },


=head2 Hashes

    # map over each pair
    # e.g. Upper-case the genre name, and make the count say "n books"
    #     (return a key => value pair)
    $genre_count->map_each(sub { uc( $_[0] ) => "$_ books" });
    # {
    #     "FANTASY" => "1 books",
    #     "SCI-FI"  => "3 books",
    # },

    # map over each value
    # e.g. Make the count say "n books"
    #     (return the new value)
    $genre_count->map_each_value(sub { "$_ books" });
    # {
    #     "Fantasy" => "1 books",
    #     "Sci-fi"  => "3 books",
    # },

    # map each pair into an array
    # e.g. Transform each pair to the string "n: genre"
    #     (return list of items)
    $genre_count->map_each_to_array(sub { "$_: $_[0]" });
    # [ "1: Fantasy", "3: Sci-fi" ]

    # filter each pair
    # Genres with more than five books
    $genre_count->filter_each(sub { $_ > 5 });

    # Return reference, even in list context, e.g. in a parameter list
    %genre_count->to_ref;

    # Return hash, even in scalar context
    $author->book_count->to_hash;

    # Turn key-value pairs into an array
    %isbn__book->to_array;


=head2 Combined examples

    my $order_authors = $order->books
        ->filter_by("title", qr/^The/)
        ->uniq_by("isbn")
        ->map_by("author")
        ->uniq_by("name")
        ->order_by(publisher => "str", name => "str")
        ->map_by("name")->uniq->join(", ");

    my $total_order_amount = $order->books
        ->filter_by([ covered_by_vouchers => $vouchers ], sub { ! $_ })
        ->map_by([ price_with_tax => $tax_pct ])
        ->sum;

=cut



use true;
use Carp;

sub import {
    my $self = shift;
    $self->SUPER::import( ARRAY => "autobox::Transform::Array" );
    $self->SUPER::import( HASH  => "autobox::Transform::Hash"  );
}

sub throw {
    my ($error) = @_;
    ###JPL: remove lib
    $error =~ s/ at [\\\/\w ]*?\bautobox.Transform\.pm line \d+\.\n?$//;
    local $Carp::CarpLevel = 1;
    croak($error);
}

# Normalize the two method calling styles for accessor + args:
#   $acessor, $args_arrayref
# or
#   $acessor_and_args_arrayref
sub _normalized_accessor_args_subref {
    my ($accessor, $args, $subref) = @_;

    # Note: unfortunately, this won't allow the $subref (modifier) to
    # become an arrayref later on when we do many types of modifiers
    # (string eq, qr regex match, sub call, arrayref in) for
    # filtering.
    #
    # That has to happen after the deprecation has expired and the old
    # syntax is removed.
    if(ref($args) eq "CODE") {
        $subref = $args; # Move down one step
        $args = undef;
    }
    if(ref($accessor) eq "ARRAY") {
        ($accessor, my @args) = @$accessor;
        $args = \@args;
    }

    return ($accessor, $args, $subref);
}

###JPL: rename subref to predicate
# Normalize the two method calling styles for accessor + args:
#   $acessor, $args_arrayref, $modifier
# or
#   $acessor_and_args_arrayref, $modifier
sub _normalized_accessor_args_predicate {
    my ($accessor, $args, $subref) = @_;

    # Note: unfortunately, this won't allow the $subref (modifier) to
    # be an arrayref, or undef for many types of modifiers (string eq,
    # qr regex match, sub call, arrayref in) for filtering.
    #
    # That has to happen after the deprecation has expired and the old
    # syntax is removed.
    if(defined($args) && ref($args) ne "ARRAY") {
        $subref = $args; # Move down one step
        $args = undef;
    }
    if(ref($accessor) eq "ARRAY") {
        ($accessor, my @args) = @$accessor;
        $args = \@args;
    }

    return ($accessor, $args, $subref);
}



sub _predicate {
    my ($name, $predicate, $default_predicate) = @_;

    # No predicate, use default is_true
    defined($predicate) or return $default_predicate;

    # scalar, do string eq
    my $type = ref($predicate) or return sub { $predicate eq $_ };

    $type eq "CODE"   and return $predicate;
    $type eq "Regexp" and return sub { $_ =~ $predicate };
    $type eq "HASH"   and return sub { exists $predicate->{ $_ } };

    # Invalid predicate
    Carp::croak("->$name() \$predicate: ($predicate) is not one of: subref, string, regex");
}



=head1 DESCRIPTION

High level autobox methods you can call on arrays, arrayrefs, hashes
and hashrefs.


=head2 Transforming lists of objects vs list of hashrefs

C<map_by>, C<filter_by> C<order_by> etc. (all methods named C<*_by>)
work with sets of hashrefs or objects.

These methods are called the same way regardless of whether the array
contains objects or hashrefs. The items in the list must be either all
objects or all hashrefs.

If the array contains hashrefs, the hash key is looked up on each
item.

If the array contains objects, a method is called on each object
(possibly with the arguments provided).

=head3 Calling accessor methods with arguments

For method calls, it's possible to provide arguments to the method.

Consider C<map_by>:

    $array->map_by($accessor)

If the $accessor is a string, it's a simple method call.

    # method call without args
    $books->map_by("price")
    # becomes $_->price() or $_->{price}

If the $accessor is an arrayref, the first item is the method name,
and the rest of the items are the arguments to the method.

    # method call with args
    $books->map_by([ price_with_discount => 5.0 ])
    # becomes $_->price_with_discount(5.0)

=head3 Deprecated syntax

There is an older syntax for calling methods with arguments. It was
abandoned to open up more powerful ways to use grep/filter type
methods. Here it is for reference, in case you run into existing code.

    $array->filter_by($accessor, $args, $subref)
    $books->filter_by("price_with_discount", [ 5.0 ], sub { $_ < 15.0 })

Call the method $accessor on each object using the arguments in the
$args arrayref like so:

    $object->$accessor(@$args)

I<This style is deprecated>, and planned for removal in version 2.000,
so if you have code with the old call style, please:

=over 4

=item

Replace your existing code with the new style as soon as possible. The
change is trivial and the code easily found by grep/ack.

=item

If need be, pin your version to < 2.000 in your cpanfile, dist.ini or
whatever you use to avoid upgrading modules to incompatible versions.

=back


=head2 Filter predicates

There are several methods that filter items,
e.g. C<@array-E<gt>filter> (duh), C<@array-E<gt>filter_by>, and
C<%hash-E<gt>filter_each>. These methods take a $predicate argument to
determine which items to retain or filter out.

If $predicate is an I<unblessed scalar>, it is compared to each value
with C<string eq>.

    $books->filter_by("author", "James A. Corey");

If $predicate is a I<regex>, it is compared to each value with C<=~>.

    $books->filter_by("author", qr/Corey/);

If $predicate is a I<hashref>, values in @array are retained if the
$predicate hash key C<exists> (the hash values are irrelevant).

    $books->filter_by(
        "author", {
            "James A. Corey"   => undef,
            "Cixin Liu"        => 0,
            "Patrick Rothfuss" => 1,
        },
    );

If $predicate is a I<subref>, the subref is called for each value to
check whether this item should remain in the list.

The $predicate subref should return a true value to remain. $_ is set
to the current $value.

    $authors->filter_by(publisher => sub { $_->name =~ /Orbit/ });


=head2 Sorting using order and order_by

Let's first compare how sorting is done with Perl's C<sort> and
autobox::Transform's C<order>/C<order_by>.


=head3 Sorting with sort

=over 4

=item *

provide a sub that returns the comparison outcome of two values: $a and $b

=item *

in case of a tie, provide another comparison of $a and $b

=back

    # If the name is the same, compare age (oldest first)
    sort {
        uc( $a->{name} ) cmp uc( $b->{name} )           # first comparison
        ||
        int( $b->{age} / 10 ) <=> int( $a->{age} / 10 ) # second comparison
    } @users

(note the opposite order of $a and $b for the age comparison,
something that's often difficult to discern at a glance)

=head3 Sorting with order, order_by

=over 4

=item *

Provide order options for how one value should be compared with the others:

=over 8

=item *

how to compare (C<cmp> or C<<=E<gt>>)

=item *

which direction to sort (C<asc>ending or C<desc>ending)

=item *

which value to compare, using a regex or subref, e.g. by uc($_)

=back

=item *

In case of a tie, provide another comparison

=back

    # If the name is the same, compare age (oldest first)

    # ->order
    @users->order(
        sub { uc( $_->{name} ) },                         # first comparison
        [ "num", sub { int( $_->{age} / 10 ) }, "desc" ], # second comparison
    )

    # ->order_by
    @users->order_by(
        name => sub { uc },                                # first comparison
        age  => [ num => desc => sub { int( $_ / 10 ) } ], # second comparison
    )

=head3 Comparison Options

If there's only one option for a comparison (e.g. C<num>), provide a
single option (string/regex/subref) value. If there are many options,
provide them in an arrayref in any order.

=head3 Comparison operator

=over 4

=item *

C<"str"> (cmp) - default

=item *

C<"num"> (<=>)

=back


=head3 Sort order

=over 4

=item *

C<"asc"> (ascending) - default

=item *

C<"desc"> (descending)

=back


=head3 The value to compare

=over 4

=item *

A subref - default is: C<sub { $_ }>

=over 8

=item *

The return value is used in the comparison

=back

=item *

A regex, e.g. C<qr/id: (\d+)/>

=over 8

=item *

The value of join("", @captured_groups) are used in the comparison (@captured_groups are $1, $2, $3 etc.)

=back

=back

=head3 Examples of a single comparison

    # order: the first arg is the comparison options (one or an
    # arrayref with many options)
    ->order()  # Defaults to str, asc, $_, just like sort
    ->order("num")
    ->order(sub { uc($_) })
    # compare captured matches, e.g. "John" and "Doe" as "JohnDoe"
    ->order( qr/first_name: (\w+), last_name: (\w+)/ )
    ->order([ num => qr/id: (\d+)/ ])
    ->order([ sub { int($_) }, "num" ])

    # order_by: the first arg is the accessor, just like with
    # map_by. Second arg is the comparison options (one or an arrayref
    # with many options)
    ->order_by("id")
    ->order_by("id", "num")
    ->order_by("id", [ "num", "desc" ])
    ->order_by("name", sub { uc($_) })
    ->order_by(log_line => qr/first_name: (\w+), last_name: (\w+)/ )
    ->order_by("log_line", [ num => qr/id: (\d+)/ ])
    ->order_by(age => [ sub { int($_) }, "num" ])

    # compare int( $a->age_by_interval(10) )
    ->order_by([ age_by_interval => 10 ] => [ sub { int($_) }, "num" ])
    # compare uc( $a->name_with_title($title) )
    ->order_by([ name_with_title => $title ], sub { uc($_) })


=head3 Examples of fallback comparisons

When the first comparison is a tie, the subsequent ones are used.

    # order: list of comparison options (one or an arrayref with many
    # options, per comparison)
    ->order(
        [ sub { $_->{price} }, "num" ], # First a numeric comparison of price
        [ sub { $_->{name} }, "desc" ], # or if same, a reverse comparison of the name
    )
    ->order(
        [ sub { uc($_) }, "desc" ],
        "str",
    )
    ->order(
        qr/type: (\w+)/,
        [ num => desc => qr/duration: (\d+)/ ]
        [ num => sub { /id: (\d+)/ } ],
        "str",
    )

    # order_by: pairs of accessor-comparison options
    ->order_by(
        price => "num", # First a numeric comparison of price
        name => "desc", # or if same, a reverse comparison of the name
    )
    ->order_by(
        price => [ "num", "desc" ],
        name  => "str",
    )
    # accessor is a method call with arg: $_->price_with_discount($discount)
    ->order_by(
        [ price_with_discount => $discount ] => [ "num", "desc" ],
        name                                 => [ str => sub { uc($_) } ],
        "id",
    )



=head2 List and Scalar Context

Almost all of the methods are context sensitive, i.e. they return a
list in list context and an arrayref in scalar context, just like
L<autobox::Core>.

B<Beware>: I<you might be in list context when you need an arrayref.>

When in doubt, assume they work like C<map> and C<grep> (i.e. return a
list), and convert the return value to references where you might have
an unobvious list context. E.g.

=head3 Incorrect

    $self->my_method(
        # Wrong, this is list context and wouldn't return an array ref
        books => $books->filter_by("is_published"),
    );

=head3 Correct

    $self->my_method(
        # Correct, put the returned list in an anonymous array ref
        books => [ $books->filter_by("is_published") ],
    );
    $self->my_method(
        # Correct, ensure scalar context to get an array ref
        books => scalar $books->filter_by("is_published"),
    );

    # Probably the nicest, since ->to_ref goes at the end
    $self->my_method(
        # Correct, use ->to_ref to ensure an array ref is returned
        books => $books->filter_by("is_published")->to_ref,
    );



=head1 METHODS ON ARRAYS

=cut

package # hide from PAUSE
    autobox::Transform::Array;

use autobox::Core;
use Sort::Maker ();
use List::MoreUtils ();



=head2 @array->filter($predicate = *is_true_subref*) : @array | @$array

Similar to Perl's C<grep>, return an @array with values for which
$predicate yields a true value.

$predicate can be a subref, string, undef, regex, or hashref. See
L</Filter predicates>.

The default (no $predicate) is a subref which retains true values in
the @array.

Examples:

    my @apples     = $fruit->filter("apple");
    my @any_apple  = $fruit->filter( qr/apple/i );
    my @publishers = $authors->filter(
        sub { $_->publisher->name =~ /Orbit/ },
    );


=head3 filter and grep

L<autobox::Core>'s C<grep> method takes a subref, just like this
method. C<filter> also supports the other predicate types, like
string, regex, etc.


=cut

sub filter {
    my $array = shift;
    my ($predicate) = @_;
    my $subref = autobox::Transform::_predicate(
        "filter",
        $predicate,
        sub { !! $_ },
    );

    my $result = eval {
        [ CORE::grep { $subref->( $_ ) } @$array ]
    } or autobox::Transform::throw($@);

    return wantarray ? @$result : $result;
}



my $option__group = {
    str  => "operator",
    num  => "operator",
    asc  => "direction",
    desc => "direction",
};
sub _group__value_from_order_options {
    my ($method_name, $options) = @_;
    my $group__value = {};
    for my $option (grep { $_ } @$options) {
        my $group;

        my $ref_option = ref($option);
        ( $ref_option eq "CODE" ) and $group = "extract";
        if ( $ref_option eq "Regexp" ) {
            my $regex = $option;
            $option = sub { join("", m/$regex/) };
            $group = "extract";
        }

        $group ||= $option__group->{ $option }
            or Carp::croak("->$method_name(): Invalid comparison option ($option), did you mean ->order_by('$option')?");

        exists $group__value->{ $group }
            and Carp::croak("->$method_name(): Conflicting comparison options: ($group__value->{ $group }) and ($option)");

        $group__value->{ $group } = $option;
    }

    return $group__value;
}

my $transform__sorter = {
    str  => "string",
    num  => "number",
    asc  => "ascending",
    desc => "descending",
};
sub _sorter_from_comparisons {
    my ($method_name, $comparisons) = @_;

    my @sorter_keys;
    my @extracts;
    for my $options (@$comparisons) {
        ref($options) eq "ARRAY" or $options = [ $options ];

        # Check one comparison
        my $group__value = _group__value_from_order_options(
            $method_name,
            $options,
        );

        my $operator  = $group__value->{operator}  // "str";
        my $direction = $group__value->{direction} // "asc";
        my $extract   = $group__value->{extract}   // sub { $_ };

        my $sorter_operator = $transform__sorter->{$operator};
        my $sorter_direction = $transform__sorter->{$direction};

        push(@extracts, $extract);
        my $extract_index = @extracts;
        push(
            @sorter_keys,
            $sorter_operator => [
                $sorter_direction,
                # Sort this one by the extracted value
                code => "\$_->[ $extract_index ]",
            ],
        );
    }

    my $sorter = Sort::Maker::make_sorter(
        "plain", "ref_in", "ref_out",
        @sorter_keys,
    ) or Carp::croak(__PACKAGE__ . " internal error: $@");

    return ($sorter, \@extracts);
}

sub _item_values_array_from_array_item_extracts {
    my ($array, $extracts) = @_;

    # Custom Schwartzian Transform where each array item is arrayref of:
    # 0: $array item; rest 1..n : comparison values
    # The sorter keys are simply indexed into the nth value
    return [
        map { ## no critic
            my $item = $_;
            [
                $item,                         # array item to compare
                map {
                    my $extract = $_; local $_ = $item;
                    $extract->();
                } @$extracts, # comparison values for array item
            ];
        }
        @$array
    ];
}

sub _item_values_array_from_map_by_extracts {
    my ($array, $accessors, $extracts) = @_;

    # Custom Schwartzian Transform where each array item is arrayref of:
    # 0: $array item; rest 1..n : comparison values
    # The sorter keys are simply indexed into the nth value
    my $accessor_values = $accessors->map(
        sub { [ map_by($array, $_) ] }
    );
    return [
        map { ## no critic
            my $item = $_;
            my $accessor_index = 0;
            [
                $item, # array item to compare
                map {
                    my $extract = $_;
                    my $value = shift @{$accessor_values->[ $accessor_index++ ]};

                    local $_ = $value;
                    $extract->();
                } @$extracts, # comparison values for array item
            ];
        }
        @$array
    ];
}

=head2 @array->order(@comparisons = ("str")) : @array | @$array

Return @array ordered according to the @comparisons. The default
comparison is the same as the default sort, e.g. a normal string
comparison of the @array values.

If the first item in @comparison ends in a tie, the next one is used,
etc.

Each I<comparison> consists of a single I<option> or an I<arrayref of
options>, e.g. C<str>/C<num>, C<asc>/C<desc>, or a subref/regex. See
L</Sorting using order and order_by> for details about how these work.

Examples:

    @book_genres->order;
    @book_genres->order("desc");
    @book_prices->order([ "num", "desc" ]);
    @books->order([ sub { $_->{price} }, "desc", "num" ]);
    @log_lines->order([ num => qr/pid: "(\d+)"/ ]);
    @books->order(
        [ sub { $_->{price} }, "desc", "num" ] # first price
        sub { $_->{name} },                    # then name
    );

=cut

sub order {
    my $array = shift;
    my (@comparisons) = @_;
    @comparisons or @comparisons = ("str");

    my ($sorter, $extracts) = _sorter_from_comparisons("order", \@comparisons);

    my $item_values_array = _item_values_array_from_array_item_extracts(
        $array,
        $extracts,
    );
    my $sorted_array = $sorter->($item_values_array);
    my $result = [ map { $_->[0] } @$sorted_array ];

    return wantarray ? @$result : $result;
}



=head2 @array->group($value_subref = item) : %key_value | %$key_value

Group the @array items into a hashref with the items as keys.

The default $value_subref puts each item in the list as the hash
value. If the key is repeated, the value is overwritten with the last
object.

Example:

    my $title_book = $book_titles->group;
    # {
    #     "Leviathan Wakes"       => "Leviathan Wakes",
    #     "Caliban's War"         => "Caliban's War",
    #     "The Tree-Body Problem" => "The Tree-Body Problem",
    #     "The Name of the Wind"  => "The Name of the Wind",
    # },

=head3 The $value_subref

For simple cases of just grouping a single key to a single value, the
$value_subref is straightforward to use.

The hash key is the array item. The hash value is whatever is returned
from

    my $new_value = $value_sub->($current_value, $object, $key);

=over 4

=item

C<$current> value is the current hash value for this key (or undef if
the first one).

=item

C<$object> is the current item in the list. The current $_ is also set
to this.

=item

C<$key> is the array item.

=back

See also: C<-E<gt>group_by>.

=cut

sub __core_group {
    my( $name, $array, $value_sub ) = @_;
    @$array or return wantarray ? () : { };

    my %key_value;
    for my $item (@$array) {
        my $key = $item;

        my $current_value = $key_value{ $key };
        local $_ = $item;
        my $new_value = $value_sub->($current_value, $item, $key);

        $key_value{ $key } = $new_value;
    }

    return wantarray ? %key_value : \%key_value;
}

sub group {
    my $array = shift;
    my ($value_sub) = _normalized_accessor_args_subref(@_);

    $value_sub //= sub { $_ };
    ref($value_sub) eq "CODE"
        or Carp::croak("group(\$value_sub): \$value_sub ($value_sub) is not a sub ref");

    return __core_group("group", $array, $value_sub);
}



=head2 @array->group_count : %key_count | %$key_count

Just like C<group>, but the hash values are the the number of
instances each item occurs in the list.

Example:

    $book_genres->group_count;
    # {
    #     "Sci-fi"  => 3,
    #     "Fantasy" => 1,
    # },

There are three books counted for the "Sci-fi" key.

=cut

sub group_count {
    my $array = shift;

    my $value_sub = sub {
        my $count = shift // 0;
        return ++$count;
    };

    return __core_group("group_count", $array, $value_sub);
}




=head2 @array->group_array : %key_objects | %$key_objects

Just like C<group>, but the hash values are arrayrefs containing those
same array items.

Example:

    $book_genres->group_array;
    # {
    #     "Sci-fi"  => [ "Sci-fi", "Sci-fi", "Sci-fi" ],
    #     "Fantasy" => [ "Fantasy" ],
    # },

The three Sci-fi genres are collected under the Sci-fi key.

=cut

sub group_array {
    my $array = shift;

    my $value_sub = sub {
        my $value_array = shift // [];
        push( @$value_array, $_ );
        return $value_array;
    };

    return __core_group("group_array", $array, $value_sub);
}



=head2 @array->flat() : @array | @$array

Return a (one level) flattened array, assuming the array items
themselves are array refs. I.e.

    [
        [ 1, 2, 3 ],
        [ "a", "b" ],
        [ [ 1, 2 ], { 3 => 4 } ]
    ]->flat

returns

    [ 1, 2, 3, "a", "b ", [ 1, 2 ], { 3 => 4 } ]

This is useful if e.g. a C<-E<gt>map_by("some_method")> returns
arrayrefs of objects which you want to do further method calls
on. Example:

    # ->books returns an arrayref of Book objects with a ->title
    $authors->map_by("books")->flat->map_by("title")

Note: This is different from autobox::Core's ->flatten, which reurns a
list rather than an array and therefore can't be used in this
way.

=cut

sub flat {
    my $array = shift;
    ###JPL: eval and report error from correct place
    my $result = [ map { @$_ } @$array ];
    return wantarray ? @$result : $result;
}

=head2 @array->to_ref() : $arrayref

Return the reference to the @array, regardless of context.

Useful for ensuring the last array method return a reference while in
scalar context. Typically:

    do_stuff(
        books => $author->map_by("books")->to_ref,
    );

map_by is called in list context, so without ->to_ref it would have
return an array, not an arrayref.

=cut

sub to_ref {
    my $array = shift;
    return $array;
}

=head2 @array->to_array() : @array

Return the @array, regardless of context. This is mostly useful if
called on a ArrayRef at the end of a chain of method calls.

=cut

sub to_array {
    my $array = shift;
    return @$array;
}

=head2 @array->to_hash() : %hash | %$hash

Return the item pairs in the @array as the key-value pairs of a %hash
(context sensitive).

Useful if you need to continue calling %hash methods on it.

Die if there aren't an even number of items in @array.

=cut

sub to_hash {
    my $array = shift;
    my $count = @$array;

    $count % 2 and Carp::croak(
        "\@array->to_hash on an array with an odd number of elements ($count)",
    );

    my %new_hash = @$array;
    return wantarray ? %new_hash : \%new_hash;
}



=head1 METHODS ON ARRAYS CONTAINING OBJECTS/HASHES

=cut

*_normalized_accessor_args_predicate
    = \&autobox::Transform::_normalized_accessor_args_predicate;
*_normalized_accessor_args_subref
    = \&autobox::Transform::_normalized_accessor_args_subref;

sub __invoke_by {
    my $invoke = shift;
    my $array = shift;
    my( $accessor, $args, $subref_name, $subref ) = @_;
    defined($accessor) or Carp::croak("->${invoke}_by() missing argument: \$accessor");
    @$array or return wantarray ? () : [ ];

    $args //= [];
    if ( ref($array->[0] ) eq "HASH" ) {
        ( defined($args) && (@$args) ) # defined and isn't empty
            and Carp::croak("${invoke}_by([ '$accessor', \@args ]): \@args ($args) only supported for method calls, not hash key access");
        $invoke .= "_key";
    }

    ###JPL: move up
    ref($args) eq "ARRAY"
        or Carp::croak("${invoke}_by([ '$accessor', \@args ]): \@args ($args) is not a list");

    if( $subref_name ) {
        ref($subref) eq "CODE"
            or Carp::croak("${invoke}_by([ '$accessor', \@args ], \$$subref_name): \$$subref_name ($subref) is not an sub ref");
    }

    my %seen;
    my $invoke_sub = {
        map        => sub { [ CORE::map  { $_->$accessor( @$args ) } @$array ] },
        map_key    => sub { [ CORE::map  { $_->{$accessor}         } @$array ] },
        filter     => sub { [ CORE::grep { $subref->( local $_ = $_->$accessor( @$args ) ) } @$array ] },
        filter_key => sub { [ CORE::grep { $subref->( local $_ = $_->{$accessor}         ) } @$array ] },
        uniq       => sub { [ CORE::grep { ! $seen{ $_->$accessor( @$args ) // "" }++ } @$array ] },
        uniq_key   => sub { [ CORE::grep { ! $seen{ $_->{$accessor}         // "" }++ } @$array ] },
    }->{$invoke};

    my $result = eval { $invoke_sub->() }
        or autobox::Transform::throw($@);

    return wantarray ? @$result : $result;
}

=head2 @array->map_by($accessor) : @array | @$array

$accessor is either a string, or an arrayref where the first item is a
string.

Call the $accessor on each object in @array, or get the hash key value
on each hashref in @array. Like:

    map { $_->$accessor() } @array
    # or
    map { $_->{$accessor} } @array

Examples:

    my @author_names = $authors->map_by("name");
    my $author_names = @publishers->map_by("authors")->flat->map_by("name");

Or get the hash key value. Example:

    my @review_scores = $reviews->map_by("score");

Alternatively for when @array contains objects, the $accessor can be
an arrayref. The first item is the method name, and the rest of the
items are passed as args in the method call. This obviously won't work
when the @array contains hashrefs.

Examples:

    my @prices_including_tax = $books->map_by([ "price_with_tax", $tax_pct ]);
    my $prices_including_tax = $books->map_by([ price_with_tax => $tax_pct ]);

=cut

sub map_by {
    my $array = shift;
    my ($accessor, $args) = _normalized_accessor_args_subref(@_);
    return __invoke_by("map", $array, $accessor, $args);
}



=head2 @array->filter_by($accessor, $predicate = *is_true_subref*) : @array | @$array

$accessor is either a string, or an arrayref where the first item is a
string.

Call the $accessor on each object in the list, or get the hash key
value on each hashref in the list.

Example:

    my @prolific_authors = $authors->filter_by("is_prolific");

Alternatively the $accessor is an arrayref. The first item is the
accessor name, and the rest of the items are passed as args the method
call. This only works when working with objects, not with hashrefs.

Example:

    my @books_to_charge_for = $books->filter_by([ price_with_tax => $tax_pct ]);

Use the $predicate to determine whether the value should remain.
$predicate can be a subref, string, undef, regex, or hashref. See
L</Filter predicates>.

The default (no $predicate) is a subref which retains true values in
the result @array.

Examples:

    # Custom predicate subref
    my @authors = $authors->filter_by(
        "publisher",
        sub { $_->name =~ /Orbit/ },
    );

    # Call method with args and match a regex
    my @authors = $authors->filter_by(
        [ publisher_affiliation => "with" ],
        qr/Orbit/ },
    );

Note: if you do something complicated with a $predicate subref, it
might be easier and more readable to simply use
C<$array-$<gt>filter()>.


=head3 Alias

C<grep_by> is an alias for C<filter_by>. Unlike C<grep> vs C<filter>,
this one works exaclty the same way.

=cut

sub filter_by {
    my $array = shift;
    my ($accessor, $args, $predicate) = _normalized_accessor_args_predicate(@_);
    my $subref = autobox::Transform::_predicate(
        "filter_by",
        $predicate,
        sub { !! $_ },
    );
    # filter_by $value, if passed the method value must match the value?
    return __invoke_by(
        "filter",
        $array,
        $accessor,
        $args,
        filter_subref => $subref,
    );
}

*grep_by = \&filter_by;



=head2 @array->uniq_by($accessor) : @array | @$array

$accessor is either a string, or an arrayref where the first item is a
string.

Call the $accessor on each object in the list, or get the hash key
value on each hashref in the list. Return list of items wich have a
unique set of return values. The order is preserved. On duplicates,
keep the first occurrence.

Examples:

    # You have gathered multiple Author objects with duplicate ids
    my @authors = $authors->uniq_by("author_id");

Alternatively the $accessor is an arrayref. The first item is the
accessor name, and the rest of the items are passed as args the method
call. This only works when working with objects, not with hashrefs.

Examples:

    my @example_book_at_price_point = $books->uniq_by(
        [ price_with_tax => $tax_pct ],
    );

=cut

sub uniq_by {
    my $array = shift;
    my ($accessor, $args) = _normalized_accessor_args_subref(@_);
    return __invoke_by("uniq", $array, $accessor, $args);
}

=head2 @array->order_by(@accessor_comparison_pairs) : @array | @$array

Return @array ordered according to the @accessor_comparison_pairs.

The comparison value comes from an initial
C<@array->map_by($accessor)> for each accessor-comparison pair. It is
important that the $accessor call returns exactly a single scalar that
can be compared with the other values.

It then works just like with C<-E<gt>order>.

    $books->order_by("name"); # default order, i.e. "str"
    $books->order_by(price => "num");
    $books->order_by(price => [ "num", "desc" ]);

As with C<map_by>, if the $accessor is used on an object, the method
call can include arguments.

    $books->order_by([ price_wih_tax => $tax_rate ] => "num");

Just like with C<order>, the value returned by the accessor can be
transformed using a sub, or be matched against a regex.

    $books->order_by(price => [ num => sub { int($_) } ]);

    # Ignore leading "The" in book titles by optionally matching it
    # with a non-capturing group and the rest with a capturing group
    # paren
    $books->order_by( title => qr/^ (?: The \s+ )? (.+) /x );

If a comparison is missing for the last pair, the default is a normal
C<str> comparison.

    $books->order_by("name"); # default "str"

If the first comparison ends in a tie, the next pair is used,
etc. Note that in order to provide accessor-comparison pairs, it's
often necessary to provide a default "str" comparison just to make it
a pair.

    $books->order_by(
        author => "str",
        price  => [ "num", "desc" ],
    );

=cut

sub order_by {
    my $array = shift;
    my (@accessors_and_comparisons) = @_;

    my $i = 0;
    my ($accessors, $comparisons) = List::MoreUtils::part
        { $i++ %2 }
        @accessors_and_comparisons;
    $accessors   ||= [];
    $comparisons ||= [];
    @$accessors or Carp::croak("->order_by() missing argument: \$accessor");
    # Default comparison
    @$accessors == @$comparisons or push(@$comparisons, "str");

    my ($sorter, $extracts) = _sorter_from_comparisons("order_by", $comparisons);

    my $item_values_array = _item_values_array_from_map_by_extracts(
        $array,
        $accessors,
        $extracts,
    );
    my $sorted_array = $sorter->($item_values_array);
    my $result = [ map { $_->[0] } @$sorted_array ];

    return wantarray ? @$result : $result;
}

=head2 @array->group_by($accessor, $value_subref = object) : %key_value | %$key_value

$accessor is either a string, or an arrayref where the first item is a
string.

Call C<-E<gt>$accessor> on each object in the array, or get the hash
key for each hashref in the array (just like C<-E<gt>map_by>) and
group the values as keys in a hashref.

The default $value_subref puts each object in the list as the hash
value. If the key is repeated, the value is overwritten with the last
object.

Example:

    my $title_book = $books->group_by("title");
    # {
    #     "Leviathan Wakes"       => $books->[0],
    #     "Caliban's War"         => $books->[1],
    #     "The Tree-Body Problem" => $books->[2],
    #     "The Name of the Wind"  => $books->[3],
    # },

=head3 The $value_subref

For simple cases of just grouping a single key to a single value, the
$value_subref is straightforward to use.

The hash key is whatever is returned from C<$object-E<gt>$accessor>.

The hash value is whatever is returned from

    my $new_value = $value_sub->($current_value, $object, $key);

=over 4

=item

C<$current> value is the current hash value for this key (or undef if the first one).

=item

C<$object> is the current item in the list. The current $_ is also set to this.

=item

C<$key> is the key returned by $object->$accessor(@$args)

=back

A simple example would be to group by the accessor, but instead of the
object used as the value you want to look up an attribute on each
object:

    my $book_id__author = $books->group_by("id", sub { $_->author });
    # keys: book id; values: author

If you want to create an aggregate value the $value_subref can be a
bit tricky to use, so the most common thing would probably be to use
one of the more specific group_by-methods (see below). It should be
capable enough to achieve what you need though.

=cut

sub __core_group_by {
    my( $name, $array, $accessor, $args, $value_sub ) = @_;
    $accessor or Carp::croak("->$name() missing argument: \$accessor");
    @$array or return wantarray ? () : { };

    my $invoke = do {
        # Hash key
        if ( ref($array->[0] ) eq "HASH" ) {
            defined($args)
                and Carp::croak("$name([ '$accessor', \@args ]): \@args ($args) only supported for method calls, not hash key access.");
            "key";
        }
        # Method
        else {
            $args //= [];
            ref($args) eq "ARRAY"
                or Carp::croak("$name([ '$accessor', \@args ], \$value_sub): \@args ($args) is not a list");
            "method";
        }
    };

    my $invoke_sub = {
        method => sub { [ shift->$accessor(@$args) ] },
        key    => sub { [ shift->{$accessor}       ] },
    }->{$invoke};

    my %key_value;
    for my $object (@$array) {
        my $key_ref = eval { $invoke_sub->($object) }
            or autobox::Transform::throw($@);
        my $key = $key_ref->[0];

        my $current_value = $key_value{ $key };
        local $_ = $object;
        my $new_value = $value_sub->($current_value, $object, $key);

        $key_value{ $key } = $new_value;
    }

    return wantarray ? %key_value : \%key_value;
}

sub group_by {
    my $array = shift;
    my ($accessor, $args, $value_sub) = _normalized_accessor_args_subref(@_);

    $value_sub //= sub { $_ };
    ref($value_sub) eq "CODE"
        or Carp::croak("group_by([ '$accessor', \@args ], \$value_sub): \$value_sub ($value_sub) is not a sub ref");

    return __core_group_by("group_by", $array, $accessor, $args, $value_sub);
}

=head2 @array->group_by_count($accessor) : %key_count | %$key_count

$accessor is either a string, or an arrayref where the first item is a
string.

Just like C<group_by>, but the hash values are the the number of
instances each $accessor value occurs in the list.

Example:

    $books->group_by_count("genre"),
    # {
    #     "Sci-fi"  => 3,
    #     "Fantasy" => 1,
    # },

C<$book-E<gt>genre()> returns the genre string. There are three books
counted for the "Sci-fi" key.

=cut

sub group_by_count {
    my $array = shift;
    my ($accessor, $args) = _normalized_accessor_args_subref(@_);

    my $value_sub = sub {
        my $count = shift // 0; return ++$count;
    };

    return __core_group_by("group_by_count", $array, $accessor, $args, $value_sub);
}

=head2 @array->group_by_array($accessor) : %key_objects | %$key_objects

$accessor is either a string, or an arrayref where the first item is a
string.

Just like C<group_by>, but the hash values are arrayrefs containing
the objects which has each $accessor value.

Example:

    my $genre_books = $books->group_by_array("genre");
    # {
    #     "Sci-fi"  => [ $sf_book_1, $sf_book_2, $sf_book_3 ],
    #     "Fantasy" => [ $fantasy_book_1 ],
    # },

$book->genre() returns the genre string. The three Sci-fi book objects
are collected under the Sci-fi key.

=cut

sub group_by_array {
    my $array = shift;
    my ($accessor, $args) = _normalized_accessor_args_subref(@_);

    my $value_sub = sub {
        my $array = shift // [];
        push( @$array, $_ );
        return $array;
    };

    return __core_group_by("group_by_array", $array, $accessor, $args, $value_sub);
}



=head1 METHODS ON HASHES

=cut

package # hide from PAUSE
    autobox::Transform::Hash;

use autobox::Core;



sub key_value {
    my $hash = shift;
    my( $original_key, $new_key ) = @_;
    $new_key //= $original_key;
    my %key_value = ( $new_key => $hash->{$original_key} );
    return wantarray ? %key_value : \%key_value;
}

sub __core_key_value_if {
    my $hash = shift;
    my( $comparison_sub, $original_key, $new_key ) = @_;
    $comparison_sub->($hash, $original_key) or return wantarray ? () : {};
    return key_value($hash, $original_key, $new_key)
}

sub key_value_if_exists {
    my $hash = shift;
    my( $original_key, $new_key ) = @_;
    return __core_key_value_if(
        $hash,
        sub { !! exists shift->{ shift() } },
        $original_key,
        $new_key
    );
}

sub key_value_if_true {
    my $hash = shift;
    my( $original_key, $new_key ) = @_;
    return __core_key_value_if(
        $hash,
        sub { !! shift->{ shift() } },
        $original_key,
        $new_key
    );
}

sub key_value_if_defined {
    my $hash = shift;
    my( $original_key, $new_key ) = @_;
    return __core_key_value_if(
        $hash,
        sub { defined( shift->{ shift() } ) },
        $original_key,
        $new_key
    );
}



=head2 %hash->map_each($key_value_subref) : %new_hash | %$new_hash

Map each key-value pair in the hash using the
$key_value_subref. Similar to how to how map transforms a list into
another list, map_each transforms a hash into another hash.

C<$key_value_subref-E<gt>($key, $value)> is called for each pair (with
$_ set to the value).

The subref should return an even-numbered list with zero or more
key-value pairs which will make up the %new_hash. Typically two items
are returned in the list (the key and the value).

=head3 Example

    { a => 1, b => 2 }->map_each(sub { "$_[0]$_[0]" => $_ * 2 });
    # Returns { aa => 2, bb => 4 }

=cut

sub map_each {
    my $hash = shift;
    my ($key_value_subref) = @_;
    $key_value_subref //= "";
    ref($key_value_subref) eq "CODE"
        or Carp::croak("map_each(\$key_value_subref): \$key_value_subref ($key_value_subref) is not a sub ref");
    my $new_hash = {
        map { ## no critic
            my $key = $_;
            my $value = $hash->{$key};
            {
                local $_ = $value;
                my (@new_key_value) = $key_value_subref->($key, $value);
                (@new_key_value % 2) and Carp::croak("map_each \$key_value_subref returned odd number of keys/values");
                @new_key_value;
            }
        }
        keys %$hash,
    };

    return wantarray ? %$new_hash : $new_hash;
}

=head2 %hash->map_each_value($value_subref) : %new_hash | %$new_hash

Map each value in the hash using the $value_subref, but keep the keys
the same.

C<$value_subref-E<gt>($key, $value)> is called for each pair (with $_
set to the value).

The subref should return a single value for each key which will make
up the %new_hash (with the same keys but with new mapped values).

=head3 Example

    { a => 1, b => 2 }->map_each_value(sub { $_ * 2 });
    # Returns { a => 2, b => 4 }

=cut

sub map_each_value {
    my $hash = shift;
    my ($value_subref) = @_;
    $value_subref //= "";
    ref($value_subref) eq "CODE"
        or Carp::croak("map_each_value(\$value_subref): \$value_subref ($value_subref) is not a sub ref");
    my $new_hash = {
        map { ## no critic
            my $key = $_;
            my $value = $hash->{$key};
            {
                local $_ = $value;
                my @new_values = $value_subref->($key, $value);
                @new_values > 1 and Carp::croak(
                    "map_each_value \$value_subref returned multiple values. "
                    . "You can not assign a list to the value of hash key ($key). "
                    . "Did you mean to return an arrayref?",
                );
                $key => @new_values;
            }
        }
        keys %$hash,
    };

    return wantarray ? %$new_hash : $new_hash;
}

=head2 %hash->map_each_to_array($item_subref) : @new_array | @$new_array

Map each key-value pair in the hash into a list using the
$item_subref.

C<$item_subref-E<gt>($key, $value)> is called for each pair (with $_
set to the value) in key order.

The subref should return zero or more list items which will make up
the @new_array. Typically one item is returned.

=head3 Example

    { a => 1, b => 2 }->map_each_to_array(sub { "$_[0]-$_" });
    # Returns [ "a-1", "b-2" ]

=cut

sub map_each_to_array {
    my $hash = shift;
    my ($array_item_subref) = @_;
    $array_item_subref //= "";
    ref($array_item_subref) eq "CODE"
        or Carp::croak("map_each_to_array(\$array_item_subref): \$array_item_subref ($array_item_subref) is not a sub ref");
    my $new_array = [
        map { ## no critic
            my $key = $_;
            my $value = $hash->{$key};
            {
                local $_ = $value;
                $array_item_subref->($key, $value);
            }
        }
        sort keys %$hash,
    ];

    return wantarray ? @$new_array : $new_array;
}


=head2 %hash->filter_each($predicate = *is_true_subref*) : @hash | @$hash

Return a %hash with values for which $predicate yields a true value.

$predicate can be a subref, string, undef, regex, or hashref. See
L</Filter predicates>.

The default (no $predicate) is a subref which retains true values in
the @array.

Examples:

    my @apples     = $fruit->filter("apple");
    my @any_apple  = $fruit->filter( qr/apple/i );
    my @publishers = $authors->filter(
        sub { $_->publisher->name =~ /Orbit/ },
    );

If the $predicate is a subref, C<$predicate-E<gt>($key,
$value)> is called for each pair (with $_ set to the value).

The subref should return a true value to retain the key-value pair in
the result %hash.

=head3 Example

    $book_author->filter_each(sub { $_->name =~ /Corey/ });

=cut

sub filter_each {
    my $hash = shift;
    my ($predicate) = @_;
    my $subref = autobox::Transform::_predicate(
        "filter_each",
        $predicate,
        sub { !! $_ }, # true?
    );

    my $new_hash = {
        map { ## no critic
            my $key = $_;
            my $value = $hash->{$key};
            {
                local $_ = $value;
                $subref->($key, $value)
                    ? ( $key => $value )
                    : ();
            }
        }
        keys %$hash,
    };

    return wantarray ? %$new_hash : $new_hash;
}
{
    no warnings "once";
    *grep_each = \&filter_each;
}

sub filter_each_defined {
    my $hash = shift;
    return &filter_each($hash, sub { defined($_) });
}
{
    no warnings "once";
    *grep_each_defined = \&filter_each_defined;
}



=head2 %hash->to_ref() : $hashref

Return the reference to the %hash, regardless of context.

Useful for ensuring the last hash method return a reference while in
scalar context. Typically:

    do_stuff(
        genre_count => $books->group_by_count("genre")->to_ref,
    );

=cut

sub to_ref {
    my $hash = shift;
    return $hash;
}

=head2 %hash->to_hash() : %hash

Return the %hash, regardless of context. This is mostly useful if
called on a HashRef at the end of a chain of method calls.

=cut

sub to_hash {
    my $hash = shift;
    return %$hash;
}

=head2 %hash->to_array() : @array | @$array

Return the key-value pairs of the %hash as an @array, ordered by the
keys.

Useful if you need to continue calling @array methods on it.

=cut

sub to_array {
    my $hash = shift;
    my @new_array = map_each_to_array($hash, sub { shift() => $_ });
    return wantarray ? @new_array : \@new_array;
}



=head1 AUTOBOX AND VANILLA PERL


=head2 Raison d'etre

L<autobox::Core> is awesome, for a variety of reasons.

=over 4

=item

It cuts down on dereferencing punctuation clutter, both by using
methods on references and by using ->elements to deref arrayrefs.

=item

It makes map and grep transforms read in the same direction it's
executed.

=item

It makes it easier to write those things in a natural order. No need
to move the cursor around a lot just to fix dereferencing, order of
operations etc.

=back

On top of this, L<autobox::Transform> provides a few higher level
methods for mapping, filtering and sorting common cases which are easier
to read and write.

Since they are at a slightly higher semantic level, once you know them
they also provide a more specific meaning than just "map" or "grep".

(Compare the difference between seeing a "map" and seeing a "foreach"
loop. Just seeing the word "map" hints at what type of thing is going
on here: transforming a list into another list).

The methods of autobox::Transform are not suitable for all
cases, but when used appropriately they will lead to much more clear,
succinct and direct code, especially in conjunction with
autobox::Core.


=head2 Code Comparison

These examples are only for when there's a straightforward and simple
Perl equivalent.

    ### map_by - method call: $books are Book objects
    my @genres = map { $_->genre() } @$books;
    my @genres = $books->map_by("genre");

    my $genres = [ map { $_->genre() } @$books ];
    my $genres = $books->map_by("genre");

    # With sum from autobox::Core / List::AllUtils
    my $book_order_total = sum(
        map { $_->price_with_tax($tax_pct) } @{$order->books}
    );
    my $book_order_total = $order->books
        ->map_by([ price_with_tax => $tax_pct ])->sum;

    ### map_by - hash key: $books are book hashrefs
    my @genres = map { $_->{genre} } @$books;
    my @genres = $books->map_by("genre");



    ### filter_by - method call: $books are Book objects
    my $sold_out_books = [ grep { $_->is_sold_out } @$books ];
    my $sold_out_books = $books->filter_by("is_sold_out");
    my $sold_out_books = $books->grep_by("is_sold_out");

    my $books_in_library = [ grep { $_->is_in_library($library) } @$books ];
    my $books_in_library = $books->filter_by([ is_in_library => $library ]);

    ### filter_by - hash key: $books are book hashrefs
    my $sold_out_books = [ grep { $_->{is_sold_out} } @$books ];
    my $sold_out_books = $books->filter_by("is_sold_out");



    ### uniq_by - method call: $books are Book objects
    my %seen; my $distinct_books = [ grep { ! %seen{ $_->id // "" }++ } @$books ];
    my $distinct_books = $books->uniq_by("id");

    ### uniq_by - hash key: $books are book hashrefs
    my %seen; my $distinct_books = [ grep { ! %seen{ $_->{id} // "" }++ } @$books ];
    my $distinct_books = $books->uniq_by("id");


    #### flat - $author->books returns an arrayref of Books
    my $author_books = [ map { @{$_->books} } @$authors ]
    my $author_books = $authors->map_by("books")->flat



=head1 DEVELOPMENT

=head2 Author

Johan Lindstrom, C<< <johanl [AT] cpan.org> >>


=head2 Source code

L<https://github.com/jplindstrom/p5-autobox-Transform>


=head2 Bug reports

Please report any bugs or feature requests on GitHub:

L<https://github.com/jplindstrom/p5-autobox-Transform/issues>.



=head1 COPYRIGHT & LICENSE

Copyright 2016- Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
