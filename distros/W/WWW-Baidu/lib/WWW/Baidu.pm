package WWW::Baidu;

use 5.008001;
use strict;
use warnings;

use WWW::Mechanize::Cached;
use HTML::TreeBuilder;
#use YAML::Syck;
use Encode qw/ encode decode /;
use WWW::Baidu::Record;
use Carp 'croak';
use utf8;

our $VERSION = '0.06';

our $Debug = 1;

sub new ($@) {
    my $class = ref $_[0] ? ref shift : shift;
    my $cache;
    if (@_ == 1 and ref $_[0]) { # for backward-compatibility
        $cache = shift;
    } else {
        my %opts = @_;
        $cache = delete $opts{cache};
        if (%opts) {
            croak "WWW::Baid::new: Unknown options ", join(' ', keys %opts);
        }
    }
    bless {
        current => 0,
        limit   => undef,
        agent   => WWW::Mechanize::Cached->new( autocheck => 1, cache => $cache ),
        records => [],
    }, $class;
}

sub limit ($$) {
    my ($self, $count) = @_;
    $self->{limit} = $count;
}

sub search ($@) {
    my $self = shift;
    my $keys = join ' ', @_;
    $self->{current} = 0;
    $self->{records} = [];
    my $agent = $self->{agent};
    $agent->env_proxy();
    $agent->get('http://www.baidu.com');
    if (!$agent->forms or !scalar @{$agent->forms}) {
        die "Can't find forms in the baidu home page";
    }
    $agent->field( wd => _($keys) );
    $agent->submit();
    my $content = $agent->content;
    my $pat = _('百度一下，找到相关网页.*?(\d+(?:\,\d+)*)\s*篇');
    my ($count) = ($content =~ /$pat/);
    if (!defined $count) { return 0; }
    $count =~ s/,//g;
    $self->_extract_items($content);
    return $count;
}

sub next ($) {
    my $self = shift;
    my $records = $self->{records};
    my $limit = $self->{limit};
    if (defined $limit and $self->{current} >= $limit) { return undef; }
    if (my $item = shift @$records) {
        $self->{current}++;
        return $item;
    }
    $self->_goto_next_page();
    $self->{current}++;
    shift @$records;
}

sub _goto_next_page ($) {
    my ($self) = @_;
    my $i = 0;
    my $agent = $self->{agent};
    my $link = $agent->find_link( text => _('下一页') );
    if ($link) {
        #warn "found!\n" if $Debug;
        $agent->follow_link(url => $link->url);
        $self->_extract_items($agent->content);
    }
}

sub _extract_items ($$) {
    my ($self, $html) = @_;
    $html = decode('GBK', $html);
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($html);
    $tree->eof;
    my @td = $tree->look_down(
        _tag  => 'td',
        class => 'f',
    );
    #warn "!!! ", scalar(@td), " !!!\n";
    my $records = $self->{records};
    foreach my $td (@td) {
        push @$records, $self->_parse_record($td);
    }
    $tree = $tree->delete;
}

sub _parse_record ($$) {
    my ($self, $td) = @_;
    my $title_a = $td->look_down(
        _tag   => 'a',
        target => '_blank',
    );
    $title_a->detach;
    my $title = $title_a->as_text;
    my $cache_a = $td->look_down(
        _tag   => 'a',
        target => '_blank',
        sub { $_[0]->as_text =~ /百度快照/ }
    );
    if (defined $cache_a) {
        $cache_a->detach;
    }
    my $text = $td->as_text;
    if (!$cache_a and $text =~ s/^【[A-Za-z]+】//s) {
        #warn "<<<< $& >>>>>";
        $title = $& . $title;
    }
    my ($size, $date);
    if ($text =~
        s/\s+(\d+[KM])\s+(\d{4}-\d{1,2}-\d{1,2})\b//s) {
        ($size, $date) = ($1, $2);
    }
    WWW::Baidu::Record->new(
        {
            title      => _($title),
            url        => _($title_a->attr('href')),
            summary    => _($text),
            size       => _($size),
            date       => _($date),
            cached_url => $cache_a ? _($cache_a->attr('href')) : undef,
        }
    );
}

sub _ {
    my $s = shift;
    utf8::is_utf8($s) ? encode('GBK', $s) : $s;
}

1;
__END__

=head1 NAME

WWW::Baidu - Perl interface for the www.baidu.com search engine

=head1 VERSION

This document describes version 0.06 of C<WWW::Baidu>, released Jan 21, 2007.

=head1 SYNOPSIS

    use WWW::Baidu;
    my $baidu = WWW::Baidu->new;
    # ensure the keys are in the GBK/GB2312 encoding if they're Chinese
    my $count = $baidu->search('Perl "Larry Wall"', 'Audrey');
    $baidu->limit(200);
    while (my $record = $baidu->next) {
        # the results are in GBK/GB2312 encoding
        print $record->title, "\n",
              $record->url, "\n",
              $record->summary, "\n",
              $record->date, "\n",
              $record->size, "\n",
              $record->cached_url, "\n\n\n";
    }

=head1 DESCRIPTION

Baidu.com is a very popular Chinese search engine which does similar things as
Google. This module provides you with a Perl interface to that site.

=head1 METHODS

=over

=item C<< $obj = WWW::Baidu->new() >>

=item C<< $obj = WWW::Baidu->new( cache => $cache ) >>

This is the constructor for C<WWW::Baidu>. It accepts an optional argument which will must
be a L<Cache::Cache>-compatible object. C<WWW::Baidu> will use this cache instead of a default
C<Cache::FileCache> instance.

=item C<< $count = $obj->search($key1, $key2, ...) >>

Searches Baidu by the given keys and returns the total records reported by Baidu.
Note that the return value C<$count> is only an estimation by Baidu. Usually it's not equal to the
total number of records that you can fetch by the C<next> method.

It's highly recommended to pass only string keys in the GBK or GB2312 encoding.

A call of this method will clear the internal search results' buffer and the iterator counter, but
the C<limit> setting is left intact.

=item C<< $obj->limit($count) >>

Limits the total number of records WWW::Baidu will try to offer. This method will affect
the C<next()> method. And the internal counter will also get cleared if the C<search> method
is called again.

=item C<< $record = $obj->next() >>

Returns the next search result which is a L<WWW::Baidu::Record> object.
C<WWW::Baidu> accesses the baidu.com site rather lazily.
That is, it only "clicks" the "Next page" link in case that the user has fetched all the
records in the internal buffer.

When there's no more records (due to the capability of Baidu itself or the upper-limit set
via the C<limit> method), this method will return undef.

=back

=head1 CACHING

C<WWW::Baidu> uses L<WWW::Mechanize::Cached> internally so that your program will run much
faster during debugging and will also behave more politely to the Baidu.com site.

=head1 CAVEAT

=over

=item *

The values returned by the L<WWW::Baidu::Record> objects' properties are always in
the GBK (or GB2312) encoding. If you want unicode semantics, please decode the results
using the L<Encode> module yourself. :)

It's not a bug in L<WWW::Baidu>.

=item *

Althogh C<WWW::Baidu> has tried very hard to behave politely to Baidu.com via both
caching, limiting, and lazy iteration, it's still important for the user not to abuse
it.

During debugging, it's highly recommended to fix your search keys fed into the C<search>
method, so that C<WWW::Baidu> can take advantage of the caching facility and your scripts
will also run swiftly without the pain of accessing the web.

Please don't punish others' sites for your own programming mistakes. :)

=back

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below is the 
L<Devel::Cover> report on this module test suite.

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/WWW/Baidu.pm          98.1   84.6   66.7  100.0  100.0  100.0   93.9
    blib/lib/WWW/Baidu/Record.pm  100.0    n/a    n/a  100.0    n/a    0.0  100.0
    Total                          98.2   84.6   66.7  100.0  100.0  100.0   94.3
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SOURCE CONTROL

You can always get the latest source code from the following Subversion repos:

L<https://svn.openfoundry.org/wwwbaidu>

It has anonymous access to all.

If you like to get a commit bit, please let me know. I've been trying to follow
Audrey's best practices. ;)

=head1 AUTHOR

Agent Zhang E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2007 by Agent Zhang. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<WWW::Baidu::Record>, L<http://www.baidu.com>, L<WWW::Mechanize::Cached>.
