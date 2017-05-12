#
# PERL Modul
# Access to Stadaf-files
#
# Copyright (C) 1999 Dirk Tostmann (tostmann@tiss.com)
#
# $rcs = ' $Id: STADAF.pm,v 1.1 1999/02/22 09:01:19 root Exp $ ' ;	
#
#####################################################################################################
package STADAF;
#####################################################################################################

use 5.004;
use strict;
use XBase::Base 0.120;		# will give us general methods
use Time::ParseDate;
use Time::CTime;

## ##############
# General things

use vars qw( $VERSION $errstr $CLEARNULLS @ISA );

@ISA = qw( XBase::Base );
$VERSION = '0.01';
$CLEARNULLS = 1;		# Cut off white spaces from ends of char fields

*errstr = \$XBase::Base::errstr;

###########################################
# Open, read_header, close
#
# Open the specified file or try to append the .daf suffix.
sub open{
  my ($self) = shift;
  my %options;
  if (scalar(@_) % 2) { $options{'name'} = shift; }	
  $self->{'openoptions'} = { %options, @_ };
  
  my %locoptions;
  @locoptions{ qw( name readonly) } = @{$self->{'openoptions'}}{ qw( name readonly) };
  my $filename = $locoptions{'name'};
  if ($filename eq '-') { 
    return $self->SUPER::open(%locoptions); 
  }
  for my $ext ('', '.daf', '.DAF') {
    if (-f $filename.$ext) {
      $locoptions{'name'} = $filename.$ext;
      $self->NullError();
      return $self->SUPER::open(%locoptions);
    }
  }
  $locoptions{'name'} = $filename;	
  return $self->SUPER::open(%locoptions); # for nice error message
}

