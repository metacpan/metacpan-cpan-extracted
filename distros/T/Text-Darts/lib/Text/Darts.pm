package Text::Darts;
use strict;
use warnings;
use Carp;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.9 $ =~ /(\d+)/g;
our $DEBUG = 0;

require XSLoader;
XSLoader::load('Text::Darts', $VERSION);

sub new{
    my $pkg = shift;
    my $dpi = xs_make([ grep { $_ } sort @_]);
    bless \$dpi, $pkg;
}

sub open{
    my $pkg = shift;
    my $filename = shift;
    my $dpi = xs_open($filename) 
	or carp __PACKAGE__, " cannot open $filename";
    bless \$dpi, $pkg;
}

sub DESTROY{
    if ($DEBUG){
	no warnings 'once';
	require Data::Dumper;
	local $Data::Dumper::Terse  = 1;
	local $Data::Dumper::Indent = 0;
	warn "DESTROY:", Data::Dumper::Dumper($_[0]);
    }
    xs_free(${$_[0]});
}

sub search{
    xs_search(${$_[0]}, $_[1]);
}

sub gsub{
    my $cbstr = $_[2];
    no warnings 'uninitialized';
    my $cb = ref $cbstr ? $cbstr : sub { $cbstr };
    xs_gsub(${$_[0]}, $_[1], $cb);
}

if ($0 eq __FILE__){
    sub say { print @_, "\n" };
    my @a = ("ALGOL", "ANSI", "ARCO",  "ARPA", "ARPANET", "ASCII");
    my %a = map { $_ => lc $_ } @a;
    my $da = __PACKAGE__->new(@a);
    say $da->gsub("I don't like ALGOL at all!", sub{"<$_[0]>"});
    say $da->gsub("I don't like nomatch at all!");
    say $da->gsub("I don't like ALGOL at all!", \%a);
    if (@ARGV){
	$da = __PACKAGE__->open(shift);
	say $da->gsub("The quick brown fox jumps over the black lazy dog",
		      sub{"<$_[0]>"});
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::Darts - Perl interface to DARTS by Taku Kudoh

=head1 SYNOPSIS

  use Text::Darts;
  my @words = qw/ALGOL ANSI ARCO ARPA ARPANET ASCII/;
  my %word   = map { $_ => lc $_ } @words;
  my $td     = Text::Darts->new(@words);
  my $newstr = $td->gsub("ARPANET is a net by ARPA", sub{ "<<$_[0]>>" });
  # $newstr is now "<<ARPANET>> is a net by <<ARPA>>".
  my $lstr   = $td->gsub("ARPANET is a net by ARPA", \%word);
  # $Lstr is now "arpanet is a net by arpa".

  # or
  my $td     = Text::Darts->open("words.darts"); # make one with mkdarts
  my $newstr = $td->gsub($str, sub{ 
     qq(<a href="http://dictionary.com/browse/$_[0]">$_[0]</a>)
  }); # link'em all!

=head1 DESCRIPTION

Darts, or Double-ARray Trie System is a C++ Template Library by Taku Kudoh.
This module makes use of Darts to implement global replace like below;

  $str = s{ (foo|bar|baz) }{ "<<$1>>" }msgex;

The problem with regexp is that it is slow with alterations.  Suppose
you want to anchor all words that appear in /usr/share/dict/words with
regexp.  It would be impractical with regexp.  This module makes it
practical.

Even if you are using perl 5.10 or better which does TRIE optimization
internally, you still have to compile the regexp everytime you run the
script.  So it is still more practical to use this module if your
match is exact -- containing no quantifier.

Since Version 0.05, L<Text::Darts> also accepts a hash reference
instead of a code reference.  In such cases gsub behaves as follows.

  $str = s{ (foo|bar|baz) }{$replacement{$1}}msgx;

like C<s///ge> vs C<s///g>, this is less flexible but faster.

=head1 REQUIREMENT

Since Version 0.07, you no longer need to have Darts installed.  This
module now bundles darts.h which is needed to build this module.  To
get the most out of Darts, you still need to install Darts 0.32 or
above.

L<http://chasen.org/~taku/software/darts/index.html> (Japanese)

  fetch http://chasen.org/~taku/software/darts/src/darts-0.32.tar.gz
  tar zxvf darts-0.32.tar.gz
  cd darts-0.32
  configure
  make
  make check
  sudo make install



=head2 EXPORT

None.

=head2 Functions

=over 2

=item Text::Darts::DARTS_VERSION

returns DARTS version.  Currently 0.32

=back

=head1 SEE ALSO

L<http://chasen.org/~taku/software/darts/index.html> (Japanese)

L<Regexp::Assemble>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

=over 2

=item darts.h

Copyright (c) 2001-2008, Taku Kudo
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 * Redistributions of source code must retain the above
   copyright notice, this list of conditions and the
   following disclaimer.

 * Redistributions in binary form must reproduce the above
   copyright notice, this list of conditions and the
   following disclaimer in the documentation and/or other
   materials provided with the distribution.

 * Neither the name of the Nippon Telegraph and Telegraph Corporation
   nor the names of its contributors may be used to endorse or
   promote products derived from this software without specific
   prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABI LITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONT RIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR P ROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT , STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF TH IS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=item anything else

Copyright (C) 2007-2009 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=back

=cut
