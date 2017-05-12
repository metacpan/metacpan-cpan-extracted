package Text::GooglewikiFormat;

use warnings;
use strict;
use URI;
use URI::Escape;
use Text::GooglewikiFormat::Blocks;
use Scalar::Util qw( blessed reftype );
use URI::Find;

use vars qw( $VERSION %tags $indent $code_delimiters);
$VERSION = '0.05';
$indent  = qr/^(?:\t+|\s{4,})/;
$code_delimiters = 0;
%tags    = (
	indent		=> qr/^(?:\t+|\s{1,})/,
	newline		=> '<br />',

	strong		=> sub { " <strong>$_[0]</strong> " },
	italic      => sub { " <i>$_[0]</i> " },
	strike   	=> sub { qq~ <span style="text-decoration: line-through">$_[0]</span> ~ },
	superscript => sub { "<sup>$_[0]</sup>" },
	subscript   => sub { "<sub>$_[0]</sub>" },
	inline      => sub { "<tt>$_[0]</tt>" },
	strong_tag  => qr/(^|\s+)\*(.+?)\*(\s+|$)/,
	italic_tag  => qr/(^|\s+)_(.+?)_(\s+|$)/,
	strike_tag  => qr/(^|\s+)\~\~(.+?)\~\~(\s+|$)/,
	superscript_tag => qr/\^(.+?)\^/,
	subscript_tag   => qr/\,\,(.+?)\,\,/,
	inline_tag  => qr/\`(.+?)\`/,

    header      => [ '', '', sub {
		my $level = length $_[2];
		return "<h$level>", format_line($_[3], @_[-2, -1]), "</h$level>" }
	],
	unordered   => ["<ul>", "</ul>", '<li>', " </li>"],
    ordered		=> ["<ol>", "</ol>", '<li>', " </li>"],

	code		=> [ '<pre class="prettyprint">', "</pre>", sub {
	    my ($line, $level, $args, $tags, $opts) = @_;
	    $line =~ s/(^\{\{\{|\}\}\}$)//isg;
	    return (length($line)) ? $line . "\n" : '';
	} ],
	paragraph	=> [ '<p>', "</p>", '', "<br />", 1 ],
	quote       => [ '<blockquote>', "</blockquote>", '', "\n"],
	table       => [ '<table>', '</table>', sub {
	    my ($line, $level, $args, $tags, $opts) = @_;
	    $line =~ s/(^\|\||\|\|$)//isg;
	    $line =~ s/\|\|/\<\/td\>\<td style\=\"border\: 1px solid \#aaa\; padding\: 5px\;\"\>/isg;
	    $line = qq~<tr><td style="border: 1px solid #aaa; padding: 5px;">$line</td></tr> ~;
	    return $line,
	} ],
	

	blocks		=> {
	    header      => qr/^(=+)(.+)\1/,
		ordered		=> qr/^\#\s*/,
		unordered	=> qr/^\*\s*/,
	    quote       => qr/^ /,
		paragraph   => qr/^/,
		table       => qr/^\|\|/,
	},

	indented    => { map { $_ => 1 } qw( ordered unordered )},
	nests       => { map { $_ => 1 } qw( ordered unordered code table ) },

	blockorder               =>
		[qw( header ordered unordered table quote paragraph code )],
	
	link		=> \&make_html_link,
	extended_link_delimiters => [qw( [ ] )],
	schemas => [ qw( http https ftp mailto gopher ) ],
);

sub merge_hash {
	my ($from, $to) = @_;

	while (my ($key, $value) = each %$from)
	{
		if ((reftype( $value ) || '' ) eq 'HASH' )
		{
			$to->{$key} = {} unless defined $to->{$key};
			merge_hash( $value, $to->{$key} );
			next;
		}

		$to->{$key} = $value;
	}

	return $to;
}

sub format {
	my ($text, $newtags, $opts) = @_;

	$opts    ||=
	{
		prefix => '', extended => 1, implicit_links => 1, absolute_links => 1
	};

	my %tags   = %tags;

	merge_hash( $newtags, \%tags )
		if defined $newtags and ( reftype( $newtags ) || '' ) eq 'HASH';
	check_blocks( \%tags )
		if exists $newtags->{blockorder} or exists $newtags->{blocks};

    # find URIs
    my $finder = URI::Find->new( sub {
        my($uri, $orig_uri) = @_;
        # If your link points to an image (that is, if it ends in .png, .gif, .jpg or .jpeg), it will get inserted as an image into the page:
        if ($uri =~ /\.(jpe?g|png|gif)$/) {
            return qq|<img src="$uri" /> |;
        } else {
            return qq|[$uri]|;
        }
    } );
    $finder->find(\$text);
    $text =~ s/\[\[(.+?)\]/\[$1/isg; # dirty hack

	my @blocks =  find_blocks( $text,     \%tags, $opts );
	@blocks    = merge_blocks( \@blocks                 );
	@blocks    =  nest_blocks( \@blocks                 );

	return process_blocks( \@blocks,  \%tags, $opts );
}

sub check_blocks
{
	my $tags   = shift;
	my %blocks = %{ $tags->{blocks} };
	delete @blocks{ @{ $tags->{blockorder} } };

	if (keys %blocks)
	{
		require Carp;
		Carp::carp(
			"No order specified for blocks '" . join(', ', keys %blocks )
			. "'\n"
		)
	}
}

sub find_blocks
{
	my ($text, $tags, $opts) = @_;

	my @blocks;
	for my $line ( split(/\r?\n/, $text) )
	{
		my $block = start_block( $line, $tags, $opts );
		push @blocks, $block if $block;
	}

	return @blocks;
}

sub start_block
{
	my ($text, $tags, $opts) = @_;
	return new_block( 'end', level => 0 ) unless $text;

    # for {{{ }}}
    if ($text =~ /^\}\}\}$/) {
        $code_delimiters = 0;
        return new_block( 'end', level => 1 );
    } elsif ($code_delimiters or $text =~ /^\{\{\{$/) {
        $code_delimiters = 1;
        return new_block( 'code', level => 1, text => $text, opts => $opts, tags => $tags );
    }

	for my $block (@{ $tags->{blockorder} })
	{
		my ($line, $level, $indentation)  = ( $text, 0, '' );

		if ($tags->{indented}{$block})
		{
			($level, $line, $indentation) = get_indentation( $tags, $line );
			next unless $level;
		}

		my $marker_removed = length ($line =~ s/$tags->{blocks}{$block}//);

		next unless $marker_removed;

		return new_block( $block,
			args  => [ grep { defined } $1, $2, $3, $4, $5, $6, $7, $8, $9 ],
			level => $level || 0,
			opts  => $opts,
			text  => $line,
			tags  => $tags,
		);
	}
}

# merge_blocks() and nest_blocks()
BEGIN
{
	for my $op (qw( merge nest ))
	{
		no strict 'refs';
		*{ $op . '_blocks' } = sub
		{
			my $blocks    = shift;
			return unless @$blocks;

			my @processed = shift @$blocks;

			for my $block (@$blocks)
			{
				push @processed, $processed[-1]->$op( $block );
			}
	
			return @processed;
		};
	}
}

sub process_blocks
{
	my ($blocks, $tags, $opts) = @_;

	my @open;
	for my $block (@$blocks)
	{
		push @open, process_block( $block, $tags, $opts )
			unless $block->type() eq 'end';
	}

	return join('', @open);
}

sub process_block {
	my ($block, $tags, $opts) = @_;

	my ($start, $end, $start_line, $end_line, $between)
		= @{ $tags->{ $block->type() } };

	my @text;
	for my $line ( $block->formatted_text() )
	{
		if (blessed( $line ))
		{
			my $prev_end = pop @text || ();
			push @text, process_block( $line, $tags, $opts ), $prev_end;
			next;
		}

		if ((reftype( $start_line ) || '' ) eq 'CODE' )
		{
			(my $start_line, $line, $end_line) = 
				$start_line->(
					$line, $block->level(), $block->shift_args(), $tags, $opts
				);
			push @text, $start_line;
		}
		else
		{
			push @text, $start_line;
		}
		push @text, $line, $end_line;
	}

	pop @text if $between;
	
	@text = grep { defined $_ } @text; # remove warnings
	return join('', $start, @text, $end);
}

sub get_indentation
{
	my ($tags, $text) = @_;

	return 0, $text unless $text =~ s/($tags->{indent})//;
	return( length( $1 ) + 1, $text, $1 );
}

sub format_line {
	my ($text, $tags, $opts) = @_;
	$opts ||= {};

	$text =~ s!$tags->{strong_tag}!$tags->{strong}->($2, $opts)!eg;
	$text =~ s!$tags->{italic_tag}!$tags->{italic}->($2, $opts)!eg;
	$text =~ s!$tags->{strike_tag}!$tags->{strike}->($2, $opts)!eg;
	$text =~ s!$tags->{superscript_tag}!$tags->{superscript}->($1, $opts)!eg;
	$text =~ s!$tags->{subscript_tag}!$tags->{subscript}->($1, $opts)!eg;
	$text =~ s!$tags->{inline_tag}!$tags->{inline}->($1, $opts)!eg;

	$text = find_extended_links( $text, $tags, $opts );

	$text =~ s|(?<!["/>=])\b((?:[A-Z][a-z0-9]\w*){2,})|
			  $tags->{link}->($1, $opts)|egx;

	return $text;
}

sub find_innermost_balanced_pair
{
	my ($text, $open, $close) = @_;

	my $start_pos             = rindex( $text, $open              );
	return if $start_pos == -1;

	my $end_pos               =  index( $text, $close, $start_pos );
	return if $end_pos   == -1;

	my $open_length           = length( $open );
	my $close_length          = length( $close );
	my $close_pos             = $end_pos + $close_length;
	my $enclosed_length       = $close_pos - $start_pos;

	my $enclosed_atom        = substr( $text, $start_pos, $enclosed_length );
	return substr( $enclosed_atom, $open_length, 0 - $close_length ),
	       substr( $text, 0, $start_pos ),
		   substr( $text, $close_pos );
}

sub find_extended_links
{
	my ($text, $tags, $opts) = @_;

    my $schemas = join('|', @{$tags->{schemas}});
    $text =~ s!(\s+)(($schemas):\S+)!$1 . $tags->{link}->($2, $opts)!egi;

	my ($start, $end) = @{ $tags->{extended_link_delimiters} };

	while (my @pieces = find_innermost_balanced_pair( $text, $start, $end ) )
	{
		my ($tag, $before, $after) = map { defined $_ ? $_ : '' } @pieces;
		my $extended               = $tags->{link}->( $tag, $opts ) || '';
		$text                      = $before . $extended . $after;
	};

	return $text;
}

sub make_html_link {
	my ($link, $opts)        = @_;
	$opts                  ||= {};

	($link, my $title)       = find_link_title( $link, $opts );
	($link, my $is_relative) = escape_link( $link, $opts );

	my $prefix               = ( defined $opts->{prefix} && $is_relative )
		? $opts->{prefix} : '';

    unless ($is_relative) {
        return qq|<a href="$link" rel="nofollow">$title</a>|;
    } else {
    	return qq|<a href="$prefix$link">$title</a>|;
    }
}

sub escape_link {
	my ($link, $opts) = @_;

	my $u = URI->new( $link );
	return $link if $u->scheme();

	# it's a relative link
	return( uri_escape( $link ), 1 );
}

sub find_link_title {
	my ($link, $opts)  = @_;
	my $title;

	($link, $title)    = split(/\s+/, $link, 2);
	$title             = $link unless $title;

	return $link, $title;
}

'shamelessly adapted from the Jellybean project, directly from Text::WikiFormat';

__END__

=head1 NAME

Text::GooglewikiFormat - Translate Google Code Wiki markup into HTML

=head1 SYNOPSIS

    use Text::GooglewikiFormat;
    my $raw  = '*bold* _italic_ ~~strike~~';
    my $html = Text::GooglewikiFormat::format($raw);
    # $html is qq~<p><strong>bold</strong> <i>italic</i> <span style="text-decoration: line-through">strike</span></p>~ now

=head1 DESCRIPTION

Google Code L<http://code.google.com/> is a great code hosting place.

This module is aim to convert L<http://code.google.com/p/support/wiki/WikiSyntax> to HTML.

=head1 ADV. Example

    my $raw  = 'WikiWordLink';
    my %tags = %Text::GooglewikiFormat::tags;
    my $html = Text::GooglewikiFormat::format($raw, \%tags, { prefix => 'http://code.google.com/p/fayland/wiki/' } );
    # $html is qq~<p><a href="http://code.google.com/p/fayland/wiki/WikiWordLink">WikiWordLink</a></p>~ now

=head1 BUGS

It's not excatly the same as what google outputs. for the linebreak generally.

please report bugs to L<http://code.google.com/p/fayland/issues/list>

=head1 SEE ALSO

L<Text::WikiFormat>, L<Text::MediawikiFormat>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut