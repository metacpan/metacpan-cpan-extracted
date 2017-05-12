package Text::Tx;
use strict;
use warnings;
use Carp;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
our $DEBUG = 0;

require XSLoader;
XSLoader::load('Text::Tx', $VERSION);

sub open{
    my $pkg = shift;
    my $filename = shift;
    my $errfh;
    if (!$DEBUG){
	# temporary close STDERR to suppress messages from tx_tool::tx::read;
	open $errfh, '>&', \*STDERR or die "Can't dup STDERR: $!";
	close STDERR;
    }
    my $dpi = xs_open($filename);
    if (!$DEBUG){
	# and restore STDERR
	open STDERR, '>&', $errfh or die "Can't dup OLDERR: $!";
    }
    carp __PACKAGE__, " cannot open $filename" unless $dpi;
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

sub gsub{
    my $cbstr = $_[2];
    no warnings 'uninitialized';
    my $cb = ref $cbstr ? $cbstr : sub { $cbstr };
    xs_gsub(${$_[0]}, $_[1], $cb);
}


if ($0 eq __FILE__){
    my $tx = __PACKAGE__->open(shift);
    sub say { print @_, "\n" };
    say $tx->gsub("The quick brown fox jumps over the black lazy dog",
		  sub{"<$_[0]>"});
    print STDERR "wow\n"; # make sure STDERR is restored
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::Tx - Perl interface to Tx by OKANOHARA Daisuke

=head1 SYNOPSIS

  use Text::Tx; 
  my $td     = Text::Tx->open("words.tx");
  my $newstr = $td->gsub($str, sub{ 
     qq(<a href="http://dictionary.com/browse/$_[0]">$_[0]</a>)
  }); # link'em all!

=head1 DESCRIPTION

Tx is a library for a compact trie data structure by OKANOHARA Daisuke.
Tx requires 1/4 - 1/10 of the memory usage compared to the previous
implementations, and can therefore handle quite a large number of keys
(e.g. 1 billion) efficiently.

Suppose words.tx is a pre-built tx by txbuild command which contains
foo, bar, and baz,

  $newstr = $td->gsub($str, sub{"<$_[0]>"});

is equivalent to

  my $newstr = $str;
  $newstr = s{ (foo|bar|baz) }{ "<<$1>" }msgex;

Sounds less convenient?  But what happens if the alteration contains
thousands of words?  It takes a whole lot of time and memory just to
compile the regexp.  Tx and L<Text::Tx> does just that.

=head1 REQUIREMENT

Tx 0.04 or above.  Available at 

L<http://www-tsujii.is.s.u-tokyo.ac.jp/~hillbig/tx.htm>

To install, just

  fetch http://www-tsujii.is.s.u-tokyo.ac.jp/~hillbig/software/tx-0.04.tar.gz
  tar zxvf tx-0.04.tar.gz
  cd tx-0.04
  configure
  make
  sudo make install

=head2 EXPORT

None.

=head1 SEE ALSO

L<http://www-tsujii.is.s.u-tokyo.ac.jp/~hillbig/tx.htm>

L<Regexp::Assemble>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
