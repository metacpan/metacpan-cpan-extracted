package Text::CSV::UniqueColumns;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);


our $VERSION = '0.3';

my (%headerHash, @cleanup);

sub new {
    my ($class) = shift;
    my ($sFile) = shift || die "Please provide csv file as argument\n";
    my ($sCols) = shift;
    die "$sFile not found" if (!-e $sFile);

    my $self = {
        '_file' => $sFile,
        '_cols' => $sCols,
        '_headers' => ""
        };

    bless $self, $class;

    getHeaders($self,$sFile);
    die "Could not get headers\n" if (!$self->{'_headers'});

   return $self;
}

sub checkUniq {
    my ($self) = shift;
    my $sCols = shift || return "Provide cols as arguments\n";
    $self->{'_cols'} = $sCols;
    my $iCount = 1;
    my $sPasteOutput;
    my $sPasteFiles = " ";
    my @CompositeCols = split(',',$sCols);
    foreach my $sCol (@CompositeCols) {
        chomp($sCol);
        if ($headerHash{$sCol}) {
            $headerHash{"Composite$iCount"} = `cut -f$headerHash{$sCol} -d , $self->{'_file'}`;
            open (FILE , ">Composite$iCount") or return "Cannot write Composite$iCount $! \n";
            push (@cleanup, "Composite$iCount");
            print FILE $headerHash{"Composite$iCount"};
            $sPasteFiles .= " Composite$iCount";
            close(FILE);
            $iCount++;
        }
        else {
            return  "Column - $sCol not found\n INFO - Use \"-l\" option to list columns in file\n";
        }
    }
    my $sCmd = "paste  -d , $sPasteFiles > pasteOutput ";
    push (@cleanup, 'pasteOutput');
    $sPasteOutput = `$sCmd`;
    my $iCount1 =  `cat pasteOutput | sed s/' '//g | wc -l`;
    my $iCount2 =  `cat pasteOutput | sed s/' '//g | sort | uniq |  wc -l`;
    cleanUp();
    if ($iCount1 == $iCount2) {
       return "1"; #unique 
    }
    else {
       return "0";
    }
}

sub getColumnList {
    my ($self) = @_;
    foreach  (@{$self->{'_headers'}}) {
        return join(',', @{$self->{'_headers'}});
        print "$_\n";
    }
}


sub getUniqCols {
    my ($self) = @_;
    my ($sUniqCols) = " ";
    foreach my $iNo ( 0 .. (scalar(@{$self->{'_headers'}}) - 1)) {
        my $iField = $iNo + 1;
        my $sCmd = "cut -f$iField -d , $self->{'_file'} | sed s/' '//g | wc -l;";
        $sCmd .= "cut -f$iField -d ,  $self->{'_file'} | sed s/' '//g | sort | uniq | wc -l";
        my ($iCount1, $iCount2) = split("\n",`$sCmd`);

        if ( $iCount1 == $iCount2) {
            $sUniqCols .=  $self->{'_headers'}->[$iNo].",";
        }
        else {
            next;
        }
    }
    chop ($sUniqCols);
    return $sUniqCols;

}

sub buildHeaderHash {
    my ($self) = @_;
    my $iColNo = 1;
    foreach my $sCol (@{$self->{'_headers'}}) {
        $sCol =~ s/\s+//g;
        $sCol =~ s/\n//g;
        $headerHash{$sCol} = $iColNo;
        $iColNo++;
    }
}


sub getHeaders {
    my ($self,$sFile) = @_;
    print "file is $sFile \n";
    my @headers = split(',', `head -1 $sFile`);
    $self->{'_headers'} = \@headers;
    buildHeaderHash($self);
}

sub cleanUp {
    foreach my $sFile (@cleanup){
        `rm -f $sFile`;
    }
}


1;
         


__END__

=head1 NAME

Text::CSV::UniqueColumns - Perl extension for finding columns with unique values in a CSV 

=head1 SYNOPSIS

  use Text::CSV::UniqueColumns;
  
  --Create an object of the module
  $Obj = new UniqueColumns('check.csv');
  
  --To get list of columns
  $list = $Obj->getColumnList();
  
  --To check if column 'col1' has unique values.
  $Int = $Obj->checkUniq('col1');
  
  --To get a list of columns(comma seperated) having unique values.
  #Returns 1 if unique, 0 if not
  $Uniq = $Obj->getUniqCols();


=head1 DESCRIPTION

find columns with unique values of a CSV file.

Functions and their usage -- 

getColumnList - list all columns name in a csv 
checkUniq  - Check if one('Col1') or more combination of column('Col1,Col2,Col3') values are unique 
getUniqCols - give list of unique columns in an CSV.

**** Module works on UNIX boxes only ****


=head1 AUTHOR

Tushar, E<lt>tushar@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tushar Murudkar

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut



