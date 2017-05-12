package dtRdrTestUtil;

# Copyright (C) 2006 OSoft, Inc.
# License: GPL

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  error_catch
  slurp_data
);

use File::Basename;

=head1 Functions

All are exported by default.

=head2 error_catch

# XXX seems like there's a module for this
# runs subroutine reference and catches STDERR
#   ($errs, @ans) = error_catch(sub {$this->test()});
#

=cut

sub error_catch {
  my ($sub) = @_;
  my $TO_ERR;
  open($TO_ERR, '<&STDERR');
  close(STDERR);
  my $catch;
  open(STDERR, '>', \$catch);
  my @ans = $sub->();
  open(STDERR, ">&", $TO_ERR);
  close($TO_ERR);
  return($catch, @ans);
} # end subroutine error_catch definition
########################################################################

=head2 slurp_data

Looks for $filename *in the directory of $0* and slurps it in.

  @lines = slurp_data($filename);

=cut

sub slurp_data {
  my ($filename) = @_;
  my $dir = File::Basename::dirname($0);
  my $file = "$dir/$filename";
  (-e $file) or die "$file not found";
  open(my $fh, $file);
  return(map({chomp;$_} <$fh>));
} # end subroutine slurp_data definition
########################################################################

1;
# vim:ts=2:sw=2:et:sta
