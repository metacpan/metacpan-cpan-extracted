package Text::SimSearch;
use strict;
use warnings;
use strict;
use warnings;
use Storable qw( nstore retrieve);
use Time::HiRes qw(gettimeofday tv_interval);

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    return $self;
}

sub add_item_from_file {
    my $self             = shift;
    my $file             = shift;
    my $max_posting_size = shift || 1000;

    my $tmp_data;
    my $labels;
    open my $fh, "<", $file
        or die("can not open $file");
    my $i = 0;
    while (<$fh>) {
        chomp $_;
        my @f = split "\t", $_;
        my $label = shift @f;
        $labels->[$i] = $label;

        my %vec = @f;
        my $vec = $self->_unit_length( \%vec );
        while ( my ( $key, $val ) = each %$vec ) {
            next unless $val > 0;
            $tmp_data->{$key}->{$i} = $val;
        }

        $i++;
    }
    close($fh);

    # make "Posting-Lists" from $tmp_data created above.
    # Note: concatenate the label-ID and the weight as string,
    #       and then convert it to interger value.

    my $posting_lists;

    my $key_scale = int( log( int @$labels ) / log(10) ) + 1;
    my $val_scale = 6;

    $i = 0;
    while ( my ( $key, $ref ) = each %$tmp_data ) {

        my @array;
        for ( keys %$ref ) {

            my $label_id = $_;
            my $weight   = $ref->{$label_id};

            # convert the weight to integer value.
            my $condition = '%.' . $val_scale . 'f';
            my $integer = sprintf( $condition, $weight ) * ( 10**$val_scale );

            # convert the label_id to integer value, and connect to $interger.
            $condition = '%0' . $key_scale . 'd';
            $integer .= sprintf( $condition, $label_id );
            push @array, $integer;
        }

        # cut down posting-list to suitable size and compress it.
        my @tmp;
        my $n = 0;
    LABEL:
        for ( sort { $b <=> $a } @array ) {
            my $p = pack( "w*", $_ );
            push @tmp, $p;
            last LABEL if ++$n == $max_posting_size;
        }

        $posting_lists->{$key} = \@tmp;

        $i++;
    }

    $self->{index_data} = {
        posting_lists => $posting_lists,
        labels        => $labels,
        key_scale     => $key_scale,
        val_scale     => $val_scale
    };
}

sub search {
    my $self         = shift;
    my $query_vector = shift;
    my $number       = shift || 10;

    my $t0 = [gettimeofday];

    my $vec       = $self->_unit_length($query_vector);
    my $key_scale = $self->{index_data}->{key_scale};
    my $val_scale = $self->{index_data}->{val_scale};

    my $dot_product;
    while ( my ( $q_key, $q_val ) = each %$vec ) {
        my $compressed_array = $self->{index_data}->{posting_lists}->{$q_key};
        next if !$compressed_array;
    LABEL:
        my $max;

        for (@$compressed_array) {

            # decompress and decode
            my $string   = unpack( "w*", $_ );
            my $count    = length($string) - $key_scale;
            my $val      = substr( $string, 0, $count );
            my $label_id = int substr( $string, $count, $key_scale );
            $val = $val / ( 10**$val_scale );

            # calculate similarities
            $dot_product->{$label_id} += $q_val * $val;
        }
    }

    my @list;
    for (
        sort { $dot_product->{$b} <=> $dot_product->{$a} }
        keys %$dot_product
        )
    {
        my $similarity = sprintf( "%8.6f", $dot_product->{$_} );
        my $label = $self->{index_data}->{labels}->[$_];
        push @list, { label => $label, similarity => $similarity };
        last if int @list == $number;
    }
    my $elapsed = tv_interval($t0);

    return {
        elapsed        => $elapsed,
        retrieved_list => \@list,
        return_num     => int @list,
    };
}

sub save {
    my $self      = shift;
    my $save_file = shift;
    my $index     = $self->{index_data};
    nstore( $index, $save_file );
}

sub load {
    my $self      = shift;
    my $save_file = shift;
    my $index     = retrieve($save_file);
    $self->{index_data} = $index;
}

sub _unit_length {
    my $self = shift;
    my $vec  = shift;
    my $ret;
    my $norm = $self->_calc_norm($vec);
    while ( my ( $key, $value ) = each %$vec ) {
        $ret->{$key} = $value / $norm;
    }
    return $ret;
}

sub _calc_norm {
    my $self = shift;
    my $vec  = shift;

    my $norm;
    for ( values %$vec ) {
        $norm += $_**2;
    }
    sqrt($norm);
}

1;
__END__

=head1 NAME

Text::SimSearch - inverted index for similarity search 

=head1 SYNOPSIS

  use Text::SimSearch;

  my $indexer = Text::SimSearch->new;

  $indexer->add_item_from_file("source_file.tsv");
  $indexer->save("save.bin");

  $indexer->load("save.bin");

  my $query_vector = { BAG_OF_WORDS };
  my $number       = 100; # retrieve num
  my $result = $indexer->search( $query_vector, $number );


=head1 DESCRIPTION

Text::SimSearch is a on-memory inverted index for similarity search.


=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
