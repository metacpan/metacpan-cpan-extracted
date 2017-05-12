package Text::CSV::Flatten;

use v5.014;
use strict;
use warnings;

our $VERSION = '0.04';

use JSON qw/ encode_json /;
use Text::CSV;

my @KNOWN_ARGS= qw/ column_name /;

sub new {
    my ($class, $pattern, %args)= @_;

    my $data= delete $args{data};

    my %known_args;
    @known_args{@KNOWN_ARGS}= delete @args{@KNOWN_ARGS};
    if(keys %args) {
        my $unknown_keys= join ",", keys %args;
        die "Unknown arguments: $unknown_keys";
    }

    my $self= bless {
        %known_args,
        data_matrix => {},
    }, $class;

    $self->_set_pattern($pattern);
    $self->data($data) if $data;

    return $self;
}

sub _set_pattern {
    my ($self, $pattern_definition)= @_;

    my @pattern_def= split / /, $pattern_definition;

    my %index_column_names;
    my @pattern_parts;
    for my $pattern (@pattern_def) {
        $pattern =~ /^\.(.*)$/
            or die "invalid pattern part: <$pattern>";
        my $p= $1;
        my @pattern= split /\./, $p;

        my @index_column_names= map { /^<(.*)>$/ ? $1 : () } @pattern;
        $index_column_names{ join("\0", @index_column_names) }= 1;

        push @pattern_parts, \@pattern;
    }

    if(keys %index_column_names == 1) {
        $self->{index_column_names}= [ split "\0", (keys %index_column_names)[0] ];
    } else {
        die "Invalid pattern: the different pattern chunks have different index columns";
    }

    $self->{pattern_parts}= \@pattern_parts;
}

sub data {
    my ($self, $data)= @_;

    my $data_matrix= $self->{data_matrix};
    my $pattern_parts= $self->{pattern_parts};

    my @default_column_names;
    if(my $default_column_name= $self->{column_name}) {
        if(ref $default_column_name eq 'ARRAY') {
            @default_column_names= @$default_column_name;
        } else {
            @default_column_names= ($self->{column_name}) x @$pattern_parts;
        }
    }
    for my $pattern (@$pattern_parts) {
        my $has_column_name= scalar grep {
            $_ eq '*' || /^{(.*)}$/
        } @$pattern;
        $self->{_default_column_name}= shift @default_column_names
            if !$has_column_name;
        $self->_recurse_pattern($data, $pattern, [], []);
    }

    return $self;
}

sub csv {
    my ($self)= @_;

    my $data_matrix= $self->{data_matrix};
    my $index_column_names= $self->{index_column_names};

    my @records;
    my %column_names;
    for my $index (sort keys %$data_matrix) {
        my $data= $data_matrix->{$index};
        my %record;
        @record{@$index_column_names}= _deserialize_tuple($index);
        for my $column_key (keys %$data) {
            my $friendly_column_name= join "_", _deserialize_tuple($column_key);
            $record{$friendly_column_name}= $data->{$column_key};
        }
        @column_names{keys %record}= (1) x keys %record;

        push @records, \%record;
    }
    my @column_names= sort keys %column_names;
    my $render_header= scalar grep $_, @column_names;

    my $csv= Text::CSV->new({binary => 1});

    my @result;
    if($render_header) {
        if(my $status= $csv->combine(@column_names)) {
            push @result, $csv->string();
        } else {
            my $error= $csv->error_input();
            die "Error while rendering header row: $error";
        }
    }
    for my $record (@records) {
        my @columns= @$record{@column_names};
        if(my $status= $csv->combine(@columns)) {
            push @result, $csv->string();
        } else {
            my $error= $csv->error_input();
            die "Error while rendering row: $error";
        }
    }

    return join "\n", @result;
}

# utility function to iterate over key => value pairs with the added
# bonus that it also works for arrays
sub _foreach(&$) {
    my ($codeblock, $it)= @_;

    if(!defined $it || !ref $it) {
        return;
    } elsif('ARRAY' eq ref $it) {
        for my $i (0 .. @$it - 1) {
            $codeblock->($i, $it->[$i]);
        }
    } elsif('HASH' eq ref $it) {
        for my $i (keys %$it) {
            $codeblock->($i, $it->{$i});
        }
    } elsif($it->can('TO_JSON')) {
        no warnings 'prototype';            # avoid "_foreach() called too early to check prototype"
        _foreach($codeblock, $it->TO_JSON);
    } else {
        die "Can't iterate over item";
    }
}

sub _serialize_tuple {
    return pack "(S/a)*", @_;
}

sub _deserialize_tuple {
    return unpack "(S/a)*", $_[0];
}

