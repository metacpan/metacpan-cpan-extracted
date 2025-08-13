package Text::PrettyTable;

=head1 NAME

Text::PrettyTable - Allow for auto-fixed-width formatting of raw data

=head1 DEPENDENCIES

This module doesn't require any dependencies.

=cut

use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '0.03';

our @border = ('| ', ' | ', ' |', ' ',
               '+-', '-+-', '-+', '-',
               '+-', '-+-', '-+', '-',
               '+-', '-+-', '-+', '-');
our @borderu = ("│ ", " │ ", " │", ' ',
                '┌─', '─┬─', '─┐', '─',
                '├─', '─┼─', '─┤', '─',
                '└─', '─┴─', '─┘', '─');
our $unibox = 1;
our $split  = 100;
our $qr_escape = "[^ -~]";
our @EXPORT = qw(pretty_table);

sub new {
    my $class = shift;
    return bless ref($_[0]) ? $_[0] : {@_}, $class;
}

sub pretty_table { __PACKAGE__->tablify(@_) }
sub plain_text { goto &tablify }

sub tablify {
    my ($self, $data, $args) = @_;
    if (!ref $self) {
        $self = $self->new($args || {});
    } elsif ($args) {
        # Override settings in new object
        my $new_p = __PACKAGE__->new({ %$self, %$args });
        # Clean call without $args
        return $new_p->tablify($data);
    }
    local $self->{'_level'} = 1 + ($self->{'_level'} || 0);

    my $uni   = exists($self->{'unibox'}) ? $self->{'unibox'} : $unibox;
    local $split = $self->{'split'}  || $split if $self->{'_level'} == 1;
    local @border = ref($uni) ? @$uni : map {utf8::decode(my $c = $_); $c} @borderu
        and !$uni or local $qr_escape = "[^ -~".join('', @border)."]" if $uni && $self->{'_level'} == 1;

    my @bucket;
    my @title;
    my @max;
    my @dir;
    my $add = sub {
        my ($cols, $bucket) = @_;
        if (!ref($cols)) {
            for my $chunk ($split ? map {/(.{$split}|.+)/g} split /\n/, $cols : split /\n/, $cols) {
                push @$bucket, $chunk;
            }
            return;
        }
        my $i = @$bucket;
        for my $j (0 .. $#$cols) {
            my $_split = $split;
            my $val = $cols->[$j];
            if (! defined $val) {
                $val = '(undef)';
            } elsif (ref $val) {
                if (UNIVERSAL::isa($val, 'SCALAR')) {
                    $val = (defined(&JSON::true)  && JSON::true()  eq $val) ? '(true)'
                         : (defined(&JSON::false) && JSON::false() eq $val) ? '(false)'
                         : "\\\"$$val\"";
                } else {
                    chomp($val = $self->tablify($val));
                    $_split = 0 if $_split && $val =~ /^\Q$border[4]\E/ && $val =~ /\Q$border[14]\E$/;
                }
            }
            $dir[$j] = 1 if $val =~ /\D/ && $bucket == \@bucket; # TODO - we could work on our alignment
            my $I = $i;
            for my $chunk ($_split ? map {/(.{$_split}|.+)/g} split /\n/, $val : split /\n/, $val) {
                $chunk =~ s/($qr_escape)/sprintf "\\%03o", ord $1/eg;
                $bucket->[$I++]->[$j] = $chunk;
                $max[$j] = length($chunk) if !$max[$j] || $max[$j] < length($chunk);
            }
        }
    };


    if (UNIVERSAL::isa($data, 'HASH')) {
        my $title = $self->{'title'};
        $add->($title, \@title) if $title;
        my @keys = @{ $self->{'sort'} || [sort {($a eq 'id') ? -1 : ($b eq 'id') ? 1 : $a cmp $b } keys %$data] };
        $add->([$_, $data->{$_}], \@bucket) for @keys;
        $add->(['(empty hash)'], \@bucket) if !@bucket;
    } elsif (UNIVERSAL::isa($data, 'ARRAY')) {
        my %title;
        if ($data->[0] && ref($data->[0]) eq 'HASH' && !$self->{'collapse'}) {
            @title{keys %$_} = () for grep {ref($_) eq 'HASH'} @$data; # find all uniques
            my @keys = @{ $self->{'sort'} || [sort {($a eq 'id') ? -1 : ($b eq 'id') ? 1 : $a cmp $b } keys %title] };
            $add->(\@keys, \@title);
            foreach my $row (@$data) {
                if (ref($row) ne 'HASH') {
                    $add->($row, \@bucket);
                    next;
                }
                $add->([@$row{@keys}], \@bucket);
            }
        } else {
            my $title = $self->{'title'};
            $add->($title, \@title) if $title;
            $add->([$_], \@bucket) for @$data;
            $add->(['(empty array)'], \@bucket) if !@bucket;
        }
    }

    my $indent = $self->{'indent'} || '';
    my $sep = "${indent}$border[8]".join($border[9], map {$border[11] x $_} @max)."$border[10]\n";
    my $fmt = "${indent}$border[0]".join($border[1], map {'%'.($dir[$_] ? '-' : '').$max[$_].'s'} 0..$#max)."$border[2]\n";

    if (!$self->{'collapse'} and my $cols = $self->{'auto_collapse'}) {
        $cols = $ENV{'COLUMNS'} || eval { die if ! -t STDOUT; require Term::ReadKey; (Term::ReadKey::GetTerminalSize(\*STDOUT))[0] } || 80 if $cols eq '1';
        if (length($sep) - 1 > $cols) {
            local $self->{'collapse'} = 1;
            local $self->{'_level'} if $self->{'_level'} == 1;
            return $self->tablify($data);
        }
    }

    my $out = "";
    $out .= "${indent}$border[4]".join($border[5], map {$border[7] x $_} @max)."$border[6]\n";
    no warnings 'uninitialized'; # because of multiline
    for my $buck (\@title, \@bucket) {
        for my $row (@$buck) {
            if (ref $row) {
                $out .= sprintf($fmt, @$row);
            } else {
                $out .= sprintf("$border[0]%-*s$border[2]\n", length($sep) - (length($border[0])+length($border[2])+1), $row);
            }
        }
        if ($buck == \@title) {
            $out .= $sep if @title;
        } else {
            $out .= "${indent}$border[12]".join($border[13], map {$border[15] x $_} @max)."$border[14]\n";
        }
    }

    utf8::encode($out) if $self->{'_level'} == 1;
    return $out;
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

    perl -MText::PrettyTable -e 'print pretty_table([qw(Hello Hey There)])'
    ┌───────┐
    │ Hello │
    │ Hey   │
    │ There │
    └───────┘

    perl -MText::PrettyTable -e 'print pretty_table([qw(99 1000 2)])'
    ┌──────┐
    │   99 │
    │ 1000 │
    │    2 │
    └──────┘

    perl -MText::PrettyTable -e 'print pretty_table([qw(99 1000 2)], {title => ["Stuff"], unibox => 0})'
    +-------+
    | Stuff |
    +-------+
    |    99 |
    |  1000 |
    |     2 |
    +-------+

    perl -MText::PrettyTable -e 'print pretty_table({id=>23,hi => "HI", cool => 1})'
    ┌──────┬────┐
    │ id   │ 23 │
    │ cool │ 1  │
    │ hi   │ HI │
    └──────┴────┘

    perl -MText::PrettyTable -e 'print pretty_table({id=>23,hi => "HI", cool => 1}, {title => [qw(Key Value)]})'
    ┌──────┬───────┐
    │ Key  │ Value │
    ├──────┼───────┤
    │ id   │ 23    │
    │ cool │ 1     │
    │ hi   │ HI    │
    └──────┴───────┘

    perl -MText::PrettyTable -e 'print pretty_table([{id=>23,hi => "HI", cool => 1}, {id => 7,hi => "George", cool => "two"}])'
    ┌────┬──────┬────────┐
    │ id │ cool │ hi     │
    ├────┼──────┼────────┤
    │ 23 │ 1    │ HI     │
    │  7 │ two  │ George │
    └────┴──────┴────────┘

    perl -MText::PrettyTable -e 'print pretty_table({id => 23, hi => "HI", cool => [qw(a cee)]})'
    ┌──────┬─────────┐
    │ id   │ 23      │
    │ cool │ ┌─────┐ │
    │      │ │ a   │ │
    │      │ │ cee │ │
    │      │ └─────┘ │
    │ hi   │ HI      │
    └──────┴─────────┘

    perl -MText::PrettyTable -e 'print pretty_table([{id => 23, hi => "HI", cool => [qw(a cee)]}])'
    ┌────┬─────────┬────┐
    │ id │ cool    │ hi │
    ├────┼─────────┼────┤
    │ 23 │ ┌─────┐ │ HI │
    │    │ │ a   │ │    │
    │    │ │ cee │ │    │
    │    │ └─────┘ │    │
    └────┴─────────┴────┘

    perl -MText::PrettyTable -e 'print pretty_table([{id=>23,hi => "HI", cool => 1}, "Wow", {hi => "Row1\nRow2", cool => 98, id=>""}])'
    ┌────┬──────┬──────┐
    │ id │ cool │ hi   │
    ├────┼──────┼──────┤
    │ 23 │    1 │ HI   │
    │ Wow              │
    │    │   98 │ Row1 │
    │    │      │ Row2 │
    └────┴──────┴──────┘

    perl -MText::PrettyTable -e 'print pretty_table([({one => "A"x50, two => "B"x50})x2])'
    ┌────────────────────────────────────────────────────┬────────────────────────────────────────────────────┐
    │ one                                                │ two                                                │
    ├────────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
    │ AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA │ BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB │
    │ AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA │ BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB │
    └────────────────────────────────────────────────────┴────────────────────────────────────────────────────┘

    perl -MText::PrettyTable -e 'print pretty_table([({one => "A"x50, two => "B"x50})x2], {auto_collapse => 100})'
    ┌──────────────────────────────────────────────────────────────┐
    │ ┌─────┬────────────────────────────────────────────────────┐ │
    │ │ one │ AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA │ │
    │ │ two │ BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB │ │
    │ └─────┴────────────────────────────────────────────────────┘ │
    │ ┌─────┬────────────────────────────────────────────────────┐ │
    │ │ one │ AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA │ │
    │ │ two │ BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB │ │
    │ └─────┴────────────────────────────────────────────────────┘ │
    └──────────────────────────────────────────────────────────────┘

    # auto_collapse => 1 will try and determine columns from the terminal

=head1 METHODS

=over 4

=item pretty_table( $data [, $args] )

Function.  Exported by default.  Calls Text::PrettyTable->tablify(@_).

    use Text::PrettyTable;

    print pretty_table([qw(one two three)]);

    print pretty_table([qw(Alice Bob Chuck)], {title => ["Guest"]});

    # Output:
    ┌───────┐
    │ one   │
    │ two   │
    │ three │
    └───────┘
    ┌───────┐
    │ Guest │
    ├───────┤
    │ Alice │
    │ Bob   │
    │ Chuck │
    └───────┘

=item plain_text( $data [, $args] )

Method.  Alias for "tablify" only for backwards compatibility.

=item tablify( $data [, $args] )

Method.  Can be called as a static class method or an object method.
The first argument $data must be a HASH ref or ARRAY ref.
Returns a string of a table represention of the $data structure.
Optional $args hash can be used to override previous object settings
or to override default settings.

    print Text::PrettyTable->tablify($data, {auto_collapse => 100});

    # or

    print Text::PrettyTable->tablify($data, {auto_collapse => 100});

    # or

    my $pt = Text::PrettyTable->new({auto_collapse => 100});
    print $pt->tablify($data);

    # or

    print $pt->tablify($data, {auto_collapse => 150});

    # or


=back

=head1 ARGUMENTS

=over 4

=item auto_collapse

If set will try and automatically shrink the width based on the terminal width.

=item sort

A sort order for keys.  By default it sorts hashes by key.  Any key
not in this sort order will not be present in the output.

=item split

Default is 100.  Length at which to split long lines.  Can also be set
via $Text::PrettyTable::split.

=item title

By default hashes do not have a title header.  You can pass in a
two item arrayref to label the columns.

   title => [qw(Key Value)],

Arrays of non-hashrefs also do not have a title header.  You can
pass in a title header for these as well.

   title => [qw(My Array Column Headings)],

=item unibox

Now default true.  Enables unicode box borders.  Can be either a true
value, or can be a 16 element array defining the border box (See the
code for a sample of alternate boxes).  Can also be set via
$Text::PrettyTable::unibox.

=back

=head1 SEE ALSO

Similar idea with the following:

  Data::Format::Pretty::Console

=head1 AUTHOR

Paul Seamons <paul@seamons.org>

Rob Brown <bbb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 by Rob Brown <bbb@cpan.org>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
