#
# $Id: HikiDoc.pm,v 1.19 2009/07/17 12:59:59 oneroad Exp $
#
package Text::HikiDoc;

use strict;
use warnings;

use File::Basename;

our $VERSION = '1.023';

sub _array_to_hash {
    my $self = shift;
    my $params = shift;
    my $defaults = shift;

    if ( ref $$params[0] eq 'HASH' ) {
        %$self = (@$defaults, %{$$params[0]});
    }
    else {
        my $num = 1;
        for my $value (@$params) {
            $$defaults[$num] = $value;
            $num += 2;
        }

        %$self = @$defaults;
    }

    return $self;
}

sub new {
    my $class = shift;
    my @params = @_;

    my $self = bless {}, $class;

    my @defaults = (
                    string => '',
                    level   => 1,
                    empty_element_suffix => ' />',
                    br_mode => 'false',
                    table_border => 'true',
                   );

    $self->_array_to_hash(\@params, \@defaults);

    $self->{stack} = ();
    $self->{plugin_stack} = ();
    $self->{enabled_plugin} = ();

    return $self;
}


sub to_html {
    my $self = shift;
    my @params = @_;

    my @defaults = (
                    string => $self->{string},
                    level   => $self->{level},
                    empty_element_suffix => $self->{empty_element_suffix},
                    br_mode => $self->{br_mode},
                    table_border => $self->{table_border},
                    enabled_plugin => $self->{enabled_plugin},
                   );

    $self->_array_to_hash(\@params, \@defaults);

    my $string = $self->{string} || '';

    return unless $string;

    $string =~ s/\r\n/\n/g;
    $string =~ s/\r/\n/g;
    $string =~ s/\n*\z/\n\n/;

    # escape '&', '<' and '>'
    $string = $self->_escape_html($string);
    # escape some symbols
    $string = $self->_escape_meta_char($string);
    # parse blocks
    $string = $self->_block_parser($string);
    # remove needless new lines
    $string =~ s/\n{2,}/\n/g;
    # restore some html parts
    $string = $self->_restore_block($string);
    $string = $self->_restore_plugin_block($string);
    # unescape some symbols
    $string = $self->_unescape_meta_char($string);
    # terminate with a single new line
    $string =~ s/\n*\z/\n/g;

    return $string;
}

sub enable_plugin {
    my $self = shift;
    my @list = @_;

    my %tmp;
    @{$self->{enabled_plugin}} = map {
        eval 'require '.ref($self).'::Plugin::'.$_;
        if ( $@ ) {
            ;
        }
        else {
            $_;
        }
    } sort {$a cmp $b} grep {!$tmp{$_}++} @list;
    undef %tmp;

    return @{$self->{enabled_plugin}};
}

#sub enable_all_plugin {
#    my $self = shift;
#
##    somethig_to_do();
#
#    return @{$self->{enabled_plugin}};
#}

#sub disable_plugin {
#    my $self = shift;
#    my @list = @_;
#
#    my %tmp;
#    map {$tmp{$_}++} @{$self->{enabled_plugin}};
#    map {$tmp{$_}--} @list;
#    @{$self->{enabled_plugin}} = sort {$a cmp $b} grep {$tmp{$_} > 0} (keys %tmp);
#    undef %tmp;
#
#    return @{$self->{enabled_plugin}};
#}
#
#sub disable_all_plugin {
#    my $self = shift;
#
#    @{$self->{enabled_plugin}} = ();
#
#    return @{$self->{enabled_plugin}};
#}

sub plugin_list {
    my $self = shift;

    if ( $#{$self->{enabled_plugin}} >= 0 ) {
        return @{$self->{enabled_plugin}};
    }
    else {
        return ();
    }
}

sub is_enabled {
    my $self = shift;
    my $plugin = shift;

    for my $list (@{$self->{enabled_plugin}}) {
        return 1 if $list eq $plugin;
    }
    return 0;
}

##
# Block Parser
##
sub _block_parser {
    my $self = shift;
    my $string = shift || '';

    $string = $self->_parse_plugin($string);
    $string = $self->_parse_pre($string);
    $string = $self->_parse_comment($string);
    $string = $self->_parse_header($string);
    $string = $self->_parse_hrules($string);
    $string = $self->_parse_list($string);
    $string = $self->_parse_definition($string);
    $string = $self->_parse_blockquote($string);
    $string = $self->_parse_table($string);
    $string = $self->_parse_paragraph($string);
    $string =~ s/^\s+//gm;

    return $string;
}

##
# plugin
sub _parse_plugin {
    my $self = shift;
    my $string = shift || '';

    my $plugin = 'false';
    my $plugin_str = '';


    my $ret = '';
    for my $str ( split(/(\{\{|\}\})/o, $string) ) {
        if ( $str eq '{{' ) {
            $plugin = 'true';
            $plugin_str .= $str;
        }
        elsif ( $str eq '}}' ) {
            if ( $plugin eq 'true' ) {
                $plugin_str .= $str;
                (my $tmp = $plugin_str) =~ s/(['"]).*?\1//sg;
                unless ( $tmp =~ /['"]/ ) {
                    $plugin = 'false';
                    $ret .= $self->_store_plugin_block($self->_unescape_meta_char($plugin_str,'true'));
                    $plugin_str = '';
                }
            }
            else {
                $ret .= $str;
            }
        }
        else {
            if ( $plugin eq 'true' ) {
                $plugin_str .= $str;
            }
            else {
                $ret .= $str;
            }
        }
    }
    $ret .= $plugin_str if $plugin eq 'true';

    return $ret;
}

##
# pre
sub _parse_pre {
    my $self = shift;
    my $string = shift || '';

    my $MULTI_PRE_OPEN_RE  = '&lt;&lt;&lt;';
    my $MULTI_PRE_CLOSE_RE = '&gt;&gt;&gt;';
    my $PRE_RE = "^[ \t]";

    $string =~ s|^$MULTI_PRE_OPEN_RE[ \t]*(\w*)$(.*?)^$MULTI_PRE_CLOSE_RE$|"\n".$self->_store_block('<pre>'.$self->_restore_pre($2).'</pre>')."\n\n"|esgm;

    my $c = sub {
        my $string = shift;
        my $regexp = shift;

        chomp $string;
        $string =~ s|$regexp||gm;

        return $string;
    };
    $string =~ s|((?:$PRE_RE.*\n?)+)|"\n".$self->_store_block("<pre>\n".$self->_restore_pre($c->($1,$PRE_RE))."\n</pre>")."\n\n"|egm;
    $c = undef;

    return $string;
}


sub _restore_pre {
    my $self = shift;
    my $string = shift || '';

    $string = $self->_unescape_meta_char($string, 'true');
    $string = $self->_restore_plugin_block($string, 'true');

    return $string;
}

##
# header
sub _parse_header {
    my $self = shift;
    my $string = shift || '';

    my $level = 7 - $self->{level};

    $string =~ s|^(!{1,$level})\s*(.*)\n?|sprintf("\n<h%d>%s</h%d>\n\n",length($1) + $self->{level} -1,$self->_inline_parser($2),length($1) + $self->{level} -1)|egm;

    return $string;
}

##
# hrules
sub _parse_hrules {
    my $self = shift;
    my $string = shift;

    $string =~ s|^----$|\n<hr$self->{empty_element_suffix}\n|gm;

    return $string;
}

##
# list
sub _parse_list {
    my $self = shift;
    my $string = shift;

    my $LIST_UL = '*';
    my $LIST_OL = '#';

    my $LIST_MARK_RE = "[${LIST_UL}${LIST_OL}]";
    my $LIST_RE      = "^$LIST_MARK_RE+\\s*.*";
    my $LIST_RE2     = "^(($LIST_MARK_RE)+)\\s*(.*)";
    my $LISTS_RE     = "(?:$LIST_RE\n)+";

    for my $str ( $string =~ /$LISTS_RE/gm ) {
        my $cur_str = "\n";
        my @list_type_array = ();
        my $level = 0;

        for my $line (split(/\n/,$str)) {
            if ( $line =~ /$LIST_RE2/ ) {
                my $list_type = $2 eq $LIST_UL ? 'ul' : 'ol';
                my $new_level = length($1);
                my $item = $3;
                if ( $new_level > $level ) {
                    for my $i ( 1 .. $new_level - $level ) {
                        push @list_type_array, $list_type;
                        $cur_str .= '<'.$list_type.">\n<li>";
                    }
                    $cur_str .= $self->_inline_parser($item);
                }
                elsif ( $new_level < $level) {
                    for my $i ( 1 .. $level - $new_level ) {
                        $cur_str .= "</li>\n</".pop(@list_type_array).'>';
                    }
                    $cur_str .= "</li>\n<li>".$self->_inline_parser($item);
                }
                elsif ( $list_type eq $list_type_array[$#list_type_array] ) {
                    $cur_str .= "</li>\n<li>".$self->_inline_parser($item);
                }
                else {
                    $cur_str .= "</li>\n</".pop(@list_type_array).">\n";
                    $cur_str .= '<'.$list_type.">\n";
                    $cur_str .= '<li>'.$self->_inline_parser($item);
                    push @list_type_array, $list_type;
                }
                $level = $new_level;
            }
        }
        for my $i ( 1 .. $level) {
            $cur_str .= "</li>\n</".pop(@list_type_array).'>';
        }
        $cur_str .= "\n\n";

        $string =~ s/$LISTS_RE/$cur_str/m;
    }

    return $string;
}

##
# definition
sub _parse_definition {
    my $self = shift;
    my $string = shift;

    my $DEFINITION_RE  = "^:(?:.*?)?:(?:.*)\n?";
    my $DEFINITION_RE2 = "^:(.*?)?:(.*)\n?";
    my $DEFINITIONS_RE = "(?:$DEFINITION_RE)+";

    $string =~ s/($DEFINITION_RE)/$self->_inline_parser($1)/gem;


    my $c = sub {
        my $string = shift;
        my $regexp1 = shift;
        my $regexp2 = shift;

        my $ret = '';

        chomp $string;

        for my $str ( $string =~ /$regexp1/gm ) {
            $str =~ /$regexp2/m;
            if ( $1 eq '' ) {
                $ret .= '<dd>'.$2."</dd>\n";
            }
            elsif ( $2 eq '' ) {
                $ret .= '<dt>'.$1."</dt>\n";
            }
            else {
                $ret .= '<dt>'.$1.'</dt><dd>'.$2."</dd>\n";
            }
        }
        return $ret;
    };
    $string =~ s/($DEFINITIONS_RE)/"\n<dl>\n".$c->($1,$DEFINITION_RE,$DEFINITION_RE2)."<\/dl>\n\n"/gem;
    $c = undef;

    return $string;
}

##
# blockquote
sub _parse_blockquote {
    my $self = shift;
    my $string = shift;

    my $BLOCKQUOTE_RE  = "^\"\"[ \t]?";
    my $BLOCKQUOTES_RE = "(?:$BLOCKQUOTE_RE.*\n?)+";

    my $c = sub  {
        my $string = shift;
        my $regexp = shift;

        chomp $string;
        $string =~ s/$regexp//gm;

        return $string;
    };
    $string =~ s/($BLOCKQUOTES_RE)/"\n<blockquote>\n".$self->_block_parser($c->($1,$BLOCKQUOTE_RE))."\n<\/blockquote>\n\n"/egm;
    $c = undef;

    return $string;
}

##
# table
sub _parse_table {
    my $self = shift;
    my $string = shift;

    my $TABLE_SPLIT_RE = '\|\|';
    my $TABLE_RE = "^$TABLE_SPLIT_RE.+\n?";
    my $TABLES_RE = "(?:$TABLE_RE)+";

    $string =~ s/($TABLE_RE)/$self->_inline_parser($1)/gme;

    for my $str ( $string =~ /($TABLES_RE)/gm ) {
        my $ret = '';
        if ( $self->{table_border} eq 'false' ) {
            $ret = "\n<table>\n";
        }
        else {
            $ret = "\n<table border=\"1\">\n";
        }

        for my $line (split(/\n/,$str)) {
            $ret .= '<tr>';
            chomp $line;
            $line =~ s/^$TABLE_SPLIT_RE//;
            for my $i ( grep !/$TABLE_SPLIT_RE/, split(/($TABLE_SPLIT_RE)/,$line) ) {
                my $tag = $i =~ s/^!// ? 'th' : 'td';
                my $attr = '';
                if ( $i =~ s/^((?:\^|&gt;)+)// ) {
                    my $tmp = $1;
                    my $rs = (() = $tmp =~ /\^/g) +1;
                    my $cs = (() = $tmp =~ /(?:&gt;)/g)+1;
                    $attr .= ' rowspan="'.$rs.'"' if $rs > 1;
                    $attr .= ' colspan="'.$cs.'"' if $cs > 1;
                }
                $ret .= '<'.$tag.$attr.'>'.$self->_inline_parser($i).'</'.$tag.'>';
            }
            $ret .= "</tr>\n";
        }

        $ret .= "</table>\n\n";
        $string =~ s/$TABLES_RE/$ret/m;
    }

    return $string;
}

##
# comment
sub _parse_comment {
    my $self = shift;
    my $string = shift;

    $string =~ s|^//.*\n?||gm;

    return $string;
}

##
# paragraph
sub _parse_paragraph {
    my $self = shift;
    my $string = shift;

    my $PARAGRAPH_BOUNDARY_RE = "\n{2,}";
    my $NON_PARAGRAPH_RE      = "^<[^!]";

    my @ret;
    for my $str ( split(/$PARAGRAPH_BOUNDARY_RE/mo, $string) ) {
        my $tmp = $str;
        chomp $tmp;

        if ( $tmp eq '' ) {
            push @ret, '';
        }
        elsif ( $tmp =~ /$NON_PARAGRAPH_RE/m ) {
            push @ret, $tmp;
        }
        else {
            my $paragraph = '<p>'.$self->_inline_parser($tmp).'</p>';
            $paragraph =~ s/\n/<br$self->{empty_element_suffix}\n/g if ($self->{br_mode} eq 'true');
            push @ret, $paragraph;
        }
    }

    $string = join("\n\n",@ret);

    return $string;
}

##
# Inline Parser
##
sub _inline_parser {
    my $self = shift;
    my $string = shift || '';

    $string = $self->_parse_link($string);
    $string = $self->_parse_modifier($string);

    return $string;
}

##
# link and image
sub _parse_link {
    my $self = shift;
    my $string = shift || '';

    my $IMAGE_RE        = '.(jpe?g|gif|png)\z';
    my $BLACKET_LINK_RE = '\[\[(.+?)\]\]';
    my $NAMED_LINK_RE   = '(.+?)\|(.+)';
    my $URI_RE          = '((?:(?:https?|ftp|file):|mailto:)[A-Za-z0-9;\/?:@&=+$,\-_.!~*\'()#%]+)';

    for my $str ( $string =~ /$BLACKET_LINK_RE/gm ) {
        my $uri;
        my $title;
        if ( $str =~ /$NAMED_LINK_RE/ ) {
            $title = $self->_parse_modifier($1);
            $uri = $2;
        }
        else {
            $uri = $title = $str;
        }
        if ( $uri !~ m|://| and $uri !~ /^mailto:/ ) {
            $uri =~ s/^(?:https?|ftp|file)+://;
        }

        my $key = $self->_store_block('<a href="'.$self->_escape_quote($uri).'">'.$title.'</a>');
        $string =~ s/$BLACKET_LINK_RE/$key/m;
    }

    for my $str ( $string =~ /$URI_RE/gm ) {
        my $uri = $str;
        my $key;
        if ( $uri !~ m|://| and $uri !~ /^mailto:/ ) {
            $uri =~ s/^\w+://;
        }
        if ( $uri =~ /$IMAGE_RE/i ) {
            $key = $self->_store_block('<img src="'.$uri.'" alt="'.File::Basename::basename($uri).'"'.$self->{empty_element_suffix});
        }
        else {
            $key = $self->_store_block('<a href="'.$uri.'">'.$uri.'</a>');
        }
        $string =~ s/$URI_RE/$key/m;
    }

    return $string;
}

##
# modifier (strong, em, re)
sub _parse_modifier {
    my $self = shift;
    my $string = shift || '';

    my $STRONG = "'''";
    my $EM     = "''";
    my $DEL    = '==';

    my $STRONG_RE = "$STRONG(.+?)$STRONG";
    my $EM_RE     = "$EM(.+?)$EM";
    my $DEL_RE    = "$DEL(.+?)$DEL";

    (my $MODIFIER_RE = "($STRONG_RE|$EM_RE|$DEL_RE)") =~ s/\(\.\+\?\)/(?:.+?)/g;

    for my $str ( $string =~ /$MODIFIER_RE/gm ) {
        my $key;
        if ( $str =~ /(.*)$STRONG_RE(.*)/ ) {
            $key = $self->_store_block($self->_parse_modifier($1.'<strong>'.$2.'</strong>'.$3));
        }
        elsif ( $str =~ /(.*)$EM_RE(.*)/ ) {
            $key = $self->_store_block($self->_parse_modifier($1.'<em>'.$2.'</em>'.$3));
        }
        elsif ( $str =~ /(.*)$DEL_RE(.*)/ ) {
            $key = $self->_store_block($self->_parse_modifier($1.'<del>'.$2.'</del>'.$3));
        }
        $string =~ s/$MODIFIER_RE/$key/ if $key;
    }

    return $string;
}


##
# Utility Methods
##
sub _escape_html {
    my $self = shift;
    my $string = shift || '';

    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;

    return $string;
}

sub _escape_quote {
    my $self = shift;
    my $string = shift || '';

    $string =~ s/"/&quot;/g;

    return $string;
}

sub _store_block {
    my $self = shift;
    my $string = shift || '';

    push @{$self->{stack}}, $string;
    my $key = '<'.$#{$self->{stack}}.'>';

    return $key;
}

sub _restore_block {
    my $self = shift;
    my $string = shift || '';
    my $count = shift || 0;

    return $string if $#{$self->{stack}} < 0;
    return $string if $count > 10;

    if ( $string =~ s|<(\d+)>|${$self->{stack}}[$1]|gm ) {
        $string = $self->_restore_block($string,++$count);
    }

    return $string;
}

sub _store_plugin_block {
    my $self = shift;
    my $string = shift || '';

    push @{$self->{plugin_stack}}, $string;
    my $key = '<!'.$#{$self->{plugin_stack}}.'>';

    return $key;
}

sub _restore_plugin_block {
    my $self = shift;
    my $string = shift || '';
    my $original = shift || 'false';

    my $BLOCK_PLUGIN_RE    = '<p><!(\d+)></p>';
    my $BLOCK_PLUGIN_OPEN   = '<div class="plugin">';
    my $BLOCK_PLUGIN_CLOSE  = '</div>';
    my $INLINE_PLUGIN_RE     = '<!(\d+)>';
    my $INLINE_PLUGIN_OPEN  = '<span class="plugin">';
    my $INLINE_PLUGIN_CLOSE = '</span>';

    return $string if $#{$self->{plugin_stack}} < 0;

    if ( $original eq 'true' ) {
        $string =~ s|$INLINE_PLUGIN_RE|${$self->{plugin_stack}}[$1]|g;
    }
    elsif ( $#{$self->{enabled_plugin}} >= 0 ) {
        $string =~ s|$BLOCK_PLUGIN_RE|$self->_do_plugin(${$self->{plugin_stack}}[$1],$BLOCK_PLUGIN_OPEN,$BLOCK_PLUGIN_CLOSE)|ge;
        $string =~ s|$INLINE_PLUGIN_RE|$self->_do_plugin(${$self->{plugin_stack}}[$1],$INLINE_PLUGIN_OPEN,$INLINE_PLUGIN_CLOSE)|eg;
    }
    else {
        $string =~ s|$BLOCK_PLUGIN_RE|$BLOCK_PLUGIN_OPEN${$self->{plugin_stack}}[$1]$BLOCK_PLUGIN_CLOSE|g;
        $string =~ s|$INLINE_PLUGIN_RE|$INLINE_PLUGIN_OPEN${$self->{plugin_stack}}[$1]$INLINE_PLUGIN_CLOSE|g;
    }

    return $string;
}

sub _do_plugin {
    my $self = shift;
    my $string = shift;
    my $prefix = shift;
    my $suffix = shift;

#    $string =~ s/^{{(.*)}}$/$1/;
#    return eval ref($self).'::Plugin::'.$string || $prefix.'{{'.$string.'}}'.$suffix;
    $string =~ /\{\{([^\s\(\)\'\"]+)([\000-\377]*)\}\}/m;
    eval {
        my $method = $1;
        my $args = $2 || '';

        my $obj = ref($self).'::Plugin::'.$method.'->new($self)';
        return eval $obj.'->to_html('.$args.')';
    } or return $prefix.$string.$suffix;
}

sub _escape_meta_char {
    my $self = shift;
    my $string = shift || '';

    $string =~ s{\\(\{|\}|:|'|"|\|)}{'&#x'.unpack('H2',$1).';'}eg;

    return $string;
}

sub _unescape_meta_char {
    my $self = shift;
    my $string = shift || '';
    my $original = shift || 'false';

    if ( $original eq 'true' ) {
        $string =~ s|&#x([0-9a-f]{2});|'\\'.pack('H2',$1)|eg;
    }
    else {
        $string =~ s|&#x([0-9a-f]{2});|pack('H2',$1)|eg;
    }

    return $string;
}

1;
__END__

=head1 NAME

Text::HikiDoc - Pure Perl implementation of 'HikiDoc' which is a text-to-HTML conversion tool.

=head1 SYNOPSIS

  use Text::HikiDoc;

  # $text = '!Title';
  # $html = '<h1>Title</h1>';

  $obj = Text::HikiDoc->new();
  $html = $obj->to_html($text);

    or

  $obj = Text::HikiDoc->new($text);
  $html = $obj->to_html();


  # $text = "!Title\n----\n!!SubTitle";
  # $html = "<h2>Title</h2>\n<hr />\n<h3>SubTitle</h3>\n";

  $obj = Text::HikiDoc->new({
                             string => $text,
                             level => 2,
                             empty_element_suffix => ' />',
                             br_mode => 'true',
                             table_border => 'false',
                            });

    or

  $obj = Text::HikiDoc->new($text, 2, ' />', 'true', 'false');

  $html = $obj->to_html();

  # $text = "!Title\n----\n!!SubTitle\nhogehoge{{br}}fugafuga";
  # $html = "<h1>Title</h1>\n<hr />\n<h2>SubTitle</h2>\n<p>hogehoge<br />fugafuga</p>\n";

  $obj = Text::HikiDoc->new();
  $obj->enable_plugin('br');
  $html = $obj->to_html($text);

  $obj->enable_plugin('br','ins');
  @plugins = $obj->plugin_list; # br, ins
  $obj->is_enabled('br'); # 1
  $obj->is_enabled('pr'); # 0


=head1 DESCRIPTION

'HikiDoc' is a text-to-HTML conversion tool for web writers. The original 'HikiDoc' is Ruby implementation.

This library is pure perl implementation of 'HikiDoc', and has interchangeability with the original.

=head1 Methods

=head2 new

=over 4

This method creates a new HikiDoc object. The following parameters are accepted.

=over 4

=item string

Set text data.

=item level

Set headings level. Default setting is '1'. If you set '2', heading tags will start '<h2>'.

=item empty_element_suffix

Set empty element suffix. Default setting is ' />'.

ex. Default horizontal line is '<hr />'. You can change it '<hr>' If you set '>'.

=item br_mode

When br_mode is 'true', changing line in paragraph is replaced 'br' tag. Default setting is 'false'.

This is an original enhancing of this library that is not in the original 'HikiDoc'.

=item table_border

When table_border is 'false', 'table' tag is '<table>'. When it is 'true', add 'border="1"' in table tag.
Default setting is 'true'.

This is an original enhancing of this library that is not in the original 'HikiDoc'.

=back

=back

=head2 to_html

=over 4

This method converts string to html

=over 4

=item string

Set text data. If 'string' is specified by both new() and to_html(), to_html is given to priority.

=back

=back

=head2 enable_plugin(@args)

=over 4

This method enables plugin module. '@args' is list of plugin names.

=over 4

=back

=back

=head2 plugin_list

=over 4

This method returns array of enabled plugin lists.

=over 4

=back

=back

=head2 is_enabled($str)

=over 4

This method returns 1 or 0. If enabled plugin "$str", return 1.

=over 4

=back

=back

=head1 Plugin

Text::HikiDoc can be enhanced by the plug-in. When you use the plug-in, enable_plugin() is used.

=head2 Text::HikiDoc::Plugin::aa

=over 4

  {{aa "
               (__)
              (oo)
       /-------\/
      / |     ||
     *  ||----||
        ~~    ~~
  "}}

  is replaced with

  <pre class="ascii-art">
               (__)
              (oo)
       /-------\/
      / |     ||
     *  ||----||
        ~~    ~~
  </pre>

  If Text::HikiDoc::Plugin::texthighlight or Text::HikiDoc::Plugin::vimcolor is enabled, you can write

  <<< aa
               (__)
              (oo)
       /-------\/
      / |     ||
     *  ||----||
        ~~    ~~
  >>>

=back

=head2 Text::HikiDoc::Plugin::br

=over 4

{{br}}

is replaced with 

E<lt>br /E<gt>

=back

=head2 Text::HikiDoc::Plugin::e

=over 4

{{e('hearts')}} {{e('9829')}}

is replaced with

&hearts; &#9829;

=back

=head2 Text::HikiDoc::Plugin::ins

=over 4

{{ins 'insert part'}}

is replaced with

E<lt>insE<gt>insert partE<lt>/insE<gt>

=back

=head2 Text::HikiDoc::Plugin::sub

=over 4

H{{sub('2')}}O

is replaced with

HE<lt>subE<gt>2E<lt>/subE<gt>O

=back

=head2 Text::HikiDoc::Plugin::sup

=over 4

2{{sup(3)}}=8

is replaced with

2E<lt>supE<gt>3E<lt>/supE<gt>=8

=back

=head2 Text::HikiDoc::Plugin::texthighlight

=over 4

Syntax color text is added to the pre mark. That uses Text::Highlight .

The following, it is highlighted as the source code of Perl. When writing instead of"E<lt>E<lt>E<lt> Perl" as "E<lt>E<lt>E<lt>", it becomes a usual pre mark.

  <<< Perl
  sub dummy {
      $string = shift;
  
      $string =~ /$PLUGIN_RE/;
      print "s:$string\tm:$1\ta:$2\n";
      $a = $2;
      $a =~ s/^\s*(.*)\s*$/$1/;
  
      if ( $a =~ /($PLUGIN_RE)/ ) {
          &hoge($a);
      }
      return $string;
  }
  >>>

NOTE: Method of mounting this plug-in will change in the future.

=back

=head2 Text::HikiDoc::Plugin::vimcolor

=over 4

Syntax color text is added to the pre mark. That uses Text::VimColor .

NOTE: Method of mounting this plug-in will change in the future.

=back

=head1 SEE ALSO

=over 4

=item The original 'HikiDoc' site

http://projects.netlab.jp/hikidoc/

=item Text::HikiDoc::Plugin

=item Text::HikiDoc::Plugin::aa

=item Text::HikiDoc::Plugin::br

=item Text::HikiDoc::Plugin::e

=item Text::HikiDoc::Plugin::ins

=item Text::HikiDoc::Plugin::sub

=item Text::HikiDoc::Plugin::sup

=item Text::HikiDoc::Plugin::texthighlight

=item Text::HikiDoc::Plugin::vimcolor

=back

=head1 AUTHORS

The original 'HikiDoc' was written by Kazuhiko E<lt>kazuhiko@fdiary.netE<gt>

This release was made by Kawabata, Kazumichi (Higemaru) E<lt>kawabata@cpan.orgE<gt> http://haro.jp/

=head1 COPYRIGHT AND LICENSE

This library 'HikiDoc.pm' is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2006- Kawabata, Kazumichi (Higemaru) E<lt>kawabata@cpan.orgE<gt>

=cut