# We have to provide way to fill up the object upon open
sub read_header	{
  my $self = shift;
  my $fh = $self->{'fh'};
  
  @{$self}{ qw( field_names field_types field_length rec_idx DATA name_hash) } = ([],[],[],[],[],{});
  
  my $header;			# read the header
  $self->read($header, 105) == 105 or do { $self->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
  
  @{$self}{ qw( magic version create_dt sender code_of_sender program serial full_update var_char file_len charset num_rec num_fields) }
  = unpack 'A6A4A12A20A5A20A4AAA12A8A8A4', $header; # parse the data
  
  my $char = $self->{'var_char'};
  $self->{'constants'} = {
			  'C'     => $char.'RlBookingClass'.$char,
			  'NETTO' => $char.'TkNetFareCode'.$char,
			  'ARI'   => $char.'FaArrivalCode'.$char,
			 };
  
  my $fields = $self->num_fields;
  my ($type,$len,$name);
  
  $self->read($header, $fields*37) == ($fields*37) or do { $self->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
  
  while ($header) {
    ($type,$len,$name) = unpack 'AA5A30', $header;
    unless ($type =~ /^F|S|D$/ && $len =~ /^\d+$/) {
      $self->Error("Error reading header of $self->{'filename'}: $!\n"); 
      return;
    }
    push @{$self->{'field_names'}},  $name;
    push @{$self->{'field_types'}},  $type;
    push @{$self->{'field_length'}}, $len+0;
    $self->{'name_hash'}->{$name} = @{$self->{'field_names'}} - 1;
    
    $header =~ s/^[^\r]+\r//;
  }
  
  $self->read($header, 8) == 8 or do { $self->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
  
  @{$self}{ qw( num_const) }
  = unpack 'A8', $header;	# parse the data
  
  my $consts = $self->num_consts;
  
  if ($consts) {
    $self->read($header, $consts*41) == ($consts*41) or do { $self->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
    while ($header) {
      ($name) = unpack 'A40', $header;
      $name =~ s/\s+$//;
      
      if ($name =~ /^$char([^$char]+)$char=(.+)$/) {
        $self->{'constants'}->{$1} = $2;
      }
      
      $header =~ s/^[^\r]+\r//;
    }
    
  } 
  
  $self->read($header, 6) == 6 or do { $self->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
  
  @{$self}{ qw( separator memo_len) }
  = unpack 'AA5', $header;	# parse the data
  
  my $memo_len = $self->memo_len;
  
  if ($memo_len) {
    $self->read($header, $memo_len) == $memo_len or do { $self->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
    $self->{'memo_text'} = $header;
  } 
  
  
  $self->read($header, 2) == 2 or do { $self->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
  
  $self->{'data_start'} = $self->tell;
  $self->{rec_idx}->[0] = $self->{'data_start'};
  $self->gotop;
  
  return $header eq "\r\n";
}

# got to the TOP of data, first record
sub gotop {
  my $self = shift;
  $self->{'position'}      = $self->{'data_start'};
  $self->{'record_number'} = 0;
  $self->seek_to_seek( $self->{'position'});
}

sub seek2rec {
  my $self = shift;
  my $rec  = shift;

  return if ($rec<0);
  return unless $self->{rec_idx}->[$rec];

  $self->{'position'}      = $self->{rec_idx}->[$rec];
  $self->{'record_number'} = $rec;
  $self->seek_to_seek( $self->{'position'});
}

sub EOF {
  my $self = shift;
  return ($self->{'record_number'}<$self->{num_rec}) ? 0 : 1;
}

# Close the file
sub close {
  my $self = shift;
  $self->SUPER::close();
}

################
# Little decoding
sub version		{ sprintf "%1.2f", shift->{'version'}; }
sub num_rec		{ sprintf "%d", shift->{'num_rec'}; }
sub last_record		{ sprintf "%d", shift->{'num_rec'}-1; }
sub num_fields		{ sprintf "%d", shift->{'num_fields'}; }
sub num_consts		{ sprintf "%d", shift->{'num_consts'} || 0; }
sub memo_len		{ sprintf "%d", shift->{'memo_len'} || 0; }
sub file_len		{ sprintf "%d", shift->{'file_len'}; }
sub create_dt		{ 
  my $date = shift->{'create_dt'};
  $date =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})$/$2\/$3\/$1 $4:$5/;
  parsedate($date); 
}

# List of field names, types, lengths and decimals
sub field_names		{ @{shift->{'field_names'}}; }
sub field_types		{ @{shift->{'field_types'}}; }
sub field_lengths	{ @{shift->{'field_length'}}; }


###############################
# Header, field and record info

# Returns (not prints!) the info about the header of the object
*header_info = \&get_header_info;

sub get_header_info {
  my $self   = shift;
  my $result = '';
  $result .= "Filename      : $self->{'filename'}\n";
  $result .= "Magic         : $self->{'magic'}\n";
  $result .= "Version       : ".$self->version."\n";
  $result .= "Created       : ".strftime('%c', $self->create_dt)."\n";
  $result .= "Num of records: ".$self->num_rec."\n";
  $result .= "Num of fields : ".$self->num_fields."\n";
  $result .= "Num of consts : ".$self->num_consts."\n";
  $result .= "File len      : ".$self->file_len."\n";
  $result .= "CharSet       : $self->{'charset'}\n";
  $result .= "Routing sep.  : $self->{'separator'}\n";
  $result .= "Full Update   : ";
  $result .= $self->{'full_update'} ? "Yes\n" : "No\n";
  $result .= "Vari-Char     : $self->{'var_char'}\n";
  $result .= "Data starts at: ".sprintf("%08X (hex)\n", $self->{'data_start'});
  $result .= "Sender   Name : $self->{'sender'}\n";
  $result .= "         Code : $self->{'code_of_sender'}\n";
  $result .= "      Program : $self->{'program'}\n";
  $result .= "         Info : ";
  $result .= $self->{'memo_text'} ? "\n$self->{'memo_text'}" : "not defined\n";
  $result .= "\nFields        :\nNum	Name                           Type    Len\n";

  return join '', $result, map { $self->get_field_info($_) } (0 .. $self->num_fields-1);

}


# Return info about field in daf file
sub get_field_info {
  my ($self, $num) = @_;
  sprintf "%d.\t%-31.31s%-8.8s%-8.8s\n", $num + 1,
  map { $self->{$_}[$num] }
  qw( field_names field_types field_length );
}

sub read_type_F {
  my $self = shift;
  my $len  = shift;
  my $buffer = '';

  $self->read($buffer, $len) == $len or do { $self->Error("Error reading Fix type: $!\n"); return; };

  $buffer;
}

sub read_type_D {
  my $self = shift;
  my $len  = shift;
  my $buffer = '';

  $self->read($buffer, $len) == $len or do { $self->Error("Error reading length of dynamic type: $!\n"); return; };
  $len = sprintf '%d', $buffer;

  $self->read($buffer, $len) == $len or do { $self->Error("Error reading data of dynamic type: $!\n"); return; };

  $buffer;
}

sub read_type_S {
  my $self = shift;
  my $buffer = '';
  
  $self->read($buffer, 16) == 16 or do { $self->Error("Error reading header of stuctured type: $!\n"); return; };
  my ($len,$num_f,$len_f) = unpack 'A6A5A5', $buffer;
  unless ($len == ($num_f*$len_f)) { 
    $self->Error("Internal checksum error of stuctured type: $!\n"); 
    return; 
  }
  
  $self->read($buffer, $len) == $len or do { $self->Error("Error reading data of structured type: $!\n"); return; };
  
  my @array = ();
  foreach (0..$num_f-1) {
    push @array, substr($buffer,$_*$len_f,$len_f);  
  }
  
  \@array;
}

sub read_record {
  my $self = shift;
  $self->NullError();
  my ($hash,$i,$type) = ({});
  
  foreach $i (0 .. $self->num_fields-1) {
    $type = 'read_type_'.$self->{'field_types'}->[$i];
    unless ($self->can($type)) {
      $self->Error("Undefined field type: $!\n"); 
      return; 
    }
    $hash->{$self->{'field_names'}->[$i]} = $self->$type($self->{'field_length'}->[$i]);
    $hash->{$self->{'field_names'}->[$i]} =~ s/\s+$//;
    $hash->{$self->{'field_names'}->[$i]} =~ s/\r/\n/g;
    return if $self->errstr;
  }
  
  $self->read($i, 1) == 1 or do { $self->Error("Error reading record border char: $!\n"); return; };
  return unless ($i eq "\r");

  $self->substitute_hash($hash,$self->{'record_number'});
  $self->{rec_idx}->[++$self->{'record_number'}] = $self->tell;
  
  $hash;
}

sub substitute_hash {
  my $self = shift;
  my $hash = shift;
  my $rec  = shift;
  my $char = $self->{'var_char'} || return $hash;
  my ($key,$i,$pattern);
  
  foreach $i (0..@{$self->{'field_names'}}-1) {
    $key = $self->{'field_names'}->[$i];
    while ($hash->{$key} =~ /$char([^\s\r\n$char]+)$char/) {
      $pattern = $1;
      if ($pattern =~ /^Gp/ || $pattern =~ /^C|NETTO|ARI$/) {
	$hash->{$key} =~ s/$char([^\s\r\n$char]+)$char/$self->{'constants'}->{$pattern}/g;
      } else {
	$hash->{$key} =~ s/$char([^\s\r\n$char]+)$char/$hash->{$pattern}/g;
      }
    }
    
    unless ($self->{NOCACHE}) {
      $self->{DATA}->[$rec] = [] unless $self->{DATA}->[$rec];
      $self->{DATA}->[$rec]->[$i] = $hash->{$key};
    }
  }
  
  $hash;
}


sub fetch_all {
  my $self = shift;
  $self->gotop;
  $self->{DATA} = [];
  while (!$self->EOF) {
    $self->read_record || return;
    print "$self->{'record_number'}\n" unless ($self->{'record_number'} % 50);
  }
  1;
}

sub get_record {
  my $self = shift;
  my $rec  = shift;

  my $hash = {};

  my ($key,$i);
  
  foreach $i (0..@{$self->{'field_names'}}-1) {
    $key = $self->{'field_names'}->[$i];
    $hash->{$key} = $self->{DATA}->[$rec]->[$i];
  }

  $hash;
}


1;











