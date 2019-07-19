package Test::NiceDump;
use strict;
use warnings;

use Exporter "import";

use Test::Builder;
use Safe::Isa 1.000010;
use overload ();
use Data::Dump;
use Data::Dump::Filtered;

our @EXPORT_OK = ("nice_explain", "nice_dump");

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: let's have a nice and human readable dump of our objects!


sub _dd_recurse {
    my ($object) = @_;
    # Data::Dump resets its filters when dumping the objects
    # we return; if we do it this way, we force it to keep
    # filtering, so (e.g.) datetime objects inside DBIC rows
    # will get dumped the way we want
    return Data::Dump::Filtered::dump_filtered(
        $object,
        \&_dd_filter,
    );
}

# functions to modify this hash are at the bottom of this file
my %filters = (
    'Test::NiceDump::010_DateTime' => sub {
        $_[0]->$_isa('DateTime')
            ? $_[0]->format_cldr("yyyy-MM-dd'T'HH:mm:ssZZZZZ")
            : ();
    },
    'Test::NiceDump::011_Test_Deep_Methods' => sub {
        $_[0]->$_isa('Test::Deep::Methods')
            ? $_[0]->{methods}
            : ();
    },
    'Test::NiceDump::012_Test_Deep' => sub {
        (ref($_[0]) || '') =~ /^Test::Deep::/
            ? $_[0]->{val}
            : ();
    },
    'Test::NiceDump::013_DBIC_Schema' => sub {
        $_[0]->$_isa('DBIx::Class::Schema')
            ? 'DBIx::Class::Schema object'
            : ();
    },
    'Test::NiceDump::020_overload' => sub { overload::Method($_[0],q{""}) ? "$_[0]" : () },
    'Test::NiceDump::021_as_string' => sub { shift->$_call_if_can('as_string') },
    'Test::NiceDump::022_to_string' => sub { shift->$_call_if_can('to_string') },
    'Test::NiceDump::023_toString' => sub { shift->$_call_if_can('toString') },
    'Test::NiceDump::024_TO_JSON' => sub { shift->$_call_if_can('TO_JSON') },
    'Test::NiceDump::030_get_inflated_columns' => sub {
        my %c = shift->$_call_if_can('get_inflated_columns');
        %c ? \%c : ();
    },
);

sub _dd_filter {
    my ($ctx, $object) = @_;

    for my $filter_name (sort keys %filters) {
        my $filter_code = $filters{$filter_name};
        my @filtered_object = $filter_code->($object);
        if (@filtered_object) {
            return {
                dump => _dd_recurse($filtered_object[0]),
                comment => $ctx->class,
            };
        }
    }

    return;
}


sub nice_dump {
    my ($data) = @_;
    return Data::Dump::Filtered::dump_filtered( $data, \&_dd_filter );
}


sub nice_explain {
    my ($data, $comparator) = @_;
    my $tb = Test::Builder->new; # singleton
    $tb->diag("Got:" . nice_dump( $data ));
    $tb->diag("Expected: " . nice_dump( $comparator )) if defined $comparator;
    return 0; # like diag / explain do
}


sub add_filter {
    my ($filter_name, $filter_code) = @_;
    $filters{$filter_name} = $filter_code;
    return;
}

sub remove_filter {
    my ($filter_name) = @_;
    delete $filters{$filter_name};
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::NiceDump - let's have a nice and human readable dump of our objects!

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    use Test::Deep;
    use Test::NiceDump 'nice_explain';

    cmp_deeply($got,$expected,'it works')
        or nice_explain($got,$expected);

=head1 DESCRIPTION

This module uses L<< C<Data::Dump::Filtered> >> and a set of sensible
filters to dump test data in a more readable way.

For example, L<< C<DateTime> >> objects get printed in the full ISO
8601 format, and L<< C<DBIx::Class::Row> >> objects get printed as
hashes of their inflated columns.

=head1 FUNCTIONS

=head2 C<nice_dump>

    my $dumped_string = nice_dump $data;

Serialise C<$data> in a nice, readable way.

=head2 C<nice_explain>

    nice_explain $data;
    nice_explain $data, $comparator;

Calls L<< /C<nice_dump> >> on C<$data> and C<$comparator> (if
provided), and uses L<< C<diag>|Test::Builder/diag >> to provide test
failure feedback with the dumped strings.

=head1 HOW TO ADD FILTERS

If the built-in filtering of input data is not enough for you, you can
add extra filters. A filter is a coderef that takes a single argument
(the value to be dumped), and returns either:

=over

=item nothing at all

to signal that it won't handle this particular value

=item any single value

which will be dumped instead

=back

Let's say you have a class C<My::Class>, and you don't want its
instances to be dumped directly (maybe they contain cached data that's
not very useful to see). That class may have a C<as_data_for_log>
method that returns only the important bits of data (as a hashref,
probably), so you want the return value of that method to be dumped
instead. You could say:

    use Safe::Isa;

    Test::NiceDump::add_filter(
        my_filter => sub {
            $_[0]->$_isa('My::Class')
                ? $_[0]->as_data_for_log
                : ();
        },
    );

or, if you want to do the same for any object with that method:

    use Safe::Isa;

    Test::NiceDump::add_filter(
        my_filter => sub { $_[0]->$_call_if_can('as_data_for_log') },
    );

=head2 C<add_filter>

  Test::NiceDump::add_filter($name => $code);

Adds a new filter. Adding a filter with an existing name overrides it.

Filters are invoked in C<cmp> order of name. The names of all built-in
filters match C</^Test::NiceDump::/>.

Try to be specific with your checks, to avoid surprises due to the
interaction of different filters.

Your filter I<must> return nothing at all if it didn't handle the
value. Failure to do so will probably lead to infinite recursion.

=head2 C<remove_filter>

  Test::NiceDump::remove_filter($name);

Removes the filter with the given name. Nothing happens if such a
filter does not exist.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
