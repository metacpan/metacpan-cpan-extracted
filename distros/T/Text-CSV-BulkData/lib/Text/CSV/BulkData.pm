package Text::CSV::BulkData;

use strict;
use vars qw($VERSION);
our $VERSION = '0.06';

use Carp;

sub new { 
    my ($class, $output_file, $format) = @_;
    bless { 
        output_file   => $output_file,
        format        => $format,
        residue_loop  => 1,
    }, $class;
} 

sub set_residue_loop_off {
    my ($self, $output_file) = @_;
    $self->{residue_loop} = 0;
    return $self;
}

sub set_output_file {
    my ($self, $output_file) = @_;
    $self->{output_file} = $output_file;
    return $self;
}

sub set_format {
    my ($self, $format) = @_;
    $self->{format} = $format;
    return $self;
}

sub set_pattern {
    my $self = shift;
    $self->{pattern} = shift;
    return $self;
}

sub set_start {
    my ($self, $start) = @_;
    $self->{start} = $start;
    return $self;
}

sub set_end {
    my ($self, $end) = @_;
    $self->{end} = $end;
    return $self;
}

sub initialize {
    my $self = shift;
    my $output_file = $self->{output_file};
    unlink $output_file or croak $! if -f $output_file;
    return $self;
}

sub make {
    my $self = shift;
    my ($output_file, $start, $end, $format, $pattern ) = 
        ( $self->{output_file}, $self->{start}, $self->{end}, $self->{format}, $self->{pattern} );
    my $debug_ary_ref;

    open FH, ">> $output_file" or croak $!;
    for (my $i = $start; $i <= $end; $i++){
        my @input = ();
        for (my $j = 0; $j < ($format =~ s/%/%/g); $j++) {
            my $pattern = $$pattern[$j];
            if ( ! defined $pattern ) { 
                push @input, $i;
                next;
            } elsif ( $pattern !~ m/^[%\/\*\+-]/ ) {
                push @input, $pattern;
                next;
            }
            push @input, $self->_calculate($pattern, $i, 0);
        }
        $self->{debug} 
            ? push @$debug_ary_ref, sprintf $format, @input 
            : printf FH $format, @input;
    }
    close FH;
   
    $self->{debug} 
        ? return $debug_ary_ref 
        : return $self;
}

sub _calculate {
    my ($self, $pattern, $i, $flag) = @_;
    if ( ! $flag && $self->_is_recursive_start($pattern) ) {
        $pattern =~ m{^(\d+)[^0-9]};
        $self->{pattern} = $pattern;
        $self->{before} = $1;
        $pattern =~ s{^\d+([^0-9])}{$1};
        return $self->_calculate($pattern, $i, 1); 
    }

    if ( $pattern =~ m{\*(\d+)} ) {
        if ( $flag eq 1) {
            my $res = $self->{before} * $1;
            $res = $self->_recursive_calc($res);
            $pattern = $self->_return_substituted('^\d+\*\d+', $res);
        } else { 
            my $res = $i * $1;
            $pattern =~ s{\*\d+}{$res};
        }
        $self->_calculate($pattern, $i, 0);
    } elsif ( $pattern =~ m{/(\d+)} ) {
        if ( $flag eq 1) {
            my $res = int($self->{before} / $1);
            $res = $self->_recursive_calc($res);
            $pattern = $self->_return_substituted('^\d+/\d+', $res);
        } else { 
            my $res = int($i / $1);
            $pattern =~ s{/\d+}{$res};
        }
        $self->_calculate($pattern, $i, 0);
    } elsif ( $pattern =~ m{%(\d+)} ) {
        $self->{residue_loop} = $1 if $self->{residue_loop};
        if ( $flag eq 1) {
            my $res = $self->{before} % $1;
            $res = $self->_recursive_calc($res);
            $pattern = $self->_return_substituted('^\d+%\d+', $res);
        } else { 
            my $res = $i % $1;
            $pattern =~ s{%\d+}{$res};
        }
        $self->_calculate($pattern, $i, 0);
    } elsif ( $pattern =~ m{\+(\d+)} ) {
        if ( $flag eq 1) {
            my $res = $self->{before} + $1;
            $res = $self->_recursive_calc($res);
            $pattern = $self->_return_substituted('^\d+\+\d+', $res);
        } else { 
            my $res = $i + $1;
            $pattern =~ s{\+\d+}{$res};
        }
        $self->_calculate($pattern, $i, 0);
    } elsif ( $pattern =~ m{-(\d+)} ) {
        if ( $flag eq 1) {
            my $res = $self->{before} - $1;
            $res = $self->_recursive_calc($res);
            $pattern = $self->_return_substituted('^\d+-\d+', $res);
        } else { 
            my $res = $i - $1;
            $pattern =~ s{-\d+}{$res};
        }
        $self->_calculate($pattern, $i, 0);
    } else {
        delete $self->{pattern}, $self->{before};
        $self->{residue_loop} = 1;
        return $pattern;
    }
}

