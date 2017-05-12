package Tie::File::AnyData::Bio::Fasta;

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

BEGIN{
  require Tie::File::AnyData;
}

sub TIEARRAY
  {
    my ($pack,$file,%opts) = @_;

    ## option recsep is not allowed
    for my $key (keys %opts) {
      if ($key =~ /\-?recsep/){
	carp "Option recsep is not accepted by IO::Tie::File::AnyData\nThis will be overrided\n";
	delete $opts{$key};
      }
    }

    my $coderef = sub {
      my ($fh) = @_;
      return undef if eof $fh;
      local $/ = "\n>";
      my $faseq = <$fh>;
      if (eof $fh) {
	local $/ = "\n";
	chomp $faseq;
      } else {
	chomp $faseq;
      }
      $faseq = ">$faseq" if $faseq !~ /^>/;
      return "$faseq\n";
    };

    carp "Overriding code ref" if (defined $opts{'code'});
    local $/="\n";
    Tie::File::AnyData::TIEARRAY("Tie::File::AnyData",$file,%opts, code => $coderef);
  }

1;

__END__

=head1 NAME

  Tie::File::AnyData::Bio::Fasta - Accessing fasta records in a file via a Perl array.

=head1 SYNOPSIS

    use Tie::File::AnyData::Bio::Fasta;

    ## Process the fasta records in a file 1 by 1:
    my $fastafile = "seqs.fa"; ## File containing some fasta sequences
    tie my @fa_array, 'Tie::File::AnyData::Bio::Fasta', $fastafile or die $!;
    for my $fa_rec (@fa_array){
       ## Process the record
    }
    untie @fa_array;

    ## Take randomly 10 fasta sequences from a file and put them in another one:
    use Fcntl qw/O_RDONLY O_RDWR O_CREAT/;
    use List::Util qw/shuffle/;
    tie my @in,  'Tie::File::AnyData::Bio::Fasta', $in_fasta, mode => O_RDONLY or die $!;
    tie my @out, 'Tie::File::AnyData::Bio::Fasta', $out_fasta, mode => O_RDWR | O_CREAT or die $!;
    @out = (shuffle @in)[0..10];
    untie @in;
    untie @out;

    ## All the array operations are allowed:
    push @fa_array, $fasta_rec; ## Append a fasta record at the end of the file
    unshift @fa_array, $fasta_red; ## Put a fasta record at the beginning of the file
    my $fasta_rec = pop  @fa_array; ## Remove the last record of the file (assigned to $fasta_rec)
    my $fasta_rec = shift @fa_array; ## Remove the first record of the file (assigned to $fasta_rec)

=head1 DESCRIPTION

  C<Tie::File::AnyData::Bio::Fasta> allows the management of fasta files via a Perl array
  through C<Tie::File::AnyData>, so read the documentation of this module for further details on its internals.


=head1 PARAMETERS

  This module accepts the same parameters as C<Tie::File> except C<recsep>,
  that is always assigned to C<\r\n> if it is run on a Windows machine or C<\n> otherwise.

=head1 AUTHOR

  Miguel Pignatelli

  Please send any comment to: motif@pause.org

  The most recent version of this module, should be available at CPAN.

=head1 BUGS

  Please report any bugs or feature requests to
  C<bug-tie-file-anydata at rt.cpan.org>, or through the web interface at
  L<http://rp.cpan.org/NoAuth/ReportingBug.html?Queue=Tie-File-AnyData>.

You can find documentation for this module with the perldoc command:

     perldoc Tie::File::AnyData

=head1 LICENSE

  Copyright 2007 Miguel Pignatelli, all rights reserved.

  This library is free software; you may redistribute it and/or modify it
  under the same terms as Perl itself.

=head1 WARRANTY

  This module comes with ABSOLUTELY NO WARRANTY.

=cut
