package Tie::File::AnyData;

use strict;
use warnings;
use Carp;
use Tie::File;

our $VERSION = '0.03';

sub TIEARRAY
  {
    my ($pack,$file,%opts) = @_;
    my $code;
    ## We process $opts{'code'} (if present).
    if (defined $opts{'code'}){
      $code = $opts{'code'};
      delete $opts{'code'};

      ## We override Tie::File::_read_record.
      no warnings 'redefine';
      *Tie::File::_read_record = sub {
	my ($self) = @_;
	my $rec;
	$rec = $self -> {_get_next_rec} -> ($self->{'fh'});
	return $rec;
      }
    }
    ## After processing the (optional) extra option we call Tie::File::TIEARRAY
    my $self;
    eval { $self = Tie::File::TIEARRAY("Tie::File",$file,%opts) };
    $@ =~ s/at.+//s;
    croak $@ if ($@);
    $self->{_get_next_rec} = $code;
    return $self;
  }

1;

__END__

=head1 NAME

Tie::File::AnyData - Access the data of a disk file via a Perl array

=head1 SYNOPSIS

       use Tie::File::AnyData;

       my $coderef = sub {
       ## Code to retrieve one by one the records from a file, for example,
        # to mimic the default Tie::File behaviour (one line <=> one record):
	# (this is the default behaviour of Tie::File::AnyData too)
		my ($fh) = @_;
		my $rec = <$fh>;
		return $rec;
          };
       tie my @data, 'Tie::File::AnyData', $file, code => $coderef;
       ## Use the tied array...
	# ... once done:
	untie @data;

=head1 DESCRIPTION

This module hacks 'Tie::File' to allow it to manage any kind of data.
See the documentation of 'Tie::File' for more details on the functionality of this module.

To do so, you must provide a code reference (an anonymous subroutine) to the tie call. This
code should be able to read one record of your data file per call.

There are already some modules that subclasses this one and provide examples of use of this module. For example,
check the documentation for C<Tie::File::AnyData::Bio::Fasta> or C<Tie::File::AnyData::MultiRecord_CSV>. You can
use them as guidelines to build your own subroutines and modules. If you don't know how to do that, but you are
still interested in having a module that manages your format of interest, contact me and I will do my best to 
help you in the implementation.

This module keeps intact all the goodies that Tie::File offers (caching and memory limits, deferred writing, etc).
In fact you can safely use this module with the default parameters instead of Tie::File without performance penalty.

=head2 PARAMETERS

This module accepts the same parameters that C<Tie::File>, plus:

C<code>

A reference to a subroutine that must be able to retrieve one data record per call. This subroutine must accept one parameter: an already opened filehandle (or "undef" if there are not more records).
For examples, see C<Tie::File::AnyData::Bio::Fasta> or C<Tie::File::AnyData::CSV>.


=head1 AUTHOR

Miguel Pignatelli

Please, send any comment to: motif@pause.org

The most recent version of this module, should be available at CPAN.


=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-file-anydata at rt.cpan.org>, or through the web interface at
L<http://rp.cpan.org/NoAuth/ReportingBug.html?Queue=Tie-File-AnyData>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command:

     perldoc Tie::File::AnyData

=head1 LICENSE

Copyright 2007 Miguel Pignatelli, all rights reserved.

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 WARRANTY

  This module comes with ABSOLUTELY NO WARRANTY.

=head1 ACKNOWLEDGEMENTS

  Thanks to C<kyle> at C<perlmonks> for suggestions during the implementation of this module

=cut
