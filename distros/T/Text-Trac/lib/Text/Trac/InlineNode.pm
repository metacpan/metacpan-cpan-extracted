package Text::Trac::InlineNode;

use strict;
use warnings;
use Tie::IxHash;
use Text::Trac::Macro;
use UNIVERSAL::require;
use Text::Trac::LinkResolver;
use HTML::Entities qw();

our $VERSION = '0.22';

tie my %token_table, 'Tie::IxHash';

#my $handler = $token_table{'!?\\[\\d+\\]|(?:\\b|!)r\\d+\\b(?!:\\d)'};
#$handler->format_link('test');

my $link_scheme         = '[\w.+-]+';
my $quoted_string       = q{'[^']+'|"[^"]+"};
my $shref_target_first  = '[\w/?!#@]';
my $shref_target_middle = '(?:\|(?=[^|\s])|[^|<>\s])';
my $shref_target_last   = '[a-zA-Z0-9/=]';
my $shref               = "!?$link_scheme:
             (?:
                $quoted_string
                |$shref_target_first(?:$shref_target_middle*$shref_target_last)?
              )
            ";

my $macro = '\[\[[\w/+-]+(?:\(.*\))?\]\]';

my $lhref_relative_target = '[/.][^\s[\]]*';
my $lhref                 = "!?\\[
               (?:
                $link_scheme:
                (?:$quoted_string|[^\\[\\]\\s]*)
                |(?:$lhref_relative_target|[^\\[\\]\\s])
               )
               (?:
                \\s+
                $quoted_string
                |[^\\]]+
               )?
             \\]
             ";

my $rules = join '|', ( map {"($_)"} ( keys %token_table ) );
$rules = qr/$rules/x;

s/^\!\?// for values %token_table;
s/^\\//   for values %token_table;

sub new {
	my ( $class, $c ) = @_;

	# external link resolvers
	my %external_handler;
	for (@Text::Trac::LinkResolver::handlers) {
		my $class = 'Text::Trac::LinkResolver::' . ucfirst($_);
		$class->require;
		my $handler = $class->new($c);
		$token_table{ $handler->{pattern} } = $handler if defined $handler->{pattern};
		$external_handler{$_} = $handler;
	}

	%token_table = (
		q{'''''}          => 'bolditalic',
		q{'''}            => 'bold',
		q{''}             => 'italic',
		'!?__'            => 'underline',
		'!?~~'            => 'strike',
		'!?,,'            => 'subscript',
		'!?\^'            => 'superscript',
		'`|\{\{\{|\}\}\}' => 'inline',
		$macro            => 'macro',
		%token_table,
		$lhref => 'lhref',
		$shref => 'shref',
	);

	my $rules = join '|', ( map {"($_)"} ( keys %token_table ) );
	$rules = qr/$rules/x;

	s/^\!\?// for values %token_table;
	s/^\\//   for values %token_table;

	my $self = {
		context          => $c,
		open_tags        => [],
		rules            => $rules,
		external_handler => \%external_handler,
	};
	bless $self, $class;
	return $self;
}

sub parse {
	my ( $self, $rest ) = @_;
	my $html = '';
	while ( $rest =~ /$self->{rules}/xms ) {
		$html .= $self->escape($`) . $self->_replace( $&, $`, $' );
		$rest = $';
	}
	return $html . $self->escape($rest);
}

sub escape {
	my ( $self, $s ) = @_;
	return HTML::Entities::encode( $s, '<>&"' );
}

sub _replace {
	my ( $self, $match, $pre_match, $post_match ) = @_;
	if ( $match =~ s/^!// ) {
		return $match;
	}
	else {
	TOKEN:
		for my $token ( keys %token_table ) {
			if ( $match =~ /$token/x ) {
				my $formatter = $token_table{$token};
				if ( ref $formatter ) {
					for (qw/ log source attachment http /) {
						next TOKEN if $match =~ /^\[?$_/;
					}
					return $formatter->format_link($match);
				}
				else {
					my $method = "_${formatter}_formatter";
					return $self->$method( $match, $pre_match, $post_match );
				}
			}
		}
	}
}

sub _simple_tag_handler {
	my ( $self, $open_tag, $close_tag ) = @_;

	if ( $self->_is_open($open_tag) ) {
		$self->_close_tag($open_tag);
		return $close_tag;
	}
	else {
		$self->_open_tag($open_tag);
		return $open_tag;
	}
}

sub _is_open {
	my ( $self, $tag ) = @_;
	return grep { $tag eq $_ } @{ $self->{open_tags} };
}

sub _open_tag {
	my ( $self, $tag ) = @_;
	push @{ $self->{open_tags} }, $tag;
}

sub _close_tag {
	my ( $self, $tag ) = @_;

	my $index = 0;
	for ( @{ $self->{open_tags} } ) {
		last if $tag eq $_;
		$index++;
	}
	splice @{ $self->{open_tags} }, $index;
}

sub _bolditalic_formatter {
	my $self = shift;

	my $is_open = $self->_is_open('<i>');

	my $tmp;
	if ($is_open) {
		$tmp .= '</i>';
		$self->_close_tag('<i>');
	}

	$tmp .= $self->_bold_formatter;

	unless ($is_open) {
		$tmp .= '<i>';
		$self->_open_tag('<i>');
	}

	return $tmp;
}

sub _bold_formatter {
	my $self = shift;
	return $self->_simple_tag_handler( '<strong>', '</strong>' );
}

sub _italic_formatter {
	my $self = shift;
	return $self->_simple_tag_handler( '<i>', '</i>' );
}

sub _underline_formatter {
	my ( $self, $match, $pre_match, $post_match ) = @_;
	my $class_underline = $self->{context}->{class} ? q{class="underline"} : '';
	return $self->_simple_tag_handler( qq{<span $class_underline>}, '</span>' );
}

sub _strike_formatter {
	my ( $self, $match, $pre_match, $post_match ) = @_;
	return $self->_simple_tag_handler( '<del>', '</del>' );
}

sub _superscript_formatter {
	my ( $self, $match, $pre_match, $post_match ) = @_;
	return $self->_simple_tag_handler( '<sup>', '</sup>' );
}

sub _subscript_formatter {
	my ( $self, $match, $pre_match, $post_match ) = @_;
	return $self->_simple_tag_handler( '<sub>', '</sub>' );
}

sub _inline_formatter {
	my ( $self, $match, $pre_match, $post_match ) = @_;
	return $self->_simple_tag_handler( '<tt>', '</tt>' );
}

sub _shref_formatter {
	my ( $self, $match ) = @_;

	my ( $ns, $target ) = (
		$match =~ m/($link_scheme):
                                        (
                                          $quoted_string
                                         |$shref_target_first
                                          (?:
                                              $shref_target_middle*
                                              $shref_target_last
                                          )?
                                         )
                                       /x
	);
	return $self->_make_link( $ns, $target, $match, $match );
}

sub _lhref_formatter {
	my ( $self, $match ) = @_;

	my ( $ns, $target, $label ) = (
		$match =~ m/\[
                      ($link_scheme):
                      (
                          (?:$quoted_string|[^\]\s]*)
                         |(?:$lhref_relative_target|[^\]\s])
                      )
                      (?:
                          \s+
                          ($quoted_string|[^\]]+)
                      )?
                      \]
                     /x
	);
	if ( !$label ) {    # e.g. `[http://target]` or `[wiki:target]`
		if ($target) {
			if ( $target =~ m!^//! ) {
				$label = $ns . ':' . $target;
			}
			else {
				$label = $target;
			}
		}
		else {          # e.g. `[search:]`
			$label = $ns;
		}
	}
	return $self->_make_link( $ns, $target, $match, $label );
}

sub _make_link {
	my ( $self, $ns, $target, $match, $label ) = @_;
	if ( defined $target && ( $target =~ m!^//! or $target eq 'mailto' ) ) {
		return $self->_make_ext_link( $ns . ':' . $target, $label );
	}
	else {
		my $handler;
		if ( defined $ns ) {
			$handler = $self->{external_handler}->{$ns};
		}
		return $handler ? $handler->format_link( $match, $target, $label ) : $match;
	}
}

sub _make_ext_link {
	my ( $self, $url, $text, $title ) = @_;

	my $title_attr = $title ? qq{title="$title"} : '';

	$title ||= $text;

	my $local = $self->{context}->{local} || '';
	my $class_link = $self->{context}->{class} ? q{class="ext-link"}           : '';
	my $class_icon = $self->{context}->{class} ? q{class="icon"}               : '';
	my $span       = $self->{context}{span}    ? qq{<span $class_icon></span>} : '';
	if ( $url !~ /^$local/ or !$local ) {
		return qq{<a $class_link href="$url"$title_attr>$span$text</a>};
	}
}

sub _macro_formatter {
	my ( $self, $match ) = @_;

	my ( $name, $args ) = ( $match =~ m!\[\[ ([\w/+-]+) (?:\( (.*) \))? \]\]!x );

	if ( $name =~ /br/i ) {
		return '<br />';
	}
	else {
		return Text::Trac::Macro->new->parse( $name, $args, $match );
	}
}

package Text::Trac::InlineNode::Initializer;

1;
