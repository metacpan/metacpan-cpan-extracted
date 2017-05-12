package Text::Bayon;
use strict;
use warnings;
use File::Temp qw(tempdir tempfile);
use Carp;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(bayon_path dry_run io_files);

our $VERSION = '0.00002';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( {@_} );
}

sub clustering {
    my $self          = shift;
    my $input         = shift;
    my $args_options  = shift;
    my $args_outfiles = shift;

    my $cmd = $self->_generate_command( 'clustering', $input, $args_options,
        $args_outfiles );
    return $cmd if $self->dry_run;
    system($cmd);
    if ( !$args_outfiles or $args_outfiles->{return_force} ) {
        my @ret = $self->_build_return_data( $self->io_files, $cmd );
        if (wantarray) {
            return @ret;
        }
        else {
            return $ret[0];
        }
    }
}

sub classify {
    my $self          = shift;
    my $input         = shift;
    my $args_options  = shift;
    my $args_outfiles = shift;

    my $cmd = $self->_generate_command( 'classify', $input, $args_options,
        $args_outfiles );
    return $cmd if $self->dry_run;
    system($cmd);
    if ( !$args_outfiles or $args_outfiles->{return_force} ) {
        my @ret = $self->_build_return_data( $self->io_files, $cmd );
        if (wantarray) {
            return @ret;
        }
        else {
            return $ret[0];
        }
    }
}

sub _generate_command {
    my $self          = shift;
    my $method_name   = shift;
    my $input         = shift;
    my $args_options  = shift;
    my $args_outfiles = shift;

    my $bayon_path = $self->bayon_path || 'bayon';
    my $io_files = $self->_io_file_names( $input, $args_outfiles );
    $self->io_files($io_files);
    my $options = $self->_option( $method_name, $args_options, $io_files );

    my $cmd;
    my $infile  = $io_files->{input};
    my $outfile = $io_files->{output};
    $cmd = "$bayon_path $infile $options > $outfile";
    return $cmd;
}

sub _io_file_names {
    my $self          = shift;
    my $input         = shift;
    my $args_outfiles = shift;

    my %io_files;

    if ( ref $input eq 'HASH' ) {
		my $dir            = tempdir(CLEANUP => 1);
        my ( $fh, $fname ) = tempfile(DIR => $dir);
        while ( my ( $key, $val ) = each %$input ) {
            print $fh $key, "\t";
            print $fh join( "\t", (%$val) ), "\n";
        }
        close($fh);
        $io_files{input} = $fname;
    }
    elsif ( ref $input eq 'GLOB' ) {
		my $dir            = tempdir(CLEANUP => 1);
        my ( $fh, $fname ) = tempfile(DIR => $dir);
        while ( my $rec = <$input> ) {
            print $fh $rec;
        }
        close($fh);
        $io_files{input} = $fname;
    }
    elsif ( $input and ref $input eq '' ) {
        croak("can't find input file $input") unless -e $input;
        $io_files{input} = $input;
    }
    else {
        croak("wrong input");
    }

    for (qw( output clvector )) {
        if ( $args_outfiles and $args_outfiles->{$_} ) {
            $io_files{$_} = $args_outfiles->{$_};
        }
        else {
			my $dir            = tempdir(CLEANUP => 1);
			my ( $fh, $fname ) = tempfile(DIR => $dir);
            close($fh);
            $io_files{$_} = $fname;
        }
    }
    return \%io_files;
}

sub _build_return_data {
    my $self     = shift;
    my $io_files = shift;
    my $cmd      = shift;

    my @ret;
    for (qw(output clvector)) {
        my $data;
        open( FILE, "<", $io_files->{$_} );
        while ( my $line = <FILE> ) {
            chomp $line;
            my @f = split( "\t", $line );
            my $label = shift @f;
            if ( $cmd =~ / -p / || $cmd =~ /--classify/ ) {
                my @array;
                while ( @f > 0 ) {
                    my $key = shift @f;
                    my $val = shift @f;
                    push @array, { $key => $val };
                }
                $data->{$label} = \@array;
            }
            else {
                $data->{$label} = \@f;
            }
        }
        close(FILE);
        push @ret, $data;
    }
    return @ret;
}

