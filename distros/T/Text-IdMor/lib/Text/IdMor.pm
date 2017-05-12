package Text::IdMor;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::IdMor ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	isAcronym
    isRomanNumber
    isNumber
    isInteger
    isSpanishRealNumber
    isOrdinalNumber
    isWord
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.9';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Text::IdMor - Identify words by its morphology

=head1 SYNOPSIS

  use Text::IdMor;
  blah blah blah

=head1 DESCRIPTION

use Text::IdMor :all;

my $acronym = "A.C.R.O.";
isAcronym($acronym);

my $romanNumber = "LXI";
isRomanNumber($romanNumber);

my $number = "234.45";
isNumber($number);


=head2 EXPORT

None by default.


=head1 SEE ALSO


=head1 AUTHOR

Alberto Montero, E<lt>alberto@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alberto Montero

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

use Text::Roman;

=item isAcronym

Return true if the specified word is an acronym.

=cut 
sub isAcronym($) {
    my $word = shift;
    my $result = 1;

    $result &&= ($word =~ /^\s*([A-Z]+\.)+([A-Z]+\.?)?$/);

    return $result;
}


=item isRomanNumber

Return true if the specified word is a roman number.

=cut 
sub isRomanNumber {
    return Text::Roman::isroman(@_);
}

=item isNumber

Return true if the specified word is a number.

=cut 
sub isNumber {
    my $text = shift;
    return 1 if isInteger($text);
    return 1 if isSpanishRealNumber($text);
    return 1 if ($text =~ /^-?(\d+\,)+\d+\.\d+$/);
    return 1 if ($text =~ /^-?\d+\.\d+$/);
    return 0;
}

sub isSpanishRealNumber($) {
    my $text = shift;
    return 1 if ($text =~ /^-?(\d+\.)+\d+,\d+$/);
    return 1 if ($text =~ /^-?\d+,\d+$/);
}

=item isInteger

Return true if the specified word is an integer.

=cut 
sub isInteger {
    my $text = shift;
    return 1 if ($text =~ /^-?\d+$/);
    return 1 if ($text =~ /^\d{1,3}\.(\d{3}.)*\d{3}$/);
}

=item isOrdinalNumber

Return true if the specified word is an ordinal number, identified as an integer followed by 'º' or 'ª'

=cut 
sub isOrdinalNumber($) {
    my $text = shift;
    if ($text =~ /[ªº]$/) {
        chop($text);  # A bit tricky, but solves the problem when utf8
        my $c = chop($text);
        $text .= $c if ($c =~ /[0-9]/);
        return 1 if (isInteger($text) && $text > 0);
    }
    return 0;
}

=item isWord

Return true if the specified word is a word, i.e. only letters

=cut 
sub isWord($) {
    my $text = shift;
    $text =~ tr/A-ZÁÉÍÓÚÜÑ/a-záéíóúüñ/;
    return $text =~ /^[a-záéíóúüñ]+$/;
}
