package Tie::File::AnyData::MultiRecord_CSV;

use strict;
use warnings;
use Carp;

BEGIN{
  require Parse::CSV;
  require Tie::File::AnyData;
}

our $VERSION = '0.01';

sub TIEARRAY
  {
    my ($pack,$file,%opts) = @_;
    my $field_sep = $opts{'field_sep'} || "\t";
    my $key = $opts{'key'} || 0;
    my $recsep = $opts{'recsep'} || "\n";
    delete $opts{'field_sep'};
    delete $opts{'key'};

    my $coderef = sub {
      use Parse::CSV;
      my ($fh) = @_;
      return undef if (eof $fh);
      my $csv_parser = Parse::CSV->new (
				    handle => $fh,
				    sep_char => $field_sep
				   );
      my $arref = $csv_parser->fetch;
      my $rec = join ("$field_sep",@$arref).$recsep;
      my $rec_key = ${$arref}[$key];
      my $pos = tell($fh);
      while (my $arref = $csv_parser->fetch){
	if (${$arref}[$key] eq $rec_key){
	  $rec .= join "$field_sep",(@$arref);
	  $rec .= $recsep;
	  $pos = tell($fh);
	  return $rec if eof($fh);
	} else {
	  seek $fh,$pos,0;
	  return $rec;
	}
      }
    };

    carp "Overriding code ref" if (defined $opts{'code'});
    local $/="\n";
    Tie::File::AnyData::TIEARRAY (
				  'Tie::File::AnyData',
				  $file,
				  %opts,
				  code => $coderef
				 );
  }

1;

__END__

=head1 NAME

Tie::File::AnyData::MultiRecord_CSV - Accessing groups of CSV records in a file via a Perl array.

=head1 SYNOPSIS

    use Tie::File::AnyData::MultiRecord_CSV;

   ## Suppose a CSV file containing the following data:
   #  gene1 134123 541354 ini
   #  gene1 134125 614513 mid1
   #  gene1 164151 661451 mid2
   #  gene1 214315 233415 fin
   #  gene2 313415 614351 ini
   #  gene2 341513 341566 fin
   #  gene3 512341 665144 ini
   #  gene3 551645 667676 ini
   #  gene3 661445 777347 mid
   #  gene3 888513 918344 fin

    tie my @data_array, 'Tie::File::AnyData::MultiRecord_CSV', $datafile or die $!;
    print "$data_array[0]";
    # prints:
    #  gene1 134123 541354 ini
    #  gene1 134125 614513 mid1
    #  gene1 164151 661451 mid2
    #  gene1 214315 233415 fin

    untie @data_array;

    ## All the array operations are allowed:
    push @data_array, $rec; ## Append a CSV records at the end of the file
    unshift @data_array, $rec; ## Put CSV records at the beginning of the file
    my $rec = pop  @data_array; ## Remove the last group of CSV records of the file (assigned to $rec)
    my $rec = shift @data_array; ## Remove the first group of CSV records of the file (assigned to $rec)
    ... and so on.


=head1 DESCRIPTION

C<Tie::File::AnyData::MultiRecord_CSV> allows the management of groups of CSV records in a file via a Perl array
through C<Tie::File::AnyData>, so read the documentation of the latter module for further details on its internals.
For the management of CSV records it uses the C<Parse::CSV> module.

A group of CSV records is defined by some CSV lines that have a common key field. For example, if you have the following group of CSV lines in a file:

     aa1    bb1   cc1
     aa1    bb1   cc2
     aa1    bb2   cc3
     aa1    bb2   cc4
     aa2    bb3   cc5

Then, if you take key = 0 (first field), then, the fist record would be:
     aa1    bb1   cc1
     aa1    bb1   cc2
     aa1    bb2   cc3
     aa1    bb2   cc4

With key = 1 (seconf field), the first record would be:
     aa1    bb1   cc1
     aa1    bb1   cc2

Finally, with key = 2 (third field), then, the first record would be:
     aa1    bb1   cc1


=head1 PARAMETERS

This module accepts the same parameters as C<Tie::File> plus:

=over

=item field_sep : The character used to separate fields in the input file (defaults to "\t").

=item key : A number indicating the field that defines a group of CSV lines (defaults to "0").

=back


=head1 AUTHOR

  Miguel Pignatelli

  Please send any comment to: motif@pause.org

  The most recent version of this module, should be available at CPAN.


=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-file-anydata-multirecord_csv at rt.cpan.org>, or through the web interface at
L<http://rp.cpan.org/NoAuth/ReportingBug.html?Queue=Tie-File-AnyData-MultiRecord_CSV>.

You can find documentation for this module with the perldoc command:

     perldoc Tie::File::AnyData::MultiRecord_CSV


=head1 LICENSE

Copyright 2007 Miguel Pignatelli, all rights reserved.

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.


=head1 WARRANTY

This module comes with ABSOLUTELY NO WARRANTY.

=cut
