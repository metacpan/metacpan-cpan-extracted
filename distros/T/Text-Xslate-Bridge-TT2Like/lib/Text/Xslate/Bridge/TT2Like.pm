package Text::Xslate::Bridge::TT2Like;
use 5.008001;
use strict;
use warnings;
use base qw(Text::Xslate::Bridge);

our $VERSION = '0.00010';

use Scalar::Util 'blessed';
use Text::Xslate;

our $TRUNCATE_LENGTH = 32;
our $TRUNCATE_ADDON  = '...';

__PACKAGE__->bridge(
    scalar => {
        item    => \&_text_item,
        list    => \&_text_list,
        hash    => \&_text_hash,
        length  => \&_text_length,
        size    => \&_text_size,
        defined => \&_text_defined,
        match   => \&_text_match,
        search  => \&_text_search,
        repeat  => \&_text_repeat,
        replace => \&_text_replace,
        remove  => \&_text_remove,
        split   => \&_text_split,
        chunk   => \&_text_chunk,
        substr  => \&_text_substr,
    },
    hash => {
        item    => \&_hash_item,
        hash    => \&_hash_hash,
        size    => \&_hash_size,
        each    => \&_hash_each,
        keys    => \&_hash_keys,
        values  => \&_hash_values,
        items   => \&_hash_items,
        pairs   => \&_hash_pairs,
        list    => \&_hash_list,
        exists  => \&_hash_exists,
        defined => \&_hash_defined,
        delete  => \&_hash_delete,
        import  => \&_hash_import,
        sort    => \&_hash_sort,
        nsort   => \&_hash_nsort,
    },
    array => {
        item    => \&_list_item,
        list    => \&_list_list,
        hash    => \&_list_hash,
        push    => \&_list_push,
        pop     => \&_list_pop,
        unshift => \&_list_unshift,
        shift   => \&_list_shift,
        max     => \&_list_max,
        size    => \&_list_size,
        defined => \&_list_defined,
        first   => \&_list_first,
        last    => \&_list_last,
        reverse => \&_list_reverse,
        grep    => \&_list_grep,
        join    => \&_list_join,
        sort    => \&_list_sort,
        nsort   => \&_list_nsort,
        unique  => \&_list_unique,
        import  => \&_list_import,
        merge   => \&_list_merge,
        slice   => \&_list_slice,
        splice  => \&_list_splice,
    },
    function => {
        # 'html'            => \&_html_filter, # Xslate has builtin filter for html escape, and it is not overridable.
        html_para       => Text::Xslate::html_builder(\&_html_paragraph),
        html_break      => Text::Xslate::html_builder(\&_html_para_break),
        html_para_break => Text::Xslate::html_builder(\&_html_para_break),
        html_line_break => Text::Xslate::html_builder(\&_html_line_break),
        xml             => Text::Xslate::html_builder(\&_xml_filter),
        # 'uri'             => \&uri_escape, # builtin from version 0.1052
        url             => \&Text::Xslate::uri_escape,
        upper           => sub { uc $_[0] },
        lower           => sub { lc $_[0] },
        ucfirst         => sub { ucfirst $_[0] },
        lcfirst         => sub { lcfirst $_[0] },
        # 'stderr'          => sub { print STDERR @_; return '' }, # anyone want this??
        trim            => sub { for ($_[0]) { s/^\s+//; s/\s+$// }; $_[0] },
        null            => sub { return '' },
        collapse        => sub { for ($_[0]) { s/^\s+//; s/\s+$//; s/\s+/ /g };
                                $_[0] },
        indent      => \&_indent_filter_factory,
        format      => \&_format_filter_factory,
        truncate    => \&_truncate_filter_factory,
        repeat      => \&_repeat_filter_factory,
        replace     => \&_replace_filter_factory,
        remove      => \&_remove_filter_factory,
    },
);

sub _text_item {
    $_[0];
}

sub _text_list { 
    [ $_[0] ];
}

sub _text_hash { 
    { value => $_[0] };
}

sub _text_length { 
    length $_[0];
}

sub _text_size { 
    return 1;
}

sub _text_defined { 
    return 1;
}

sub _text_match {
    my ($str, $search, $global) = @_;
    return $str unless defined $str and defined $search;
    my @matches = $global ? ($str =~ /$search/g)
        : ($str =~ /$search/);
    return @matches ? \@matches : '';
}

sub _text_search { 
    my ($str, $pattern) = @_;
    return $str unless defined $str and defined $pattern;
    return $str =~ /$pattern/;
}

sub _text_repeat { 
    my ($str, $count) = @_;
    $str = '' unless defined $str;  
    return '' unless $count;
    $count ||= 1;
    return $str x $count;
}

sub _text_replace {
    my ($text, $pattern, $replace, $global) = @_;
    $text    = '' unless defined $text;
    $pattern = '' unless defined $pattern;
    $replace = '' unless defined $replace;
    $global  = 1  unless defined $global;

    if ($replace =~ /\$\d+/) {
        # replacement string may contain backrefs
        my $expand = sub {
            my ($chunk, $start, $end) = @_;
            $chunk =~ s{ \\(\\|\$) | \$ (\d+) }{
                $1 ? $1
                    : ($2 > $#$start || $2 == 0) ? '' 
                    : substr($text, $start->[$2], $end->[$2] - $start->[$2]);
            }exg;
            $chunk;
        };
        if ($global) {
            $text =~ s{$pattern}{ &$expand($replace, [@-], [@+]) }eg;
        } 
        else {
            $text =~ s{$pattern}{ &$expand($replace, [@-], [@+]) }e;
        }
    }
    else {
        if ($global) {
            $text =~ s/$pattern/$replace/g;
        } 
        else {
            $text =~ s/$pattern/$replace/;
        }
    }
    return $text;
}

sub _text_remove { 
    my ($str, $search) = @_;
    return $str unless defined $str and defined $search;
    $str =~ s/$search//g;
    return $str;
}
    
sub _text_split {
    my ($str, $split, $limit) = @_;
    $str = '' unless defined $str;
    
    # we have to be very careful about spelling out each possible 
    # combination of arguments because split() is very sensitive
    # to them, for example C<split(' ', ...)> behaves differently 
    # to C<$space=' '; split($space, ...)>
    
    if (defined $limit) {
        return [ defined $split 
                 ? split($split, $str, $limit)
                 : split(' ', $str, $limit) ];
    }
    else {
        return [ defined $split 
                 ? split($split, $str)
                 : split(' ', $str) ];
    }
}

sub _text_chunk {
    my ($string, $size) = @_;
    my @list;
    $size ||= 1;
    if ($size < 0) {
        # sexeger!  It's faster to reverse the string, search
        # it from the front and then reverse the output than to 
        # search it from the end, believe it nor not!
        $string = reverse $string;
        $size = -$size;
        unshift(@list, scalar reverse $1) 
            while ($string =~ /((.{$size})|(.+))/g);
    }
    else {
        push(@list, $1) while ($string =~ /((.{$size})|(.+))/g);
    }
    return \@list;
}

sub _text_substr {
    my ($text, $offset, $length, $replacement) = @_;
    $offset ||= 0;
    
    if(defined $length) {
        if (defined $replacement) {
            substr( $text, $offset, $length, $replacement );
            return $text;
        }
        else {
            return substr( $text, $offset, $length );
        }
    }
    else {
        return substr( $text, $offset );
    }
}

sub _hash_item { 
    my ($hash, $item) = @_; 
    $item = '' unless defined $item;
    $hash->{ $item };
}

sub _hash_hash { 
    $_[0];
}

sub _hash_size { 
    scalar keys %{$_[0]};
}

sub _hash_each { 
    # this will be changed in TT3 to do what hash_pairs() does
    [ %{ $_[0] } ];
}

sub _hash_keys { 
    [ keys   %{ $_[0] } ];
}

sub _hash_values { 
    [ values %{ $_[0] } ];
}

sub _hash_items {
    [ %{ $_[0] } ];
}

sub _hash_pairs { 
    [ map { 
        { key => $_ , value => $_[0]->{ $_ } } 
      }
      sort keys %{ $_[0] } 
    ];
}

sub _hash_list { 
    my ($hash, $what) = @_;  
    $what ||= '';
    return ($what eq 'keys')   ? [   keys %$hash ]
        :  ($what eq 'values') ? [ values %$hash ]
        :  ($what eq 'each')   ? [        %$hash ]
        :  # for now we do what pairs does but this will be changed 
           # in TT3 to return [ $hash ] by default
        [ map { { key => $_ , value => $hash->{ $_ } } }
          sort keys %$hash 
          ];
}

sub _hash_exists { 
    exists $_[0]->{ $_[1] };
}

sub _hash_defined { 
    # return the item requested, or 1 if no argument 
    # to indicate that the hash itself is defined
    my $hash = shift;
    return @_ ? defined $hash->{ $_[0] } : 1;
}

sub _hash_delete { 
    my $hash = shift; 
    delete $hash->{ $_ } for @_;
}

sub _hash_import { 
    my ($hash, $imp) = @_;
    $imp = {} unless ref $imp eq 'HASH';
    @$hash{ keys %$imp } = values %$imp;
    return '';
}

sub _hash_sort {
    my ($hash) = @_;
    [ sort { lc $hash->{$a} cmp lc $hash->{$b} } (keys %$hash) ];
}

sub _hash_nsort {
    my ($hash) = @_;
    [ sort { $hash->{$a} <=> $hash->{$b} } (keys %$hash) ];
}

sub _list_item {
    $_[0]->[ $_[1] || 0 ];
}

sub _list_list { 
    $_[0];
}

sub _list_hash { 
    my $list = shift;
    if (@_) {
        my $n = shift || 0;
        return { map { ($n++, $_) } @$list }; 
    }
    no warnings;
    return { @$list };
}

sub _list_push {
    my $list = shift; 
    push(@$list, @_); 
    return '';
}

sub _list_pop {
    my $list = shift; 
    pop(@$list);
}

sub _list_unshift {
    my $list = shift; 
    unshift(@$list, @_); 
    return '';
}

sub _list_shift {
    my $list = shift; 
    shift(@$list);
}

sub _list_max {
    no warnings;
    my $list = shift; 
    $#$list; 
}

sub _list_size {
    no warnings;
    my $list = shift; 
    $#$list + 1; 
}

sub _list_defined {
    # return the item requested, or 1 if no argument to 
    # indicate that the hash itself is defined
    my $list = shift;
    return @_ ? defined $list->[$_[0]] : 1;
}

sub _list_first {
    my $list = shift;
    return $list->[0] unless @_;
    return [ @$list[0..$_[0]-1] ];
}

sub _list_last {
    my $list = shift;
    return $list->[-1] unless @_;
    return [ @$list[-$_[0]..-1] ];
}

sub _list_reverse {
    my $list = shift; 
    [ reverse @$list ];
}

sub _list_grep {
    my ($list, $pattern) = @_;
    $pattern ||= '';
    return [ grep /$pattern/, @$list ];
}

sub _list_join {
    my ($list, $joint) = @_; 
    join(defined $joint ? $joint : ' ', 
         map { defined $_ ? $_ : '' } @$list);
}

sub _list_sort_make_key {
   my ($item, $fields) = @_;
   my @keys;

   if (ref($item) eq 'HASH') {
       @keys = map { $item->{ $_ } } @$fields;
   }
   elsif (blessed $item) {
       @keys = map { $item->can($_) ? $item->$_() : $item } @$fields;
   }
   else {
       @keys = $item;
   }
   
   # ugly hack to generate a single string using a delimiter that is
   # unlikely (but not impossible) to be found in the wild.
   return lc join('/*^UNLIKELY^*/', map { defined $_ ? $_ : '' } @keys);
}

sub _list_sort {
    my ($list, @fields) = @_;
    return $list unless @$list > 1;         # no need to sort 1 item lists
    return [ 
        @fields                          # Schwartzian Transform 
        ?   map  { $_->[0] }                # for case insensitivity
            sort { $a->[1] cmp $b->[1] }
            map  { [ $_, _list_sort_make_key($_, \@fields) ] }
            @$list
        :  map  { $_->[0] }
           sort { $a->[1] cmp $b->[1] }
           map  { [ $_, lc $_ ] } 
           @$list,
    ];
}

sub _list_nsort {
    my ($list, @fields) = @_;
    return $list unless @$list > 1;     # no need to sort 1 item lists
    return [ 
        @fields                         # Schwartzian Transform 
        ?  map  { $_->[0] }             # for case insensitivity
           sort { $a->[1] <=> $b->[1] }
           map  { [ $_, _list_sort_make_key($_, \@fields) ] }
           @$list 
        :  map  { $_->[0] }
           sort { $a->[1] <=> $b->[1] }
           map  { [ $_, lc $_ ] } 
           @$list,
    ];
}

sub _list_unique {
    my %u; 
    [ grep { ++$u{$_} == 1 } @{$_[0]} ];
}

sub _list_import {
    my $list = shift;
    push(@$list, grep defined, map ref eq 'ARRAY' ? @$_ : undef, @_);
    return $list;
}

sub _list_merge {
    my $list = shift;
    return [ @$list, grep defined, map ref eq 'ARRAY' ? @$_ : undef, @_ ];
}

sub _list_slice {
    my ($list, $from, $to) = @_;
    $from ||= 0;
    $to    = $#$list unless defined $to;
    $from += @$list if $from < 0;
    $to   += @$list if $to   < 0;
    return [ @$list[$from..$to] ];
}

sub _list_splice {
    my ($list, $offset, $length, @replace) = @_;
    if (@replace) {
        # @replace can contain a list of multiple replace items, or 
        # be a single reference to a list
        @replace = @{ $replace[0] }
        if @replace == 1 && ref $replace[0] eq 'ARRAY';
        return [ splice @$list, $offset, $length, @replace ];
    }
    elsif (defined $length) {
        return [ splice @$list, $offset, $length ];
    }
    elsif (defined $offset) {
        return [ splice @$list, $offset ];
    }
    else {
        return [ splice(@$list) ];
    }
}

sub _xml_filter {
    my $text = shift;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
        s/'/&apos;/g;
    }
    return $text;
}

sub _html_paragraph  {
    my $text = shift;
    return "<p>\n" 
           . join("\n</p>\n\n<p>\n", split(/(?:\r?\n){2,}/, Text::Xslate::Util::html_escape($text)))
           . "</p>\n";
}

sub _html_para_break  {
    my $text = shift;
    $text = Text::Xslate::Util::html_escape($text);
    $text =~ s|(\r?\n){2,}|$1<br />$1<br />$1|g;
    return $text;
}

sub _html_line_break  {
    my $text = shift;
    $text = Text::Xslate::Util::html_escape($text);
    $text =~ s|(\r?\n)|<br />$1|g;
    return $text;
}

sub _indent_filter_factory {
    my ($pad) = @_;
    $pad = 4 unless defined $pad;
    $pad = ' ' x $pad if $pad =~ /^\d+$/;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        $text =~ s/^/$pad/mg;
        return $text;
    }
}

sub _format_filter_factory {
    my ($format) = @_;
    $format = '%s' unless defined $format;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        return join("\n", map{ sprintf($format, $_) } split(/\n/, $text));
    }
}

sub _truncate_filter_factory {
    my ($len, $char) = @_;
    $len  = $TRUNCATE_LENGTH unless defined $len;
    $char = $TRUNCATE_ADDON  unless defined $char;

    # Length of char is the minimum length
    my $lchar = length $char;
    if ($len < $lchar) {
        $char  = substr($char, 0, $len);
        $lchar = $len;
    }

    return sub {
        my $text = shift;
        return $text if length $text <= $len;
        return substr($text, 0, $len - $lchar) . $char;
    }
}

sub _repeat_filter_factory {
    my ($iter) = @_;
    $iter = 1 unless defined $iter and length $iter;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        return join('\n', $text) x $iter;
    }
}

sub _replace_filter_factory {
    my ($search, $replace) = @_;
    $search = '' unless defined $search;
    $replace = '' unless defined $replace;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        $text =~ s/$search/$replace/g;
        return $text;
    }
}

sub _remove_filter_factory {
    my ($search) = @_;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        $text =~ s/$search//g;
        return $text;
    }
}

1;
