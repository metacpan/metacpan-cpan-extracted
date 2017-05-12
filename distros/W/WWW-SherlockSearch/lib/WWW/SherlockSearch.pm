# $File: //member/autrijus/WWW-SherlockSearch/lib/WWW/SherlockSearch.pm $ $Author: autrijus $
# $Revision: #32 $ $Change: 10623 $ $DateTime: 2004/05/22 08:07:29 $ vim: expandtab shiftwidth=4

package WWW::SherlockSearch;
$WWW::SherlockSearch::VERSION = '0.20';

use strict;
use vars qw($ExcerptLength $UAClass);

use HTTP::Cookies;
use HTTP::Request::Common;
use WWW::SherlockSearch::Results;

$ExcerptLength = 100;
$UAClass = 'LWP::RobotUA';

=head1 NAME

WWW::SherlockSearch - Parse and execute Apple Sherlock 2 plugins

=head1 VERSION

This document describes version 0.20 of WWW::SherlockSearch, released
May 22, 2004.

=head1 SYNOPSIS

    use WWW::SherlockSearch;

    my $sherlock = WWW::SherlockSearch->new('google.src');

    my $text = $sherlock->asString;
    my $rss  = $sherlock->asRssString;
    my $src  = $sherlock->asSherlockString;

    # fiind 'test' with limit '10'
    my $results = $sherlock->find("test", 10);

    my $text = $results->asString;
    my $rss  = $results->asRssString;
    my $html = $results->asHtmlString;

=head1 DESCRIPTION

This module parses and executes Apple Sherlock 2 plugin files,
and generate a result set that can be expressed in text, HTML
or RSS format.  It is a repackaged and cleaned-up version of
Damian Steer's B<Sherch> service at L<http://www.sherch.com/>.

The module differ from other Sherlock implementation in that
it can actually follow the individual links and extract the
full text within it, delimited by the C<resultContentStart>
and C<resultContentEnd> tags.  In RSS, they will be expressed
via the C<content:encoded> attribute proposed by Aaron.

If there is no I<description> but I<content> is available, the
C<$WWW::SherlockSearch::ExcerptLength> variable is used to
determine how many leading characters to use to generate the
description from content (defaults to C<100>).  Setting it to
C<0> disables this feature.

Please see L<http://mycroft.mozdev.org/> for a repository and
detailed description of Sherlock 2 plugins.

=cut

sub import {
    my $class = shift;
    $UAClass = shift if @_;
}

sub new {
    my $type = shift;
    my $self = {};
    bless($self, $type);
    $self->loadFile(shift) if @_;
    return $self;
}

sub getChannelUrl {
    my $self = shift;
    return $self->{channelUrl};
}

sub setChannelUrl {
    my $self = shift;
    $self->{channelUrl} = shift;
    return $self;
}

sub getQueryAttr {
    my $self = shift;
    return $self->{queryAttr};
}

sub setQueryAttr {
    my $self = shift;
    $self->{queryAttr} = shift;
    return $self;
}

sub getPictureUrl {
    my $self = shift;
    return $self->{pictureUrl};
}

sub setPictureUrl {
    my $self = shift;
    $self->{pictureUrl} = shift;
    return $self;
}

sub loadFile {
    my $self = shift;
    my $filename = shift or return;

    if (UNIVERSAL::isa($filename, 'SCALAR')) {
        $self->initialiseSearch($$filename);
    }
    else {
        local $/;
        open(SHERFILE, $filename) or die "Couldn't open $filename: $!";
        $self->initialiseSearch(<SHERFILE>);
        close SHERFILE;
    }

    return $self;
}

sub initialiseSearch {
    my ($self, $content) = @_;
    my ($action, $basehref, $host);

    if ($content) {
        @{$self}{qw{
            search interpretList inputList
            prefetch preinputList postfetch postinputList
        }} = parseSherlock(\$content);
    }

    $action = $self->{search}{action} or return;

    ($basehref) = ($action =~ /(.*\/)/);
    ($host)     = ($action =~ /(.*\/\/.*?)\//);

    $self->{basehref} = $basehref;
    $self->{host}     = $host;

    return $self;
}

# The following parses sherlock .src files

# This takes a sherlock file, strips the comments, then passes the
# individual tags for further parsing.

my %Attr = (
    search      => [qw{
	name method action update updateCheckDays
	description bannerImage bannerLink routeType
        queryEncoding queryCharset queryLimit
    }],
    input       => [qw{
	value name user user1 user2 user3 usern prefix suffix mode
    }],
    interpret   => [qw{
	bannerStart bannerEnd relevanceStart relevanceEnd
	resultListStart resultListEnd resultItemStart resultItemEnd
	priceStart priceEnd availStart availEnd dateStart dateEnd
	nameStart nameEnd emailStart emailEnd
        pageNextStart pageNextEnd
	resultItemFind resultItemReplace
	resultContentStart resultContentEnd
    }],
);

sub parseSherlock {
    my $sherfiletoparse     = shift;

    # XXX: inputprev, inputnext?
    my $tags                = join('|', qw{
	search interpret input prefetch postfetch
	/search /prefetch /postfetch
    });
    my $searchAttributes    = join('|', map lc, @{$Attr{search}});
    my $inputAttributes     = join('|', map lc, @{$Attr{input}});
    my $interpretAttributes = join('|', map lc, @{$Attr{interpret}});

    my ($search, $prefetch, $postfetch, $interpret, $input);
    my $interpretList = [];
    my $inputList     = [];
    my $preinputList  = [];
    my $postinputList = [];
    my ($tag, $current_tag);

    $$sherfiletoparse =~ s/\r/\n/g;    # fix line endings
    $$sherfiletoparse =~ s/(?:\s+|^)\#(?:\s+$).*//g;    # remove comment lines

  PARSELOOP:
    while ($$sherfiletoparse =~ /<\s*($tags)/gcis) {
	$tag = $1;
	$tag =~ tr/A-Z/a-z/;

	if ($tag eq 'search') {
	    $search = parseAttValString($sherfiletoparse, $searchAttributes);
	    $current_tag = 'search';
	}
	elsif ($tag eq 'prefetch') {
	    $prefetch =
	      parseAttValString($sherfiletoparse, $searchAttributes);
	    $current_tag = 'prefetch';
	}
	elsif ($tag eq 'postfetch') {
	    $postfetch =
	      parseAttValString($sherfiletoparse, $searchAttributes);
	    $current_tag = 'postfetch';
	}
	elsif ($tag eq 'interpret') {
	    $interpret =
	      parseAttValString($sherfiletoparse, $interpretAttributes);
	    push (@{$interpretList}, $interpret);
	}
	elsif ($tag eq 'input') {
	    $input = parseAttValString($sherfiletoparse, $inputAttributes);
	    if ($current_tag eq "prefetch") {
		push (@{$preinputList}, $input);
	    }
	    elsif ($current_tag eq "postfetch") {
		push (@{$postinputList}, $input);
	    }
	    else {
		push (@{$inputList}, $input);
	    }
	}
	elsif ($tag eq '/prefetch') {
	    $current_tag = '';
	}
	elsif ($tag eq '/postfetch') {
	    $current_tag = '';
	}
	elsif ($tag eq '/search') {
	    last PARSELOOP;
	}
    }
    return ($search, $interpretList, $inputList, $prefetch, $preinputList,
	$postfetch, $postinputList);
}

# This parses a string containg items of the form attribute = string
# or just attribute and returns a hash of attribute=>value.
# For lone attributes value = 'true'.
# $parse is of the form "attr|attr|attr|...|attr"

sub parseAttValString {
    my $stringtoparse = shift;
    my $attrList      = shift;

    my ($value, $attribute);
    my $returnHash = {};

  PARSELOOP2:
    while ($$stringtoparse =~ /($attrList)\s*(=| |>)\s*/gcis) {
	$attribute = $1;
	$attribute =~ tr/A-Z/a-z/;    # lowercase to make my life easy
	if ($2 eq '=') {
	    $value = parseString($stringtoparse);
	}
	else { $value = 'true'; }
	$returnHash->{$attribute} = $value;
	if (($2 eq '>') or ($$stringtoparse =~ /\G\s*>/gcs)) {
	    last PARSELOOP2;
	}
    }
    return $returnHash;
}

# This takes a string of the form "....", '.....',
# or just ..... (no whitespace)
# And returns the ..... bit.

sub parseString {
    my $string = shift;
    my $content;
    my $skip = 2;

    if ($$string =~ /\G\"/gcs) {
	$content = $1 if ($$string =~ /\G(.*?[^\\])\"/gcs);
	$content =~ s{\\"}{"}g;
    }
    elsif ($$string =~ /\G\'/gcs) {
	$content = $1 if ($$string =~ /\G(.*?[^\\])\'/gcs);
	$content =~ s{\\'}{'}g;
    }
    else {
	$content = $1 if ($$string =~ /\G(\S+)/gcs);
	if ($content =~ s/>$//)    # this removes a closing tag (if present)
	{
	    pos($$string)--;       # this corrects for that removal
	}
    }
    return $content;
}

sub printHash {
    my $hashRef = shift;
    my $tab     = shift;

    my $key;

    foreach $key (keys %$hashRef) {
	print "$tab$key := ", $hashRef->{$key}, "\n";
    }
}

sub find {
    my ($self, $query, $limit, $skip_href) = @_;

    my $ua_pm = "$UAClass.pm";
    $ua_pm =~ s{::}{/}g;
    require $ua_pm;
    
    my $search = $UAClass->new(
        'Mozilla/5.0 Gecko/libwww-perl', 'autrijus@cpan.org',
    );
    my ($result, @post, $get, $rv);

    $search->cookie_jar(HTTP::Cookies->new);

    foreach my $stage (qw/prefetch search postfetch/) {
	next unless $self->{$stage}{method} and $self->{$stage}{action};

        my $find = _encode(
            $self->{$stage}{querycharset} || $self->{$stage}{queryencoding},
            $query,
        );

	if ($self->{$stage}->{method} =~ /post/i) {
	    @post = $self->getPostData($stage, $find);
	    $result = $search->request(POST $self->{$stage}->{action}, \@post);
	}
	elsif ($self->{$stage}->{method} =~ /get/i) {
	    $get = $self->getGetData($stage, $find);
	    $get = '' if $get eq '?';
	    $result = $search->request(GET $self->{$stage}->{action} . $get);
	}
	else {
	    die "Unknown method: $stage / $self->{$stage}->{method}";
	}

	next unless $stage eq 'search';
        
        while ($result) {
            if (!$result->is_success) {
                print "$stage / $self->{$stage}->{method}: Warn: " .
                    $result->code . " " . $result->message;
                last;
            }

            $self->{content} = _decode(
                $self->{$stage}{querycharset} || $self->{$stage}{queryencoding},
                $result->content,
            );

            ($rv, $result) = $self->convertResults(
                $self->{content}, $search, $limit, $skip_href, $result->date, $rv
            );
        }
    }

    return $rv;
}

sub _encode {
    my $charset = shift || 'utf8';
    require Encode::compat if $] < 5.007001; require Encode;
    return Encode::encode($charset, $_[0]);
}

sub _decode {
    my $charset = shift || 'utf8';
    require Encode::compat if $] < 5.007001; require Encode;
    return Encode::decode($charset, $_[0]);
}

sub getPostData {
    my ($self, $tag, $find) = @_;
    my (@post, $item);
    my $list;

    if ($tag eq 'prefetch') {
	$list = 'preinputList';
    }
    elsif ($tag eq 'postfetch') {
	$list = 'postinputList';
    }
    else {
	$list = 'inputList';
    }

    foreach $item (@{ $self->{$list} }) {
	if ($item->{user}) {
	    push (@post, $item->{name}, $find);
	}
	elsif ($item->{mode} ne 'browser') {
	    push (@post, $item->{name}, $item->{value});
	}
    }
    return @post;
}

sub getGetData {
    my ($self, $tag, $find) = @_;
    my ($get, $item, $amp);
    my $list;

    if ($tag eq 'prefetch') {
	$list = 'preinputList';
    }
    elsif ($tag eq 'postfetch') {
	$list = 'postinputList';
    }
    else {
	$list = 'inputList';
    }

    $get = "?";
    $amp = "";
    foreach $item (@{ $self->{$list} }) {
	if ($item->{user}) {
	    $get .= $amp . $item->{name} . "=" . $find;
	    $amp = "&";
	}
	elsif ($item->{mode} ne 'browser') {
	    $get .= $amp . $item->{name} . "=" . $item->{value};
	    $amp = "&";
	}
    }
    return $get;
}

# The following methods are used to interpret results

sub convertResults {
    my ($self, $html, $search, $limit, $skip_href, $result_date, $resultStruct) = @_;
    $limit ||= $self->{search}{querylimit};

    # It appears plugins can have more than one interpet tag
    # I only use the first
    my $interpret = $self->{interpretList}->[0];
    my ($banner, @results, $bannerimageurl, $bannerurl, $pagenexturl);

    if (!$resultStruct) {
        $resultStruct = WWW::SherlockSearch::Results->new;
        $resultStruct->setServiceName($self->{search}{name});
        $resultStruct->setServiceDescription($self->{search}{description});
        $resultStruct->setBaseHREF($self->{basehref});
        $resultStruct->setHost($self->{host});
        $resultStruct->setPictureUrl($self->getPictureUrl);
        $resultStruct->setChannelUrl(
            $self->getChannelUrl ||
            ($self->{search}{action} . $self->getGetData)
        );
        $resultStruct->setQueryAttr($self->getQueryAttr);
    }

    # get that banner
    if ($interpret->{bannerstart}) {
	($banner) = getDelimited(
	    \$html,
	    $interpret->{bannerstart},
	    $interpret->{bannerend}
	);
	($bannerimageurl) = $self->getIMG($banner);
	($bannerurl)      = $self->getHREF($banner);
	$resultStruct->setBannerImage($bannerimageurl);
	$resultStruct->setBannerLink($bannerurl);
    }
    else {
	$resultStruct->setBannerLink(
	    $self->fixRef($self->{search}{bannerlink}));
	$bannerimageurl = $self->getIMG($self->{search}{bannerimage});
	if (!$bannerimageurl) {
	    $bannerimageurl = $self->fixRef($self->{search}{bannerimage});
	}
	$resultStruct->setBannerImage($bannerimageurl);
    }

    if ($interpret->{pagenextstart}) {
	($pagenexturl) = getDelimited(
	    \$html,
	    $interpret->{pagenextstart},
	    $interpret->{pagenextend}
	);
	($pagenexturl) = $self->getHREF($pagenexturl);
    }

    if ($interpret->{resultliststart}) {
	($html) = getDelimited(
	    \$html,
	    $interpret->{resultliststart},
	    $interpret->{resultlistend}
	);
    }
    if ($interpret->{resultitemstart}) {
	@results = getDelimited(
	    \$html,
	    $interpret->{resultitemstart},
	    $interpret->{resultitemend}
	);
    }
    else {
	@results = ($html =~ /(<\s*A[^>]+HREF\s*=.*?(?:<\/A>|$))/sgi);
    }

    # Find-and-Replace
    # Thanks for mtve @ #perl for this.
    if (length $interpret->{resultitemfind}) {
        my $find = $interpret->{resultitemfind};
        $find =~ s|\\Q(.*?)\\E|quotemeta($1)|eg;

	foreach (@results) {
	    s{$find}{"qq($interpret->{resultitemreplace})"}ees;
	}
    }

    my ($item, $temp, $relev, $itemurl, $content, $rest, $fulltext, $date);

    foreach $item (@results) {
	require HTML::Entities;
	$item =~ s/&nbsp;/ /g;    # :-(~~~
	HTML::Entities::decode_entities($item);

	if ($interpret->{relevancestart}) {
	    ($temp) = getDelimited(
		\$item,
		$interpret->{relevancestart},
		$interpret->{relevanceend}
	    );
	    ($relev) = ($temp =~ /(\d+)/s);
	}
	($itemurl, $content, $rest) = $self->getHREF($item);

	if ($interpret->{namestart}) {
	    ($temp) = getDelimited(\$item, $interpret->{namestart},
		$interpret->{nameend});
	    $content = $temp if $temp;
	}

	if ($interpret->{datestart}) {
	    ($temp) = getDelimited(\$item, $interpret->{datestart},
		$interpret->{dateend});
	    $date = $temp if $temp;
	}

	# The following strips tags, $content, line endings and relevance
	# in the hope that removing this garbage will leave a nice summary

	stripTags(\$content);

	next if $content =~ /^\s*$/;

	$rest = $content unless ($rest);

	stripTags(\$rest);
	$rest =~ s/$relev\%?//g if $relev;
        next if $skip_href and exists $skip_href->{$itemurl};

	if ($interpret->{resultcontentstart}) {
	    my $result = $search->request(GET $itemurl);

	    if ($result->is_success) {
		my $item = _decode(
		    $self->{search}{querycharset} || $self->{search}{queryencoding},
                    $result->content,
		);

		($fulltext) = getDelimited(
		    \$item,
		    $interpret->{resultcontentstart},
		    $interpret->{resultcontentend}
		);

                require HTML::Entities;
                $fulltext =~ s/<[bB][rR]\b([^>]*)>/\n/gs;
                $fulltext =~ s/&nbsp;/ /g;    # :-(~~~
                HTML::Entities::decode_entities($fulltext);

                stripTags(\$fulltext);
                $date ||= $result->date;
	    }
	}

	$resultStruct->add(
            $itemurl, $content, $relev, $rest, $fulltext, $date || $result_date
        );

        if ($limit and $resultStruct->getNumResults >= $limit) {
            $pagenexturl = ''; # no next page, please
            last;
        }
    }

    $self->{resultArray} = $resultStruct;

    return (
        $resultStruct,
        $pagenexturl ? ($search->request(GET $pagenexturl)) : ()
    );
}

sub stripTags {
    my $var = shift;
    $$var =~ s/<[bB][rR]\b([^>]*)>/\n/gs;
    $$var =~ s/<([^>]+)(?:>|$)//gs;
    $$var =~ s/^\s*//;
    $$var =~ s/\s*$//;
    $$var =~ s/\s+/ /g;
}

sub getHREF {
    my ($self, $html) = @_;
    my ($itemurl, $content, $rest) =
      ($html =~ /<\s*A[^>]+HREF\s*=\s*(.*?)>(.*?)(?:<\/A>|$)(.*)/si);
    ($itemurl) = ($itemurl =~ /^\'?\"?(\S+)/);
    $itemurl =~ s/\'?\"?$//;
    $itemurl = $self->fixRef($itemurl);
    return ($itemurl, $content, $rest);
}

sub getIMG {
    my ($self, $html) = @_;
    my ($itemurl) = ($html =~ /<\s*IMG\s+SRC\s*=\s*(.*?)>/si);
    ($itemurl) = ($itemurl =~ /^\'?\"?(\S+)/);
    $itemurl =~ s/\'?\"?$//;
    $itemurl = $self->fixRef($itemurl);
    return $itemurl;
}

sub fixRef {
    my ($self, $url) = @_;
    my ($basehref, $host);
    if (!$url) { return; }
    $basehref = $self->{basehref};
    $host     = $self->{host};

    # This doesn't work for relative links :-(
    if ($url !~ m{^(?:\w+:)?//}) {
	$url = ($url =~ m{^/}) ? $host . $url : $basehref . $url;
    }
    if ($url =~ m{^//} and $basehref =~ m{^(\w+:)}) {
        $url = $1 . $url;
    }
    return $url;
}

sub getResults {
    my $self = shift;
    return $self->{resultArray};
}

sub getDelimited {
    my ($list, $left, $right) = @_;
    my @results;

    @results = ($$list =~ /\Q$left\E(.*?)\Q$right\E/gis);

    return @results;
}

sub asString {
    my $self   = shift;
    my $string = "Search :\n\n";

    $string .= "Base Href := " . $self->{basehref} . "\n";
    $string .= "Host := " . $self->{host} . "\n";
    foreach my $key (keys %{ $self->{search} }) {
	$string .= "$key := " . $self->{search}{$key} . "\n";
    }

    $string .= "\nInterpret :\n\n";

    foreach my $key (keys %{ $self->{interpretList}->[0] }) {
	$string .= "$key := " . $self->{interpretList}->[0]->{$key} . "\n";
    }

    foreach my $hash (@{ $self->{inputList} }) {
	$string .= "\nInput :\n";
	foreach my $key (keys %{$hash}) {
	    $string .= "\t$key := " . $hash->{$key} . "\n";
	}
    }
    return $string;
}

sub _fmt {
    my ($tag, $attr) = @_;

    return '' unless UNIVERSAL::isa($attr, 'HASH') and %$attr;

    my $rv = "<\U$tag\E\n";
    $tag = 'search' if $tag =~ /^(?:pre|post)fetch$/;

    foreach my $key (sort keys %$attr) {
        my $val = $attr->{$key};
        ($key) = grep {lc($_) eq lc($key)} @{$Attr{$tag}} or next;
        $val =~ s/"/\\"/g;
        $rv .= qq(\t$key="$val"\n) if length $val;
    }

    return "$rv>\n";
}

sub asSherlockString {
    my $self   = shift;
    my $string = '';

    foreach my $stage ( qw(prefetch postfetch search) ) {
        $string .= _fmt($stage => $self->{$stage})
            if length $self->{$stage}{action};

        $stage =~ /^(.*?)(?:fetch)?(?:search)?$/ or next;

        foreach my $list (@{$self->{"$1inputList"}}) {
            $string .= _fmt(input => $list);
        }

        if ($stage eq 'search') {
            foreach my $list (@{$self->{interpretList}}) {
                $string .= _fmt(interpret => $list);
            }
        }

        $string .= "</\U$stage\E>\n\n"
            if $self->{$stage} and %{$self->{$stage}}
                and length $self->{$stage}{action};
    }

    return $string;
}

sub asRssString {
    my $self = shift;

    require XML::RSS;
    my $rss = XML::RSS->(version => '1.0');

    $rss->channel(
	title       => fixEm($self->{search}{name}),
	link        => fixEm($self->getChannelUrl),
	description => fixEm($self->{search}{description})
    );

    $rss->image(
	title => fixEm($self->{search}{name}),
	url   => fixEm($self->getPictureUrl),
	link  => fixEm($self->{host})
    );

    $rss->textinput(
	title       => fixEm($self->{search}{name}),
	description => "Search this site",
	name        => fixEm($self->getQueryAttr),
	link        => fixEm($self->getChannelUrl)
    );

    return $rss->as_string;
}

# This is a cludge to fix xml problems
# - bah, thought XML::RSS would do this

sub fixEm {
    my $text = shift;

    $text =~ s/&/&amp;/gs;
    $text =~ s/</&lt;/gs;
    $text =~ s/>/&gt;/gs;
    return $text;
}

sub resultsAsRssString {
    my $self    = shift;
    my $results = $self->getResults;
    return $results->asRssString;
}

sub resultsAsString {
    my $self    = shift;
    my $results = $self->getResults;
    return $results->asString;
}

sub resultsAsHtmlString {
    my $self    = shift;
    my $results = $self->getResults;
    return $results->asHtmlString;
}

1;

=head1 SEE ALSO

L<sherch>

L<LWP>, L<XML::RSS>

=head1 AUTHORS

=over 4

=item *

Damian Steer E<lt>D.M.Steer@lse.ac.ukE<gt>

=item *

Kang-min Liu E<lt>gugod@gugod.org<gt>

=item *

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 1999, 2000, 2001 by Damian Steer.

Copyright 2002, 2003 by Kang-min Liu.

Copyright 2002, 2003, 2004 by Autrijus Tang.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