sub _recursive_calc {
    my ($self, $res) = @_;
    if ( defined $self->{residue_loop} 
         && $self->{residue_loop} > 1
         && ($res < 0 || $res > $self->{residue_loop})
       ) {
        $res += $self->{residue_loop};
    }
    return $res;
}

sub _return_substituted {
    my ($self, $regexp, $res) = @_;
    $self->{pattern} =~ s{$regexp}{$res};
    return $self->{pattern};
}

sub _is_recursive_start {
    my $self = shift;
    my $pattern = shift;
    ( $pattern =~ /^\d+/ && $pattern !~ /^\d+$/ ) ? return 1 : return 0;
}

sub _set_debug {
    my $self = shift;
    $self->{debug} = 1;
    return $self;
}

1;
__END__

=head1 NAME

Text::CSV::BulkData - generate csv file with bulk data

=head1 SYNOPSIS

  use Text::CSV::BulkData;

  my $output_file_1 = "/your/dir/example.dat";
  my $format_1 = "0907000%04d,JPN,160-%04d,type000%04d,0120444%04d,2008041810%02d00,2008041811%02d00\n";
  my $pattern_1 = [undef,'*2*2','-2','*2+1','%60-1','%60-40'];

  my $gen = Text::CSV::BulkData->new($output_file_1, $format);

  my $pattern_1 = [undef,'*2','-2','*2+1'];
  $gen->initialize
      ->set_pattern($pattern_1)
      ->set_start(59)
      ->set_end(62)
      ->make;

  my $output_file_2 = "/your/dir/yetanotherfile.dat";
  my $format_2  = "0907000%04d,JPN,160-%04d,type000%04d,0120444%04d,20080418%02d0000,20080419%02d0000\n";
  my $pattern_2 = [undef,'/10','*3/2','%2', '%24-1','23'];

  $gen->set_output_file($output_file_2)
      ->set_format($format_2)
      ->set_pattern($pattern_2)
      ->set_start(239)
      ->set_end(241)
      ->make;

This sample generates following csv file.

/your/dir/example.dat

  09070000059,JPN,160-0236,type0000057,01204440119,20080418105800,20080418111900
  09070000060,JPN,160-0240,type0000058,01204440121,20080418105900,20080418112000
  09070000061,JPN,160-0244,type0000059,01204440123,20080418100000,20080418112100
  09070000062,JPN,160-0248,type0000060,01204440125,20080418100100,20080418112200

/your/dir/yetanotherfile.dat

  09070000239,JPN,160-0023,type0000358,01204440001,20080418220000,20080419230000
  09070000240,JPN,160-0024,type0000360,01204440000,20080418230000,20080419230000
  09070000241,JPN,160-0024,type0000361,01204440001,20080418000000,20080419230000

=head1 DESCRIPTION

Text::CSV::BulkData is a Perl module which generates csv files with bulk data.

You can modify incremented values with using addition(+), subtraction(-), multiplication(*), division(/) and residue(%). 

Precedence of operators is '*', '/', '%', '+', '-'. 

The right of the decimal point are truncated.

Beginning with no operators means fixed value(integer or string).

=head1 SEE ALSO

None

=head1 AUTHOR

Kazuhiro Sera, E<lt>webmaster@seratch.ath.cxE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kazuhiro Sera

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
