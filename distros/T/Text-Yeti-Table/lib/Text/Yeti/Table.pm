
package Text::Yeti::Table;
$Text::Yeti::Table::VERSION = '0.1.0';
# ABSTRACT: Render a table like "docker ps" does

use 5.010001;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw(render_table);

# default stringification
my $TO_S = sub { defined $_[0] ? "$_[0]" : "<none>" };

sub _render_table {
    my ( $items, $spec, $io ) = ( shift, shift, shift );

    my ( @rows, @len );
    my @spec = map { ref $_ ? $_ : [$_] } @$spec;
    my @c = map { $_->[0] } @spec;

    # Compute table headers
    my @h = map {
        $_->[2] // do { local $_ = $_->[0]; s/([a-z])([A-Z])/$1 $2/g; uc }
    } @spec;
    @len = map { length $_ } @h;
    push @rows, \@h;

    # Compute table rows, keep track of max length
    my @to_s = map { $_->[1] // $TO_S } @spec;
    for my $item (@$items) {
        my @v = map { $to_s[$_]->( $item->{ $c[$_] }, $item ) } 0 .. $#c;
        $len[$_] = max( $len[$_], length $v[$_] ) for 0 .. $#c;
        push @rows, \@v;
    }

    # Compute the table format
    my $fmt = join( " " x 3, map {"%-${_}s"} @len ) . "\n";

    # Render the table
    printf {$io} $fmt, @$_ for @rows;
}

sub render_table {
    _render_table( shift, shift, shift // \*STDOUT );
}

sub max { $_[0] >= $_[1] ? $_[0] : $_[1] }

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Text::Yeti::Table qw(render_table);
#pod
#pod     render_table( $list, $spec );
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Text::Yeti::Table> renders a table of data into text.
#pod Given a table (which is an arrayref of hashrefs) and a specification,
#pod it creates output such as below.
#pod
#pod     CONTAINER ID   IMAGE                   CREATED       STATUS               NAME           
#pod     632495650e4e   alpine:latest           5 days ago    Exited 5 days ago    zealous_galileo
#pod     6459c004a7b4   postgres:9.6.1-alpine   23 days ago   Up 23 days           hardcore_sammet
#pod     63a4c1b60c9f   f348af3681e0            2 weeks ago   Exited 12 days ago   elastic_ride   
#pod
#pod The specification can be as simple as:
#pod
#pod     [ 'key1', 'key2', 'key3' ]
#pod
#pod For complex values, a function can be given for the text conversion.
#pod
#pod     [ 'name', 'id', 'node', 'address', [ 'tags', sub {"@{$_[0]}"} ] ]
#pod
#pod Usually headers are computed from keys, but that can be overriden.
#pod
#pod     [ 'ServiceName', 'ServiceID', 'Node', [ 'Datacenter', undef, 'DC' ] ]
#pod
#pod =head1 EXAMPLE
#pod
#pod The following code illustrates a full example:
#pod
#pod     my @items = (
#pod         {   ContainerId => '632495650e4e',
#pod             Image       => 'alpine:latest',
#pod             Created     => { unit => 'days', amount => 5 },
#pod             ExitedAt    => { unit => 'days', amount => 5 },
#pod             Name        => '/zealous_galileo',
#pod         },
#pod         {   ContainerId => '6459c004a7b4',
#pod             Image       => 'postgres:9.6.1-alpine',
#pod             Created     => { unit => 'days', amount => 23 },
#pod             StartedAt   => { unit => 'days', amount => 23 },
#pod             Running     => true,
#pod             Name        => '/hardcore_sammet',
#pod         },
#pod         {   ContainerId => '63a4c1b60c9f',
#pod             Image       => 'f348af3681e0',
#pod             Created     => { unit => 'weeks', amount => 2 },
#pod             ExitedAt    => { unit => 'days', amount => 12 },
#pod             Name        => '/elastic_ride',
#pod         },
#pod     );
#pod
#pod     sub status_of {
#pod         my ( $running, $item ) = ( shift, shift );
#pod         $running
#pod           ? "Up $item->{StartedAt}{amount} $item->{StartedAt}{unit}"
#pod           : "Exited $item->{ExitedAt}{amount} $item->{ExitedAt}{unit} ago";
#pod     }
#pod
#pod     my @spec = (
#pod         'ContainerId',
#pod         'Image',
#pod         [ 'Created', sub {"$_[0]->{amount} $_[0]->{unit} ago"} ],
#pod         [   'Running', \&status_of, 'STATUS' ],
#pod         [ 'Name', sub { substr( shift, 1 ) } ],
#pod     );
#pod
#pod     render_table( \@items, \@spec );
#pod
#pod The corresponding output is the table in L</"DESCRIPTION">.
#pod
#pod =head1 FUNCTIONS
#pod
#pod L<Text::Yeti::Table> implements the following functions, which can be imported individually.
#pod
#pod =head2 render_table
#pod
#pod     render_table( \@items, $spec );
#pod     render_table( \@items, $spec, $io );
#pod
#pod The C<$spec> is an arrayref whose entries are:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod a string (like C<'key>'), which is equivalent to
#pod
#pod     ['key']
#pod
#pod =item *
#pod
#pod an arrayref, with up to 3 entries
#pod
#pod     ['key', $to_s, $header]
#pod
#pod C<$to_s> is a function to convert the value under C<'key'> to text.
#pod By default, it stringifies the value, except for C<undef> which
#pod becomes C<< "<none>" >>.
#pod
#pod C<$header> is the header for the corresponding column.
#pod By default, it is computed from the key, as in the examples below:
#pod
#pod     "image"       -> "IMAGE"
#pod     "ContainerID" -> "CONTAINER ID"
#pod
#pod =back
#pod
#pod The C<$io> is a handle. By default, output goes to C<STDOUT>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Yeti::Table - Render a table like "docker ps" does

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use Text::Yeti::Table qw(render_table);

    render_table( $list, $spec );

=head1 DESCRIPTION

L<Text::Yeti::Table> renders a table of data into text.
Given a table (which is an arrayref of hashrefs) and a specification,
it creates output such as below.

    CONTAINER ID   IMAGE                   CREATED       STATUS               NAME           
    632495650e4e   alpine:latest           5 days ago    Exited 5 days ago    zealous_galileo
    6459c004a7b4   postgres:9.6.1-alpine   23 days ago   Up 23 days           hardcore_sammet
    63a4c1b60c9f   f348af3681e0            2 weeks ago   Exited 12 days ago   elastic_ride   

The specification can be as simple as:

    [ 'key1', 'key2', 'key3' ]

For complex values, a function can be given for the text conversion.

    [ 'name', 'id', 'node', 'address', [ 'tags', sub {"@{$_[0]}"} ] ]

Usually headers are computed from keys, but that can be overriden.

    [ 'ServiceName', 'ServiceID', 'Node', [ 'Datacenter', undef, 'DC' ] ]

=head1 EXAMPLE

The following code illustrates a full example:

    my @items = (
        {   ContainerId => '632495650e4e',
            Image       => 'alpine:latest',
            Created     => { unit => 'days', amount => 5 },
            ExitedAt    => { unit => 'days', amount => 5 },
            Name        => '/zealous_galileo',
        },
        {   ContainerId => '6459c004a7b4',
            Image       => 'postgres:9.6.1-alpine',
            Created     => { unit => 'days', amount => 23 },
            StartedAt   => { unit => 'days', amount => 23 },
            Running     => true,
            Name        => '/hardcore_sammet',
        },
        {   ContainerId => '63a4c1b60c9f',
            Image       => 'f348af3681e0',
            Created     => { unit => 'weeks', amount => 2 },
            ExitedAt    => { unit => 'days', amount => 12 },
            Name        => '/elastic_ride',
        },
    );

    sub status_of {
        my ( $running, $item ) = ( shift, shift );
        $running
          ? "Up $item->{StartedAt}{amount} $item->{StartedAt}{unit}"
          : "Exited $item->{ExitedAt}{amount} $item->{ExitedAt}{unit} ago";
    }

    my @spec = (
        'ContainerId',
        'Image',
        [ 'Created', sub {"$_[0]->{amount} $_[0]->{unit} ago"} ],
        [   'Running', \&status_of, 'STATUS' ],
        [ 'Name', sub { substr( shift, 1 ) } ],
    );

    render_table( \@items, \@spec );

The corresponding output is the table in L</"DESCRIPTION">.

=head1 FUNCTIONS

L<Text::Yeti::Table> implements the following functions, which can be imported individually.

=head2 render_table

    render_table( \@items, $spec );
    render_table( \@items, $spec, $io );

The C<$spec> is an arrayref whose entries are:

=over 4

=item *

a string (like C<'key>'), which is equivalent to

    ['key']

=item *

an arrayref, with up to 3 entries

    ['key', $to_s, $header]

C<$to_s> is a function to convert the value under C<'key'> to text.
By default, it stringifies the value, except for C<undef> which
becomes C<< "<none>" >>.

C<$header> is the header for the corresponding column.
By default, it is computed from the key, as in the examples below:

    "image"       -> "IMAGE"
    "ContainerID" -> "CONTAINER ID"

=back

The C<$io> is a handle. By default, output goes to C<STDOUT>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Adriano Ferreira

Adriano Ferreira <a.r.ferreira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
