# NAME

Text::Ux - More Succinct Trie Data structure (binding for ux-trie)

# SYNOPSIS

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

# DESCRIPTION

Text::Ux is a perl bindng for ux-trie.

[https://code.google.com/p/ux-trie/](https://code.google.com/p/ux-trie/)

# METHODS

- $ux = Text::Ux->new()

    Creates a new instance.

- $ux->build($keys, $is\_tail\_ux = TRUE)
- $ux->save($filename\_or\_scalarref)
- $ux->load($filename\_or\_scalarref)
- $key = $ux->prefix\_search($query)
- @keys = $ux->common\_prefix\_search($query, $limit = LIMIT\_DEFAULT\])
- @keys = $ux->predictive\_search($query, $limit = LIMIT\_DEFAULT\])
- $text = $ux->gsub($query, $callback)
- $key = $ux->decode\_key($id)
- $key = $ux->decode\_key\_utf8($id)
- $ux->clear()
- $size = $ux->size()
- $size = $ux->alloc\_size()
- $stat = $ux->stat()
- $stat = $ux->alloc\_stat($alloc\_size)

# CONSTANTS

- LIMIT\_DEFAULT

    Default value for the maximum number of matched keys

# EXPORT\_TAGS

- :all

    This exports all constants found in this module.

# SEE ALSO

[https://code.google.com/p/ux-trie/](https://code.google.com/p/ux-trie/)

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>

# COPYRIGHT AND LICENSE

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
