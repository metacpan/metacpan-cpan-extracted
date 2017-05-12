package XML::Lenient;
use strict;
use warnings;
use Moo;
use Method::Signatures;

our $VERSION = '1.0.1'; #See www.semver.org

has verbatim => (
    is      => 'rw',
    default => sub{['applet',
                    'code',
                    'pre',
                    'script']},
);

has tagl => (
    is      => 'rw',
    default => '<',
);

has tagr => (
    is      => 'rw',
    default => '>',
);

has tagc => (
    is      => 'rw',
    default => '/',
);

method within($full, $tag, $n = 1) {
    if (!defined $tag or 0 == length($tag)) {
        return '';
    } else {
        my @vtagged;
        $self->_stripverbatim(\@vtagged, \$full);
        my $left = $self->{tagl} . $tag . '[ ' . $self->{tagr} . ']';
        my $count = () = $full =~ /$left/g if defined $full;
        my $wanted = '';
        _tidyindex(\$n);
        my @stack;
        $self->_buildstack(\@stack, $full, $tag);
        if ($n <= $#stack) {
            $wanted = substr($full, $stack[$n][0], $stack[$n][1] - $stack[$n][0]) if scalar @stack;
            $self->_restoreverbatim(\@vtagged, \$wanted);
        }
        return $wanted;
    }
}

func _tidyindex($refn) {
        $$refn =~ s/[^-0-9]//g if defined $$refn;
        $$refn = 1 unless defined $$refn;
        $$refn = 1 if 0 == length($$refn);
        my $right = substr($$refn, 1);
        $right =~ s/-//g;
        $$refn = substr($$refn, 0, 1) . $right;
        $$refn-- unless $$refn < 1;
}

method _buildstack($refstack, $full, $tag) {
    my $regex = '((?:' . $self->{tagl} 
                       . $self->{tagc} . '?' . $tag . ') *?.*?' 
                       . $self->{tagr} . ')';
    if (defined $full) {
        while ($full =~ m/$regex/gi) {
            if ($self->{tagl} . $self->{tagc} . $tag . $self->{tagr} eq $1) {
                for (my $idx = $#$refstack; 0 <= $idx; $idx--) {
                    if (!defined $$refstack[$idx][1]) {
                        $$refstack[$idx][1] = pos($full) - length($1);
                        last;
                    }
                }
            } else {
                push @$refstack, [pos($full), undef];
            }
        }
    }
    for my $lineref (@$refstack) {
        if (!defined $$lineref[1]) {
            $$lineref[1] = length($full);
        }
    }
}

method _restoreverbatim($refvtagged, $reftext) {
    for my $vtag(@{$self->{verbatim}}) {
        my $lv = $self->{tagl} . $vtag . $self->{tagr};
        my $rv = $self->{tagl} . $self->{tagc} . $vtag . $self->{tagr};
        my $regex = $lv . '(\d+?)' . $rv; #Should be impossible for a D to appear.
        my @local;
        if (scalar @$refvtagged and defined $$reftext) {
            @local = $$reftext =~ /$regex/g;
        }
        for my $idx (@local) {
            if (defined $$refvtagged[$idx]) {
                $regex = $lv . $idx . $rv;
                $$reftext =~ s/$regex/$$refvtagged[$idx]/;
                $$refvtagged[$idx] = undef;
            }
        }
    }
}

method _stripverbatim($refvtagged, $reffull) {
    for my $vtag(@{$self->{verbatim}}) {
        my $lv = $self->{tagl} . $vtag . '(?: |' . $self->{tagr} . ')';
        my $rv = $self->{tagl} . $self->{tagc} . $vtag . $self->{tagr};
        my $regex = $lv . '.+?' . $rv;
        my $nbase = scalar @$refvtagged;
        my @local;
        @local = $$reffull =~ /($regex)/gmsi if defined $$reffull;
        push @$refvtagged, @local;
        if (-1 < $#$refvtagged) {
            for my $n($nbase..$#$refvtagged) {
                my $rplc = $self->{tagl} . $vtag . $self->{tagr} . $n . $rv;
                $$reffull =~ s/$$refvtagged[$n]/$rplc/ms;
            }
        }
    }
}