sub _option {
    my $self         = shift;
    my $method_name  = shift;
    my $args_options = shift;
    my $io_files     = shift;

    my $option;

    if ( $method_name eq 'clustering' ) {
        my $number 
            = $args_options->{number}
            || $args_options->{num}
            || $args_options->{n};
        my $limit 
            = $args_options->{limit}
            || $args_options->{lim}
            || $args_options->{l};
        my $point         = $args_options->{point} || $args_options->{p};
        my $clvector      = $args_options->{clvector};
        my $clvector_size = $args_options->{clvector_size};
        my $method        = $args_options->{method};
        my $seed          = $args_options->{seed};
        my $idf           = $args_options->{idf};

        if ( !$number && !$limit ) {
            $limit = 1.5;
        }
        if ($number) {
            $option .= '-n ' . $number . ' ';
        }
        else {
            if ($limit) {
                $option .= '-l ' . $limit . ' ';
            }
        }
        if ($point) {
            $option .= '-p ';
        }
        if ($clvector) {
            $option .= '-c ' . $io_files->{clvector} . ' ';
            if ($clvector_size) {
                $option .= '--clvector-size=' . $clvector_size . ' ';
            }
        }
        if ($method) {
            $option .= '--method=' . $method . ' ';
        }
        if ($seed) {
            $option .= '--seed=' . $seed . ' ';
        }
        if ($idf) {
            $option .= '--idf ';
        }
    }
    elsif ( $method_name eq 'classify' ) {
        my $classify      = $args_options->{'classify'};
        my $inv_keys      = $args_options->{'inv-keys'} || 20;
        my $inv_size      = $args_options->{'inv-size'} || 100;
        my $classify_size = $args_options->{'classify-size'} || 20;
        $option
            .= '--classify='
            . $classify
            . ' --inv-keys='
            . $inv_keys
            . ' --inv-size='
            . $inv_size
            . ' --classify-size='
            . $classify_size;
    }
    else {
        croak("wrong method name");
    }
    $option =~ s/ $//;
    return $option;
}

1;
__END__

=head1 NAME

Text::Bayon - Handling module for the clustering tool 'Bayon'

=head1 SYNOPSIS

  use Text::Bayon;
  use Data::Dumper;

  my $bayon = Text::Bayon->new;
  
  my $input_data = {
  	document_id1 => { 
  		key1_1 => "value1_1",
  		key1_2 => "value1_2",
  		key1_3 => "value1_3",
  	},
  	document_id2 => { 
  		key2_1 => "value2_1",
  		key2_2 => "value2_2",
  		key2_3 => "value2_3",
  	},
  		.
  		.
  		.
  };

  my $output = $bayon->clustering($input_data);
  
  print Dumper $output;

  #$output is ... 
  #{
  #  cluster1 => [ document_id, $document_id], 
  #  cluster2 => [ document_id, $document_id], 
  #  cluster2 => [ document_id, $document_id, $document_id], 
  #		.
  #		.
  #		.
  #} 

  #-----------
  # give 'point' option, you can get the data below format.
  #

  my $options = { point => 1 };
  my $output = $bayon->clustering( $input_data, $options );

  print Dumper $output;

  #$output is ... 
  #{
  #  cluster1 => [ { document_id => score}, {$document_id => score} ], 
  #  cluster2 => [ { document_id => score}, {$document_id => score} ], 
  #  cluster2 => [ { document_id => score}, { document_id => score } , 
  #		{ document_id => score }, { document_id => score } ], 
  #		.
  #		.
  #		.
  #} 
  
  #-----------
  # set 'clvector' option true, you can get clvector data, too. 
  #

  my $options = { clvector => 1 };
  my ( $output, $clvector ) = $bayon->clustering( $input_data, $options );

  #-----------
  # if you set outfiles as 3rd argument, it restricts returning data and out to files.
  #

  my $options = { clvector => 1 };
  my $outfiles = {
    output   => 'output.tsv',
    clvector => 'centroid.tsv',
  };

  $bayon->clustering( $input_data, $options, $outfiles );


=head1 DESCRIPTION

Text::Bayon is handling module for the clustering tool 'Bayon'.

Bayon is a simple and fast hard-clustering tool.

Bayon supports Repeated Bisection clustering and K-means clustering. 


I think Bayon is an excellent software for Data-Mining-Peoples!

If you want to know and install Bayon, see the Bayon's maual. ( http://code.google.com/p/bayon/ )

=head1 METHODS

=head2 new(%conf)

  %conf = (
      bayon_path => '/usr/local/bin/bayon', # optional
      dry_run    => 1, # optional
  );

=head2 clustering( $input, $options, $outfiles )

  $input = I< hashref | filename | filehandle >; # required

  $options = {
      number        => I<num>,           # optional
      limit         => I<num>,           # optional, default 1.5 
      point         => 1,                # optional
      clvector      => I< 1 | 0 >,       # optional
      clvector_size => I<num>,           # optional
      method        => I< rb | kmeans >, # optional, default 'rb'
      seed          => num ,             # optional
  };

  $outfiles = {
      output   => I< filename >, # optional
      clvector => I< filename >, # optional
  }

=head2 classify($args)

  $input = I< hashref | filename | filehandle >; # required

  $options = {
      classify      => I< filename >, # required
      inv_keys      => I< num >,      # optional, default 20
      inv_size      => I< num >,      # optional, default 100
      classify_size => I< num >,      # optional, default 20
  };

  $outfiles = {
      output   => I< filename >, # optional
  }

=head1 AUTHOR

Takeshi Miki E<lt>t.miki@nttr.co.jpE<gt>

( Bayon's AUTHOR is Mizuki Fujisawa E<lt>fujisawa@bayon.ccE<gt> )

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://code.google.com/p/bayon/>

=cut
