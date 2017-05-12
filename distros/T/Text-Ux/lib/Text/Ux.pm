package Text::Ux;
use 5.008005;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = "0.11";

require XSLoader;
XSLoader::load('Text::Ux', $VERSION);

our %EXPORT_TAGS = (all => [qw(LIMIT_DEFAULT)]);
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;
__END__

=encoding utf-8

=head1 NAME

Text::Ux - More Succinct Trie Data structure (binding for ux-trie)

=head1 SYNOPSIS

  use Text::Ux;

  my $ux = Text::Ux->new;

  # build
  $ux->build([qw(foo bar baz)]);
  $ux->save('/path/to/index');
  # or save the dictionary into string
  $ux->save(\my $dic);

  # search
  $ux->load('/path/to/index');
  # or pass string
  $ux->load(\$dic);
  my $key = $ux->prefix_search('text');
  my @keys = $ux->common_prefix_search('text');
  my @keys = $ux->predictive_search('text');

  # substitute
  my $text = $ux->gsub('text', sub { "<$_[0]>" });

  # list
  for (my $i = 0; $i < $ux->size; $i++) {
      say $ux->decode_key($i);
      say $ux->decode_key_utf8($i);
  }

=head1 DESCRIPTION

Text::Ux is a perl bindng for ux-trie.

L<https://code.google.com/p/ux-trie/>

=head1 METHODS

=over 4

=item $ux = Text::Ux->new()

Creates a new instance.

=item $ux->build($keys, $is_tail_ux = TRUE)

=item $ux->save($filename_or_scalarref)

=item $ux->load($filename_or_scalarref)

=item $key = $ux->prefix_search($query)

=item @keys = $ux->common_prefix_search($query, $limit = LIMIT_DEFAULT])

=item @keys = $ux->predictive_search($query, $limit = LIMIT_DEFAULT])

=item $text = $ux->gsub($query, $callback)

=item $key = $ux->decode_key($id)

=item $key = $ux->decode_key_utf8($id)

=item $ux->clear()

=item $size = $ux->size()

=item $size = $ux->alloc_size()

=item $stat = $ux->stat()

=item $stat = $ux->alloc_stat($alloc_size)

=back

=head1 CONSTANTS

=over 4

=item LIMIT_DEFAULT

Default value for the maximum number of matched keys

=back

=head1 EXPORT_TAGS

=over 4

=item :all

This exports all constants found in this module.

=back

=head1 SEE ALSO

L<https://code.google.com/p/ux-trie/>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2014, Jiro Nishiguchi All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
    * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
 copyright notice, this list of conditions and the following disclaimer
 in the documentation and/or other materials provided with the
 distribution.
    * Neither the name of Jiro Nishiguchi. nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See also vendor/ux-trie/src/ux.hpp for bundled ux-trie sources.

=cut
