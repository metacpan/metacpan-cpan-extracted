package Text::HikiDoc::Plugin::texthighlight;

use strict;
use warnings;
no warnings 'redefine';

use Text::Highlight;

*Text::HikiDoc::_parse_pre = sub {
    my $self = shift;
    my $string = shift || '';

    return '' unless $string;

    my $MULTI_PRE_OPEN_RE  = '&lt;&lt;&lt;';
    my $MULTI_PRE_CLOSE_RE = '&gt;&gt;&gt;';
    my $PRE_RE = "^[ \t]";

    # pre
    $string =~ s|^$MULTI_PRE_OPEN_RE$(.*?)^$MULTI_PRE_CLOSE_RE$|"\n".$self->_store_block('<pre>'.$self->_restore_pre($1).'</pre>')."\n\n"|esgm;

    # aa
    $string =~ s|^$MULTI_PRE_OPEN_RE[ \t]*[aA]{2}$(.*?)^$MULTI_PRE_CLOSE_RE$|"\n".$self->_store_block('<pre class="ascii-art">'.$1.'</pre>')."\n\n"|esgm;

    # raw
    my $c = sub {
        my $str = shift;
        $str =~ s/&lt;/</g;
        $str =~ s/&gt;/>/g;
        $str =~ s/&amp;/&/g;
        return $str;
    };
    $string =~ s|^$MULTI_PRE_OPEN_RE[ \t]*[rR][aA][wW]$(.*?)^$MULTI_PRE_CLOSE_RE$|"\n".$c->($1)."\n\n"|esgm;

    # texthighlight
    $c = sub {
        my $str = shift;
        my $type = shift || 'Perl';
        # CPP, CSS, HTML, Java, PHP, Perl, SQL
        return if $str eq '';

        $type = uc $type;
        $type = 'Java' if ( $type eq 'JAVA' );
        $type = 'Perl' if ( $type eq 'PERL' );

        $str =~ s/&lt;/</g;
        $str =~ s/&gt;/>/g;
        $str =~ s/&amp;/&/g;

        my $th = Text::Highlight->new(wrapper => "%s");
        return $th->highlight($type,$str);
    };
    $string =~ s|^$MULTI_PRE_OPEN_RE[ \t]*(\w*)$(.*?)^$MULTI_PRE_CLOSE_RE$|"\n".$self->_store_block('<pre class="texthighlight">'.$self->_restore_pre($c->($2,$1)).'</pre>')."\n\n"|esgm;

    $c = sub {
        my $string = shift;
        my $regexp = shift;

        chomp $string;
        $string =~ s|$regexp||gm;

        return $string;
    };
    $string =~ s|((?:$PRE_RE.*\n?)+)|"\n".$self->_store_block("<pre>\n".$self->_restore_pre($c->($1,$PRE_RE))."\n</pre>")."\n\n"|egm;
    $c = undef;

    return $string;
};

1;
