package Unicode::Char;
use 5.008001;
use strict;
use warnings;
use Carp;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
our $DEBUG = 0;

our %Name2Chr;
our %Chr2Name;

sub _init{
    return if %Name2Chr;
    my $name_pl = do 'unicore/Name.pl'; # famous cheat;
    for my $line (split /\n/, $name_pl){
	chomp $line;
	my ($hex, $name) = ($line =~ /^([0-9A-Fa-f]+)\s+(.*)/);
	next if $name =~ /[a-z]/; # range, not character
	my $chr = chr(hex($hex));
	$Name2Chr{$name} = $chr;
	$Chr2Name{$chr}  = $name; 
    }
}

sub new {
    my $pkg = shift;
    return bless \eval{ my $scalar }, $pkg;
}

sub valid($$){
    my ($self,$ord) = @_;
    return 0 if $ord <  0;
    return 1 if $ord <  0xDC00;   # BMP before surrogates
    return 0 if $ord <= 0xDFFF;   # surrogates
    return 1 if $ord <  0xFFFF;   # BMP after surrogates
    return 0 if $ord == 0xFFFF;   # U+FFFF is invalid
    return 1 if $ord <= 0x10FFFF; # and to the max; 
    return 0;
}

sub names($$){
    my ($self,$str) = @_;
    _init;
    return map { $Chr2Name{chr($_)} } unpack("U*", $str);
}

sub name($$){
    return ($_[0]->names($_[1]))[0];
}

sub u($$){
    my ($self, $hex) = @_;
    my $ord = hex($hex);
    croak "$ord is invalid" unless $self->valid($ord);
    return chr($ord);
}

sub n($$){
    my ($self, $name) = @_;
    _init();
    # canonicalize;
    $name =~ tr/_/ /;
    $name = uc($name);
    return $Name2Chr{$name};
}

sub DESTROY{} # so AUTOLOAD will not handle this

sub AUTOLOAD{
    my $method = our $AUTOLOAD;
    $DEBUG and carp $method;
    $method =~ s/.*:://o;
    if ($method =~ s/^u_?//o){
	my $chr = __PACKAGE__->new()->u($method);
	defined $chr or croak "U$method is invalid!";
	no strict 'refs';
	*{$AUTOLOAD} = sub { $chr };
	goto &$AUTOLOAD;
    }
    else{
	my $chr = __PACKAGE__->new()->n($method);
	defined $chr or croak qq(There is no character named "$method");
	no strict 'refs';
	*{$AUTOLOAD} = sub { $chr };
	goto &$AUTOLOAD;
    }
}

1;
__END__

=head1 NAME

Unicode::Char - OO interface to charnames and others

=head1 SYNOPSIS

  use Unicode::Char;
  my $u = Unicode::Char->new();
  # prints "KOGAI Dan" in Kanji
  print $u->u5c0f, $u->u98fc, $u->u5f3e, "\n";
  # smiley here
  print $u->white_smiling_face, $u->black_smiling_face, "\n";

=head1 DESCRIPTION

This module provides OO interface to Unicode characters.

=over 2

=item C<< $u->u() >>

Returns a character whose Unicode Number is the argument.

  $u->u('5c0f'); # "small" in Kanji

But the following is handier.

  $u->u5c0f;    # same thing but as a method

These methods are generatated on demand.

=item C<< $u->n() >>

Returns a character whose Unicode Canonical Name is the argument.

  $u->n('white smiling face'); 

But as  C<< $u->u() >>, you may prefer the handier version:

  $u->white_smiling_face;

As you many have noticed, these names do not have to be all in caps.
Just replace spaces with underscore.

=item C<< $u->name() >>

Returns the Unicode Canonical Name of the character.;

  my $name    = $u->name(chr(0x263A)); # WHITE SMILING FACE



=item C<< $u->names() >>

Same as above but in list context.

  my (@names) = $u->name("perl"); # ('LATIN SMALL LETTER P',
                                  #  'LATIN SMALL LETTER E',
                                  #  'LATIN SMALL LETTER R',
                                  #  'LATIN SMALL LETTER L')

=back

=head2 EXPORT

None.

=head1 SEE ALSO

L<perlunicode>, L<perluniintro>, L<charnames>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jp<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