method innertext($full) {
    if ($self->{tagl} ne substr($full, 0, length($self->{tagl}))) {
        return $full;
    } else {
        my $regex = '^' . $self->{tagl} . '(.+?)(?: |' . $self->{tagr} . ')';
        my ($tag) = $full =~ m/$regex/i;
        return $self->innertext($self->within($full, $tag));
    }
}

method tagval($full, $tag, $n = 1) {
    if (!defined $tag or 0 == length($tag)) {
        return '';
    } else {
        my @stack;
        $self->_buildstack(\@stack, $full, $tag);
        _tidyindex(\$n);
        if (defined $stack[$n][0]) {
            my $end = $stack[$n][1];
            my $ltag = $self->{tagl} . $tag . ' ';
            my $start = index($full, $ltag) + length($ltag);
            if (0 < $n) {
                my $offset = $stack[$n-1][0];
                $start = index($full, $ltag, $offset) + length($ltag);
            }
            my $subml  = substr($full, $start, $end - $start);
            my $tagval = substr($full, $start, );
            $tagval =~ s/$self->{tagr}.*$//ms;
            return $tagval;
        } else {
            return '';
        }
    }
}

method wpath($full, $path) {
    my @steps = split(/\//, $path);
    for (@steps) {
        my ($tag, $idx) = split(/\[/, $_);
        $full = $self->within($full, $tag, $idx) if defined $tag;
    }
    return $full;
}

method tagcount($full, $tag) {
    my @stack;
    $self->_buildstack(\@stack, $full, $tag);
    return scalar @stack;
}

=pod

=head1 NAME

XML::Lenient - extracts strings from HTML, XML and similarly tagged text.

=head1 SYNOPSIS

 use XML::Lenient;
 my $p = XML::Lenient->new(); #This is the same as:
 my $p = XML::Lenient->new(
     tagl => '<',
     tagr => '>',
     tagc => '/',
     verbatim => ['applet', 'code', 'pre', 'script']
 );
 my $subtext  = $p->within($ml, $tag, $index);
    $subtext  = $p->innertext($ml);
    $subtext  = $p->wpath($ml, $path);
 my $tagvalue = $p->tagval($ml, $tag, $index);
 my $count    = $p->tagcount($ml, $tag);

=head1 DESCRIPTION

=head2 What

XML::Lenient is meant to parse markup languages such as HTML and
XML in the knowledge that someone, somewhere, is going to break
every rule in the book. It will handle malformed XML, wrongly
nested HTML tags and everything else that I have thrown at it.
The results may not be what the author of the mistake expected,
but that's their headache.

=head2 Why

My original intent when writing it was to enable me to write
tests when developing code that generates HTML. I want to be
able to change any aspect of the HTML without breaking every
test previously written. I could find no way of doing this with
existing tools, so I wrote this. It is based on a module I
wrote for Excel in VBA that I use for web scraping.

=head2 How

All methods take a string and return a string (an integer in one
case). There are no complicated data structures.

=head3 The object

 my $p = XML::Lenient->new();

For most cases, the defaults will be all you need.
You could specify the version below, but it merely applies the
defaults. However, it shows how to specify the properties
should you have a need.

 my $p = XML::Lenient->new(
     tagl => '<',
     tagr => '>',
     tagc => '/',
     verbatim => ['applet', 'code', 'pre', 'script']
 );

The parser object has four properties. Three of these describe
how a tag appears.

 Property Default Meaning
 tagl     <       The leftmost character(s) of a tag
 tagr     >       The rightmost character(s) of a tag
 tagc     /       The character(s) indicating a closing tag

While the code has been written to handle multiple characters
in each delimiter, I know of no use case for this and have
written no tests. I do know that 
L<Template::Toolkit|http://search.cpan.org/~abw/Template-Toolkit-2.26/lib/Template/Toolkit.pod>
defaults to two character delimiters but cannot see a situation in
which it would constitute tag delimited text.

The fourth property is an array of "verbatim" tags. Data within
such tags will not be treated as tags. If you want to use this
parser on data within verbatim tags, create a parser object
without the verbatim tag(s) that are the problem. There is
nothing to prevent you having two parser objects with different
properties and using the right one for each task.

=head3 Indexing

Several of the methods allow an index, although this is always optional.
The L</wpath> method attempts compatibility with XPath. In consequence,
all positive indices are 1 based. However, negative indices work as in
Perl generally, meaning that zero and negative indices are zero based.
The effect of this is that there is finally a use case where 0 == 1,
which I have to admit causes me a little amusement. When working with
an index, it is the appearance of the opening tag that is counted;
nesting is ignored. If an index is given that is higher than can be found,
a zero length string will be returned. An index of zero (or undef or a
zero length string) will return the first item.

=head3 within

 $p->within($ml, $tag, $index);

within returns the text between an opening tag and a closing
tag. So:

 my $p = XML::Lenient->new();
 my $ml = '<x>asdf</x>';
 my $within = $p->within($ml, 'x');
 ok ('asdf' eq $within, "Simple within works");

The index is optional and defaults to 1. See L</Indexing> for more
information. So:

 $ml = '<x><x><x>asdf</x></x></x><x>qwer</x>';
 $within = $p->within($ml, 'x', 2);
 ok ('<x>asdf</x>' eq $within, "Indexing works with nested tags");

Zero and negative indices work in the same was as in Perl generally.
Again, see L</Indexing> for more information. So:

 $ml = '<x><x><x>asdf</x></x></x><x>qwer</x>';
 $within = $p->within($ml, 'x', 0);
 ok ('<x><x>asdf</x></x>' eq $within, 
   "Zero index is the first element");
 $within = $p->within($ml, 'x', -1);
 ok ('qwer' eq $within, 
   "Negative index works as in Perl");
 $within = $p->within($ml, 'x', -2);
 ok ('asdf' eq $within, 
   "Negative indices continue working backwards");

Extraneous tags are ignored whether they are matched properly:

 $ml = '<x><y><z>asdf</z></y></x>';
 $within = $p->within($ml, 'z');
 ok ('asdf' eq $within, 'Outer non-target tags ignored');

or mismatched:

 $ml = '<x><y>asdf</x></y>';
 $within = $p->within($ml, 'x');
 ok ('<y>asdf' eq $within, "Mismatched tags return something sensible");
 $within = $p->within($ml, 'y');
 ok ('asdf</x>' eq $within, 
   "Mismatched tags return something sensible again");

An unclosed tag is considered to be closed implicitly at the end
of the data. With nested unmatched tags, the closing tag(s) are
allocated to the innermost open tag first. So:

 $ml = '<x><x>asdf</x>';
 $within = $p->within($ml, 'x');
 ok ('<x>asdf</x>' eq $within, "Handles unclosed tags");

=head3 wpath

 $subtext = $p->wpath($ml, $path);

This is a wrapper around within that allows a path to be
specified in XPath format. A valid XPath that uses no
indexing is always a valid wpath. But wpath is far more lenient
and will accept the omission of any step in the path that is
not required to identify the wanted text. Indeed, wpath will be
faster if such steps are omitted. So, with 80 lines of HTML I
sha'n't repeat here:

 my $text = $p->wpath($ml, 
   '/html/body/div/div/div/table[1]/tbody/tr[2]/td[2]');
 ok('17' eq $text, "Full xpath works");
 $text = $p->wpath($ml, 'tbody/tr[2]/td[2]');
 ok('17' eq $text, "Abbreviated wpath works");

Both variants work with the second being faster. If you know
there are no <tr> tags in the table header (there are in the
test HTML), the tbody could be omitted, too. Since each step
in a path is split using the '[' character and non-numeric
characters deleted, it is perfectly acceptable in a wpath to
omit the closing ']'. Indeed, the lenient approach means you
can do some spectacularly improper things to the wpath and it
will still work. Just don't tell anyone I advised it.

An XPath that uses an index will differ from a wpath if and
only if the tag is repeated both at the same nesting level
and at a deeper nesting level before the tag that XPath would
select. So:

 my $ml = '<x><x>asdf</x></x><x>qwer</x>';
 
Using x[2], XPath would return qwer while wpath would return
asdf.

=head3 tagval

 $p->tagval($ml, $tag, $index);

I have never needed this, but I can envisage doing so. tagval
returns the attributes inside a tag as opposed to the data
between an opening and closing tag. So:

 my $ml = '<a href="www.example.com">Click</a>';
 my $val = $p->tagval($ml, 'a');
 ok ('href="www.example.com"' eq $val, 'Simple tagval works');
 $within = $p->within($ml, 'a');
 ok ('Click' eq $within, "Within tags with values works");

As usual, the index is optional and defaults to 1.

=head3 innertext

 $p->innertext($ml);

This is something I need when scraping web pages that change
their format without warning. Provided I have some pointers
to the data, innertext will return the text from within any
tags it may find, starting at the first non-tag character. So:

 $ml = '<x><x><x><x>asdf</x></x></x></x>';
 $inner = $p->innertext($ml);
 ok('asdf' eq $inner, 'Tags 4 deep works');
 $ml = '<x>asdf<x><x><x>asdf</x></x></x></x>';
 $inner = $p->innertext($ml);
 ok('asdf<x><x><x>asdf</x></x></x>' eq $inner,
      'Deep tags returned after text starts');

Provided there is no text between the leading tags, mismatched
tags will not cause problems:

 $ml = '<x><y>asdf</x></y>';
 $inner = $p->innertext($ml);
 ok('asdf' eq $inner, 'Magic happens to mismatched tags');

=head3 tagcount

 my $count = $p->tagcount($ml, $tag);

Returns the number of opening target tags in $ml or zero if it
doesn't exist. This is the exception that returns an integer
rather than a string.

 my $ml = '<div><div><div><div>asdf</div></div></div></div>';
 my $n = $p->tagcount($ml, 'div');
 ok (4 == $n, 'Correct number of div tags');
 $n = $p->tagcount($ml, 'x');
 ok (0 == $n, 'Correct number of x tags');

=head1 LIMITATIONS

XML::Lenient cannot handle more text than will fit in memory.

Tags cannot be split over more than one line (but having
the opening and closing tags on different lines is fine). If
you have split tags, a possible workaround is to change
carriage returns and line feeds to spaces before passing the
string to the parser.

Neither YAML nor JSON can be handled.

Internally, XML::Lenient uses lots of regexes (and other things as
well. I know regexes alone aren't enough). I have NOT tried to
prevent users from writing regex-style elements in tags, but I
dread to think what will happen if someone tries. By all means
try, though. And may your God go with you.

=head1 PRESENTATION VIDEO

I presented this to the London Perl Mongers on 2016-04-21.
There is a YouTube video at L<https://www.youtube.com/watch?v=3d_pkd4OkHQ&index=6&list=PL9L8-lcxZ4z0yP0jRd_7HCygBblDbXNO5>.

=head1 AUTHOR

John Davies

=head1 MODULES USED

L<Moo|http://search.cpan.org/~haarg/Moo-2.001001/lib/Moo.pm>

L<Method::Signatures|http://search.cpan.org/~barefoot/Method-Signatures-20160315/lib/Method/Signatures.pm>

=head1 SEE ALSO

I tried - and had problems with - several modules. I may be
the problem. But I tried:

L<HTML::Parser|http://search.cpan.org/dist/HTML-Parser/Parser.pm>

L<HTML::TreeBuilder|http://search.cpan.org/~cjm/HTML-Tree-5.03/lib/HTML/TreeBuilder.pm>

L<HTML::Element|http://search.cpan.org/~cjm/HTML-Tree-5.03/lib/HTML/Element.pm>

L<XML::XPath|http://search.cpan.org/~msergeant/XML-XPath-1.13/XPath.pm>

L<XML::LibXML|http://search.cpan.org/dist/XML-LibXML/LibXML.pod>

and they may be better for you than this.

=head1 VERSION

1.0.1. See L<http://www.semver.org>.

=head1 COPYRIGHT

Copyright (c) 2016, John Davies. All rights reserved.

=head1 LICENCE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;