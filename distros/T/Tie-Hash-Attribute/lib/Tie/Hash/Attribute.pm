package Tie::Hash::Attribute;
use 5.006;
use strict;
use warnings FATAL => 'all';
our $VERSION = '1.06';
our @ISA = 'Tie::Hash';

our $ATTR_SORT = 0;

sub STORE       { $_[0]{$_[1]}=$_[2] }
sub SCALAR      { _mk_str($_[0]) }
sub EXISTS      { exists $_[0]{$_[1]} }
sub FIRSTKEY    { each %{$_[0]} }
sub NEXTKEY     { each %{$_[0]} } 
sub DELETE      { delete $_[0]{$_[1]} }
sub CLEAR       { %{$_[0]} = () }

sub TIEHASH {
    my $class = shift;
    my %args  = @_;
    $ATTR_SORT = 1 if defined $args{sorted};
    return bless {}, $class;
}

sub FETCH {
    my $self = shift;
    my $arg  = shift;
    return $self->{$arg} unless substr($arg,0,1) eq '-';
    $arg =~ s/^-//;
    return _mk_str( $self->{$arg} );
}

sub _mk_str {
    my $hash = shift;
    my $str = '';
    my %seen;
    my @keys = $ATTR_SORT ? sort keys %$hash : keys %$hash;
    for my $key (@keys) {
        next if $seen{lc$key}++;
        my $val = $hash->{$key};
        $val  = _stringify( $val )  if ref $val eq 'HASH';
        $val  = _rotate( $val )     if ref $val eq 'ARRAY';
        next unless defined $val;
        $str .= sprintf ' %s="%s"', _key( $key ), _val( $val );
    }
    return $str;
}

sub _key {
    my $key = shift;
    return '' unless defined $key;
    $key =~ s/\s//g;
    $key =~ s/["'>=\/]//g;
    return $key;
}

sub _val {
    my $val = shift;
    $val = '' if $val =~ /^\s+$/;
    $val =~ s/"//g;
    return $val;
}

sub _rotate {
    my $ref  = shift;
    my $next = shift @$ref;
    push @$ref, $next;
    return $next;
}

sub _stringify {
    my $hash = shift;

    my @keys = $ATTR_SORT ? sort keys %$hash : keys %$hash;
    my @vals = map { my $val;

        if (ref $hash->{$_} eq 'ARRAY') {
            $val = _rotate( $hash->{$_} );
        } elsif (ref $hash->{$_} eq 'HASH') {
            ($val) = $ATTR_SORT ? sort keys %{ $hash->{$_} } : keys %{ $hash->{$_} };
        } else {
            $val = $hash->{$_};
        }

        join( ': ', $_, $val);

    } @keys;

    return join( '; ', @vals ) . (@vals > 1 ? ';' : '');
}

1;

__END__
=head1 NAME

Tie::Hash::Attribute - Just another HTML attribute generator.

=head1 SYNOPSIS

  use Tie::Hash::Attribute;

  tie my %tag, 'Tie::Hash::Attribute';
  %tag = (
      table => { border => 0 },
      tr => {
          style => { color => 'red', align => 'right' },
      },
      td => {
          style => {
              align => [qw( left right )],
              color => [qw( red blue green )],
          }
      },
  );
 
  print $tag{-table};
    # border: 0

  print $tag{-tr};
    # style="align: right; color: red;"

  print $tag{-td} for 1 .. 4;
    # style="align: left; color: red;"',
    # style="align: right; color: blue;"',
    # style="align: left; color: green;"',
    # style="align: right; color: red;"',

  # or emit all attributes at once
  tie my %tr_tag, 'Tie::Hash::Attribute';

  %tr_tag = ( style => {
      align => [qw(left right)],
      color => [qw(red blue green)]
  } );

  print scalar %tr_tag for 1 .. 4;
    # style="align: left; color: red;"
    # style="align: right; color: blue;"
    # style="align: left; color: green;"
    # style="align: right; color: red;"

=head1 DESCRIPTION

This module will translate nested hash keys and values into HTML
tag attributes that can have ther values automatically rotated.

Hash values can be scalars, arrays, hashes or hashes of hashes.

To emit values as an HTML attribute string, fetch the key with
a dash prepended to it:

  %hash = ( foo => 1, bar => 2, baz => 3);

  print $hash{foo};     # returns 1
  print $hash{-foo};    # returns foo="1"

Or access the entire hash as a scalar:

  print scalar %hash;
    # foo="1" bar="2" baz="3"

This can be used to aide in the creation of HTML tags:

  print '<table>';
  for my $row (@rows) {
      printf '<tr%s>', scalar %tr_tag;
      for my $col (@$row) {
          printf '<td%s>%s</td>', scalar %td_tag, $col;
      }
      print '</tr>';
  }
  print '/<table>';

The decision on which style to apply to a row is deferred to
the tied hash. Assign an array reference to the key and each
value will be rotated.

  %tr_tag = ( class => [qw( odd even )] );

All HTML attribute strings returned will have a leading space.
This prevents the client from having to check for the potential
of no attributes, which would leave tags with trailing space
inside the start tag: <foo ></foo>

As such all attributes values are enclosed in double quotes, not single quotes.
Additional rules for keys and values:

=over 4

=item * any attribute with a value of undef will be skipped

=item * no case-insenstive matches for attribute names in start tag

=item * remove any occurance from keys: " ' > / = and spaces

=item * remove any occurance from values: "

=back

=head1 ORDERING

Since the internal storage for this package is a hash, ordering of
attribute names (for consistancy) can be achieved by specifying a
true value for the parameter C<sorted> like so:

  tie my %tag, 'Tie::Hash::Attribute', sorted => 1;
  %hash = ( foo => 1, bar => 2, baz => 3);
  print scalar %hash;
    # bar="2" baz="3" foo="1"

The author wishes to somehow utilize Tie::IxHash to allow the client
to force desired order, but tieing a tied hash is tricky. Most of time
attribute order is not important, but it can be in a handful of cases.
If you run into such a case, please alert the author via a bug report.

=head1 SEE ALSO

=over 4

=item * L<http://www.w3.org/TR/html5/syntax.html#attributes-0>

=item * L<http://www.w3.org/TR/html-markup/syntax.html#syntax-attributes>

=back

=head1 BUGS AND LIMITATIONS

Assignment stops at the second nested key, which will use the
third as its value:

  $tag{foo}{1st}{2nd}{3rd} = '4th';
  print $tag{-foo}, "\n";

  # yields 1st="2nd: 3rd;"

This is an intended limitation. If there are other keys in the
second nested hash, then the first key in alphabetical order wins.

Please report any bugs or feature requests to either

=over 4

=item * Email: C<bug-tie-hash-attribute at rt.cpan.org>

=item * Web: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Hash-Attribute>

=back

=head1 GITHUB

The Github project is L<https://github.com/jeffa/Tie-Hash-Attribute>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Hash::Attribute

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here) L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Hash-Attribute>

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/Tie-Hash-Attribute>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/Tie-Hash-Attribute>

=item * Search CPAN L<http://search.cpan.org/dist/Tie-Hash-Attribute/>

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut
