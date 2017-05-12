package Text::CSV::Field;
use strict;

BEGIN {
    $Text::CSV::Field::VERSION = '1.01';
}


sub new {
  my ($class,$file,$sep)  = @_;

  open(FILE,$file) or die "can't open $file $!"; 
  defined($sep) or die "Missing field separator parameter\n"; 
  $sep or die "Empty field separator parameter\n"; 

  my $self = {_filename=>$file,_sep=>$sep};
  my @data = ();
  # open file
  while(<FILE>)  {
    chomp;
    push(@data,$_);
  }
  $self->{_data} = \@data;
  # check sep

  bless($self,$class);
  return $self;
}

sub check_file	{
  my ($self) = shift;
  my $num_fields = 0;
  my $err_string  = undef;
  my @data = @{$self->{_data}};
  if (!@data)  {
     $err_string .= "File is empty\n"; 
     print "$err_string\n";
     exit();
  }
  if (@data == 1)  {
     $err_string .= "no data found\n"; 
     print "$err_string\n";
     exit();
  }
  for(my $i=0;  $i < @data; $i++)  {
    my $temp = 0;
    my @temp_arr  = split($self->{_sep},${$self->{_data}}[$i]);
    $temp = @temp_arr;
    if ($i == 0)  {
      $num_fields = $temp;
    }
    else  {
      if ($num_fields != $temp)  {
        $err_string .= "Field number mismatch line# " . ($i+1) . " in " . $self->{_filename} . "\n"; 
      }
    }
  }
  if ($err_string)  {
    print "$err_string\n";
    exit();
  }
}

sub setdatafields{
  my ($self) = shift;
  $self->check_file();

  $self->{_total_number} = @{$self->{_data}};

  my @fieldnames = ();
  for(my $j = 0; $j < @{$self->{_data}}; $j++)  {
    my @recs  = split(/$self->{_sep}/,${$self->{_data}}[$j]);
    for(my $k = 0; $k < @recs; $k++)  {
      if ($j == 0)  {
        push(@fieldnames,$recs[$k]);
        $self->{$recs[$k]} = [];
        #push(@{$self->{$fieldnames[$k]}},$recs[$k]);
      }
      else  {
         push(@{$self->{$fieldnames[$k]}},$recs[$k]);
      }
    }
  }
}

sub getfield{
  my $self = shift;
  my $field = shift;
  $field or die "Missing field input\n";
  $self->setdatafields;
  $field =~ tr/a-z/A-Z/;
  return @{$self->{$field}};
}

1;
__END__
=pod

=head1 NAME

Text::CSV::Field - Get data from Text CSV file using header field.

=head1 VERSION

    1.01

=head1 SYNOPSIS

	my $obj = Text::CSV::Field->new('filename','field_sep');
	my @data = $obj->getfield('field_name');

=head1 DESCRIPTION

Using this module you can parse a simple text csv file with header field.

=head1 METHODS

=head2 new

	my $obj = Text::CSV::Field->new('filename','field_sep');

Construct a new parser. This takes two parameters csv filename and field seperator.
Both parameters are mandatory.

=head2 getfield 

	my @data = $obj->getfield('fieldname');

Returns  a list of data.

=head1 AUTHOR

Praveen Kumar

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Text-CSV-Field@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2010 Praveen Kumar.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

