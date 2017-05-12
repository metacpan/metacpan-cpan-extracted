package Test::ZeroCopy;

use strict;

our $VERSION = '0.110';

require XSLoader;
XSLoader::load('Test::ZeroCopy', $VERSION);

use base 'Test::Builder::Module';
our @EXPORT = qw(is_zerocopy isnt_zerocopy);


sub _impl {
  my $tb = __PACKAGE__->builder;

  my $desc = $_[2] || '';
  my $want_zerocopy = $_[3];

  my $addr1 = get_pv_address($_[0]);
  my $addr2 = get_pv_address($_[1]);

  if (!defined $addr1 || !defined $addr2) {
    $tb->ok(!$want_zerocopy, "$desc: One or both args aren't strings (don't have SvPV values)");
    return;
  }

  my $len1 = get_pv_cur($_[0]);
  my $len2 = get_pv_cur($_[1]);

  $tb->diag(sprintf("ZC: %s%lx+%lx vs %lx+%lx", ($desc ? "$desc: " : ""), $addr1, $len1, $addr2, $len2));

  if ($addr1 == $addr2 && $len1 == $len2) {
    $tb->ok($want_zerocopy, "$desc => (exact overlap)");
  } elsif ($addr1 >= $addr2 && $addr1 < ($addr2 + $len2)) {
    $tb->ok($want_zerocopy, "$desc => (first starts inside second)");
  } elsif ($addr2 >= $addr1 && $addr2 < ($addr1 + $len1)) {
    $tb->ok($want_zerocopy, "$desc => (second starts inside first)");
  } else {
    $tb->ok(!$want_zerocopy, "$desc => (no overlap)");
  }
}

sub is_zerocopy {
  $_[3] = 1;
  goto &_impl;
}

sub isnt_zerocopy {
  $_[3] = 0;
  goto &_impl;
}


1;



__END__

=encoding utf-8

=head1 NAME

Test::ZeroCopy - Test that two strings share the same memory

=head1 SYNOPSIS

    use Test::ZeroCopy;

    is_zerocopy($str1, $str2);
    isnt_zerocopy($str3, $str4);


=head1 BACKGROUND

In applications that attempt to handle large strings efficiently, it can often be a huge win to avoid copying strings.

However, unless you are super careful, it's easy to write perl code that copies strings without realising it:

    my $str = "long string goes here";

    sub getstring {
      my $arg = shift; # this is a copy
      return $arg;
    }

    my $ret = getstring($str); # this is another copy

One solution is to pass references to the string around. Another is to use L<Data::Alias>.

Unfortunately, neither of these approaches help when you want to take a substring of the large string: C<substr> always copies the contents of the string. In C we could avoid copying and instead pass around pointers that point into the string.

Although perl doesn't directly support pointers, it is still possible to take a zero-copy substring by creating a scalar with a C<SvPV> pointing into the large string and a C<SvLEN> set to 0 to indicate that the memory is "owned" by the large string. Also, the reference counts of the two strings are linked so that the large buffer will only be reclaimed once all substrings go out of scope.

L<String::Slice> is an example of a module that can create zero-copy sub-strings or "slices" in this way.

This module came about because I got tired of sprinkling L<Devel::Peek> C<Dump> statements around my code to confirm no copying occurred. Here is an example of how to do that:

    use String::Slice;
    use Devel::Peek;

    my $buf = "ABCDEF";
    my $slice = "";
    slice($slice, $buf, 1, 3);

    Dump($buf);
    Dump($slice);

And the (abridged) output:

    SV = PV(0x14e0c20) at 0x1501270
      PV = 0x14fa1f0 "ABCDEF"\0
      CUR = 6
      LEN = 16
    SV = PVMG(0x1528db0) at 0x150d678
      PV = 0x14fa1f1 "BCD"
      CUR = 3
      LEN = 0

Notice how the PV values point into the same buffer.

Instead of manual inspection, this module lets you add these assertions to your test-suites to ensure that you (or future maintainers) don't accidentally add wasteful copy operations.



=head1 USAGE

This module provides two L<Test::More>-compatible testing functions: C<is_zerocopy> and C<isnt_zerocopy>.

Each of these functions should be passed two strings. C<is_zerocopy> will assert that the backing memory is shared between the two strings. This is assumed to be the case when any portions of their PV buffers overlap.

The backing memory is trivially shared in the case where the two strings are the same (ie C<is_zerocopy($str, $str)>), but is much more interesting when one is a substring or "slice" of the other and they happen to use the same backing memory (see above).

C<isnt_zerocopy> is the opposite and it will assert that the backing memory is I<not> shared between the two strings.

You can also use this module to get the PV address from a perl program (which I couldn't figure out how to do with L<B>):

    require Test::ZeroCopy;
    my $addr = Test::ZeroCopy::get_pv_address($string);




=head1 SEE ALSO

L<Test-ZeroCopy github repo|https://github.com/hoytech/Test-ZeroCopy>

L<Data::Alias> - Sometimes more convenient to use this module than to use references

L<String::Slice> - Simple module that can make zero-copy substrings

L<File::Map> - Interface to C<mmap()> that lets you "read in" a whole file into a string suitable for performing zero-copy substring operations

L<LMDB_File> - In-process database that supports zero-copy reads


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2014 Doug Hoyte.

This module is licensed under the same terms as perl itself.
