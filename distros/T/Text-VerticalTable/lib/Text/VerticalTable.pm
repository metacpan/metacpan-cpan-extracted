package Text::VerticalTable;
use strict;
use warnings;
use utf8;
use Carp qw/croak/;
use overload '""' => '_drawit';
use List::Util qw/max/;

our $VERSION = '0.01';

sub new {
    my $class = shift;

    bless {
        _tbl => [],
    }, $class;
}

sub setHead {
    my ($self, $title) = @_;

    push @{$self->{_tbl}}, { head => $title, lines => [] };

    $self;
}

sub addRow {
    my $self = shift;

    if (ref ${$self->{_tbl}}[-1] ne 'HASH') {
        croak "setHead first";
    }

    my ($key, $value) = scalar(@_) == 1 && ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;

    push @{${$self->{_tbl}}[-1]{lines}}, [$key, $value];

    $self;
}

sub _drawit {scalar shift()->draw()}

sub draw {
    my $self = shift;

    my @lines;
    my $count = 1;

    for my $tbl (@{$self->{_tbl}}) {
        push @lines, sprintf("%s %s. %s %s", '*'x10, $count, $tbl->{head} || 'row', '*'x10);
        my $max_key_length = max(map { length $_->[0] } @{$tbl->{lines}});
        for my $line (@{$tbl->{lines}}) {
            my ($key, $value) = @{$line};
            push @lines, sprintf(
                "%s: %s",
                sprintf("%${max_key_length}s", $key), $value
            );
        }
        $count++;
    }

    join("\n", @lines) . "\n";
}

1;

__END__

=encoding UTF-8

=head1 NAME

Text::VerticalTable - Create a nice formatted `key, value` table vertically


=head1 SYNOPSIS

    use Text::VerticalTable;

    my $t = Text::VerticalTable->new;
    $t->setHead('explain result');
    $t->addRow(id => 1);
    $t->addRow(select_type => 'SIMPLE');
    $t->addRow(table => 'foo');
    print $t;

    # Result:
    ********** 1. explain result **********
             id: 1
    select_type: SIMPLE
          table: foo


=head1 DESCRIPTION

Text::VerticalTable is the text formatter for `key, value` list.


=head1 METHODS

=head2 new

Initialize a new table.

=head2 setHead($title)

Set the title line.

=head2 addRow(key => 'value')

Adds one row to the table.

Note that you need to call C<setHead> before calling C<addRow>.

=head2 draw

build table


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Text-VerticalTable"><img src="https://secure.travis-ci.org/bayashi/Text-VerticalTable.png"/></a> <a href="https://coveralls.io/r/bayashi/Text-VerticalTable"><img src="https://coveralls.io/repos/bayashi/Text-VerticalTable/badge.png?branch=master"/></a>

=end html

Text::VerticalTable is hosted on github: L<http://github.com/bayashi/Text-VerticalTable>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Text::ASCIITable>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
