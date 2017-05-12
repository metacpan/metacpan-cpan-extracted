package Text::Truncate;

use 5.00400;
use warnings;
use strict;

use Carp;

require Exporter;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $DEFAULT_MARKER );
@ISA = qw( Exporter );

@EXPORT_OK = ( @EXPORT, qw( $DEFAULT_MARKER ) );
@EXPORT = qw(
 truncstr
);
$VERSION = '1.06';

$DEFAULT_MARKER = "...";

sub truncstr
  {
    my $string = shift;
    my $cutoff = shift;
    my $marker = shift;

    $marker = ($DEFAULT_MARKER || ""), unless (defined($marker));

    croak "continued symbol is longer than the cutoff length",
      if (length($marker) > $cutoff);

    if (length($string) > $cutoff) {
      $string = (substr($string, 0, $cutoff-length($marker))||"") . $marker;
    }

    return $string;
  }

1;
__END__

=head1 NAME

Text::Truncate - Perl module with simple string truncating routine.

=begin readme

=head1 REQUIREMENTS

This module only uses standard modules. It should run on Perl 5.004.

=head1 INSTALLATION

Installation is pretty standard:

  perl Makefile.PL
  make test
  make install

(On Windows platforms you should use nmake instead.)

Using Build.PL (if you have L<Module::Build> installed):

  perl Build.PL
  perl Build test
  perl Build install    

=end readme

=head1 SYNOPSIS

  use Text::Truncate;

  my $long_string = "This is a very long string";

  # outputs "This is..."
  print truncstr( $long_string, 10);

  # outputs "This is a-"
  print truncstr( $long_string, 10, "-");

  # outputs "This is a "
  print truncstr( $long_string, 10, "");

  # outputs "This is---"
  $Text::Truncate::DEFAULT_MARKER = "---";
  print truncstr( $long_string, 10);

=head1 DESCRIPTION

This is a simple, no-brainer subroutine to truncate a string and add
an optional cutoff marker (defaults to ``...'').

(Yes, this is a really brain-dead sort of thing to make a module out
of, but then again, I use it so often that it might as well be in a
module.)

The synopsis gives examples of how to use it.

=for readme stop

=head2 EXPORT

The following functions are exported:

=over

=item truncstr

  $rstring = truncstr( $istring, $cutoff_length );

  $rstring = truncstr( $istring, $cutoff_length, $continued_symbol );

If the C<$istring> is longer than the C<$cutoff_length>, then the
string will be truncated to C<$cutoff_length> characters, including
the C<$continued_symbol> (which defaults to ``...'' if none is
specified).

The default C<$continued_symbol> can be changed in
C<$Text::Truncate::DEFAULT_MARKER>.

=back

=for readme continue

=head1 SEE ALSO
 
 L<String::Truncate>, L<Text::Elide>

=head1 REPOSITORY
 
 https://github.com/ileiva/Text-Truncate

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>
This is now being mantained by Israel Leiva <ilv@cpan.org>

=head1 LICENSE

Unrestricted. This module is in the public domain. No copyright is claimed.

=cut