sub _recurse_pattern {
    my ($self, $cur_data, $pattern, $column_name_prefix, $index_prefix)= @_;

    if(@$pattern) {
        my ($p, @p)= @$pattern;
        eval {
            if($p eq '*') {
                _foreach {
                    my ($key, $value)= @_;
                    _recurse_pattern($self, $value, \@p, [@$column_name_prefix, $key], $index_prefix);
                } $cur_data;
            } elsif($p =~ /^{(.*)}$/) {
                my @keys= split ',', $1;
                for my $key (@keys) {
                    my $recurse_data;
                    if(ref $cur_data eq 'HASH' && exists $cur_data->{$key}) {
                        _recurse_pattern($self, $cur_data->{$key}, \@p, [@$column_name_prefix, $key], $index_prefix)
                    } elsif(ref $cur_data eq 'ARRAY' && exists $cur_data->[$key]) {
                        _recurse_pattern($self, $cur_data->[$key], \@p, [@$column_name_prefix, $key], $index_prefix)
                    }
                }
            } elsif($p =~ /^<(.*)>$/) {
                _foreach {
                    my ($key, $value)= @_;
                    _recurse_pattern($self, $value, \@p, $column_name_prefix, [@$index_prefix, $key]);
                } $cur_data;
            } else {
                if(ref $cur_data eq 'HASH' && exists $cur_data->{$p}) {
                    _recurse_pattern($self, $cur_data->{$p}, \@p, $column_name_prefix, $index_prefix)
                } elsif(ref $cur_data eq 'ARRAY' && exists $cur_data->[$p]) {
                    _recurse_pattern($self, $cur_data->[$p], \@p, $column_name_prefix, $index_prefix)
                }
            }
            1;
        } or do {
            my $error= $@ || "Zombie error";
            my $debugstr= join(".", "-->$p<--", @p);
            die "Error while applying pattern chunk $debugstr: $error";
        }
    } else {
        my $cell_value= ref $cur_data
                      ? encode_json($cur_data)
                      : $cur_data;
        my @column_tuple= @$column_name_prefix ? @$column_name_prefix : ($self->{_default_column_name} || '');
        $self->{data_matrix}{_serialize_tuple(@$index_prefix)}{_serialize_tuple(@column_tuple)}= $cell_value;
    }
}


1;
__END__

=head1 NAME

Text::CSV::Flatten - Perl extension for transforming hierarchical data (nested
arrays/hashes) to comma-separated value (csv) output according to a compact,
readable, user-specified pattern.


=head1 SYNOPSIS

  use Text::CSV::Flatten;
  Text::CSV::Flatten->new(
    '.<index>.*',
    data    => [{ a => 1, b => 2 }, { a => 3, b => 4 }],
  )->csv();

=head1 DESCRIPTION

This module transforms hierarchical data (nested arrays/hashes) to
comma-separated value (csv) output according to a compact, readable,
user-specified pattern.

For example, the pattern C<< .<index>.* >> transforms a data structure
of the form

    [{ a => 1, b => 2 }, { a => 3, b => 4 }]

to the CSV output

    a,b,index
    1,2,0
    3,4,1

The pattern C<.*.*> applied to the same data gives the output

    0_a,0_b,1_a,1_b
    1,2,3,4

The pattern C<< .*.<key> >> gives the output

    0,1,key
    1,3,a
    2,4,b

It is hoped that the pattern specification is sufficiently powerful for this
module to replace a lot of simple boiler-plate data transformations.

=head1 PATTERN SPECIFICATION

The dot-separated components represent the following:

=over

=item

C<< <name> >> represents that the keys at that position should be put in a
column named name in the csv output. This column will be considered a primary
key, and the values belonging to those keys become rows;

=item

C<*> represents that the keys at that position in the pattern should be
interpreted as column names; their values should be the values for that column,
all beloning to the same row;

=item

C<{column_name}> or C<{column_name_1,column_name_2,...}> is similar to C<*>,
but instead of capturing all the keys at that level of the hierarchy, it only
captures the named columns.

=item

anything else represents a literal key name.

=item

If your pattern does not contain C<*> or C<{...}>, you need to pass an
additional C<< column_name => >> parameter to the constructor to specify the
name for the single column where the value will go.

=back

For the purposes of this description, an array should be seen as a collection
of index => value pairs.

It is possible to specify several dot-separated paths in a single pattern,
separated by spaces. In that case, all the paths need to have the same primary
key (that is, the same set of names in C<< <...> >>). Rows will be formed by
joining the columns resulting from the different paths.

=head1 SEE ALSO

  Text::CSV

=head1 AUTHOR

Timo Kluck, E<lt>tkluck@infty.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Timo Kluck

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
