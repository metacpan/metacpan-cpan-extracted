use strict;
use warnings;

package Text::SimpleTable::AutoWidth;
$Text::SimpleTable::AutoWidth::VERSION = '0.09';
use Moo;

# ABSTRACT: Text::SimpleTable::AutoWidth - Simple eyecandy ASCII tables with auto-width selection


has 'fixed_width' => ( is => 'rw', default => 0 );  # isa => 'Int'
has 'max_width'   => ( is => 'rw', default => 0 );  # isa => 'Int'

has 'captions' => ( is => 'rw' );                   # isa => 'ArrayRef[Str]'
has 'rows'     => ( is => 'rw' );                   # isa => 'ArrayRef[ArrayRef[Str]]'

our $WIDTH_LIMIT = 200;    # default maximum width


sub row {
    my ( $self, @texts ) = @_;

    if ( $self->rows ) {
        push( @{ $self->rows }, [@texts] );
    }
    else {
        $self->rows( [ [@texts] ] );
    }

    return $self;
}


use List::Util;
use Text::SimpleTable;

sub draw {
    my $self = shift;

    # count of columns will be same as count of captions, or same
    # as count of columns in first row, if there is no captions
    my $columns =
         ( $self->captions && @{ $self->captions } )
      || ( $self->rows && @{ $self->rows->[0] } )
      || 0;

    return unless $columns;

    # table will not be wider than limits
    my $limit =
        $self->max_width   ? $self->max_width
      : $self->fixed_width ? $self->fixed_width
      :                      $WIDTH_LIMIT;

    # by default, each column should have at least 2 symbols:
    # one informative and one for '-' (if we'll need to wrap)
    my @max_width = (2) x $columns;

    # calculate max width of each column
    for my $row ( ( $self->captions ? $self->captions : () ), @{ $self->rows } ) {
        my @row_width = map { length } @$row;
        $#row_width = $columns - 1 if $#row_width >= $columns;

        # find new width
        # we will do this in two passes
        my @new_width = @max_width;

        # first pass:
        # find new width for all columns, that we can
        # make wider without need to wrap anything
        for my $idx ( 0 .. $#row_width ) {
            if ( $max_width[$idx] < $row_width[$idx] ) {
                $new_width[$idx] = $row_width[$idx];

                # check for limits
                my $total = $columns + 1    # for each '|'
                  + $columns * 2            # for spaces around each value
                  + List::Util::reduce { $a + $b } @new_width;

                # restore old value, if new value will lead to wrap
                $new_width[$idx] = $max_width[$idx]
                  if $total > $limit;
            }
        }

        # second pass:
        # find new width for all columns, that we can
        # make wider and need to wrap something
        for my $idx ( 0 .. $#row_width ) {
            if ( $new_width[$idx] < $row_width[$idx] ) {
                my $total = $columns + 1    # for each '|'
                  + $columns * 2            # for spaces around each value
                  + List::Util::reduce { $a + $b } @new_width;

                $new_width[$idx] += $limit - $total;
                last;
            }
        }

        # save new result
        @max_width = @new_width;

        # check for limits
        my $total = $columns + 1            # for each '|'
          + $columns * 2                    # for spaces around each value
          + List::Util::reduce { $a + $b } @max_width;

        last if $total >= $limit;
    }

    # check for fixed_width
    if ( $self->fixed_width ) {
        my $total = $columns + 1            # for each '|'
          + $columns * 2                    # for spaces around each value
          + List::Util::reduce { $a + $b } @max_width;

        $max_width[-1] += $self->fixed_width - $total
          unless $total == $self->fixed_width;
    }

    # prepare drawer
    my @params = @max_width;

    if ( $self->captions ) {
        my $idx = 0;
        for (@params) {
            $_ = [ $_, $self->captions->[ $idx++ ] ];
        }
    }
    my $tab = Text::SimpleTable->new(@params);

    # put rows into drawer
    $tab->row(@$_) for @{ $self->rows };

    return $tab->draw();
}

__PACKAGE__->meta->make_immutable();


1;    # End of Text::SimpleTable::AutoWidth

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::SimpleTable::AutoWidth - Text::SimpleTable::AutoWidth - Simple eyecandy ASCII tables with auto-width selection

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Text::SimpleTable::AutoWidth;

    my $t1 = Text::SimpleTable::AutoWidth->new();
    $t1->row( 'foobarbaz', 'yadayadayada' );
    print $t1->draw;

    .-----------+--------------.
    | foobarbaz | yadayadayada |
    '-----------+--------------'


    my $t2 = Text::SimpleTable::AutoWidth->new();
    $t2->captions( 'Foo', 'Bar' );
    $t2->row( 'foobarbaz', 'yadayadayada' );
    $t2->row( 'barbarbarbarbar', 'yada' );
    print $t2->draw;

    .-----------------+--------------.
    | Foo             | Bar          |
    +-----------------+--------------+
    | foobarbaz       | yadayadayada |
    | barbarbarbarbar | yada         |
    '-----------------+--------------'

=head1 DESCRIPTION

Simple eyecandy ASCII tables with auto-selection columns width,
as seen in L<Catalyst>.

=head1 METHODS

=head2 new(@attrs)

Inherited constructor from Moo.
You can set following attributes:

=head3 fixed_width

Set fixed width for resulting table. By default it's 0,
that's mean "don't fix width", so width of result table
will depend on input data.

Be warned, that fixed_width will include not only width of your data,
but also all surronding characters, like spaces across values,
table drawings (like '|') and hypen (if wrapping is needed).

=head3 max_width

Set maximum width for resulting table. By default it's 0,
that's mean "use default value". Default value is stored in
$Text::SimpleTable::AutoWidth::WIDTH_LIMIT, and can be changed
at any moment. Default value for WIDTH_LIMIT is 200.

Be warned, that max_width will include not only width of your data,
but also all surronding characters, like spaces across values,
table drawings (like '|') and hypen (if wrapping is needed).

NB: if you set fixed_width and max_width at same time, then you'll
get table with fixed width, but not wider than max_width characters.

=head3 captions

ArrayRef[Str] for captions in resulting table.

=head3 rows

ArrayRef[ArrayRef[Str]] for values in each row.
You can use next method to add individual rows into table.

=head2 row(@texts)

Add new row to table. Return $self, so you can write something like this:

    print Text::SimpleTable::AutoWidth
        ->new( max_width => 55, captions => [qw/ Name Age /] )
        ->row( 'Mother', 59 )
        ->row( 'Dad', 58 )
        ->row( 'me', 32 )
        ->draw();

=head2 draw()

Draw table. Really, just calculate column width, and then call Text::SimpleTable->draw().

=head1 GIT REPOSITORY

git clone git://github.com/cub-uanic/Text-SimpleTable-AutoWidth.git

=head1 SEE ALSO

L<Text::SimpleTable>, L<Moo>, L<Catalyst>

=head1 AUTHOR

Oleg Kostyuk, C<< <cub#cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright by Oleg Kostyuk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Oleg Kostyuk <cub.uanic@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Oleg Kostyuk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
