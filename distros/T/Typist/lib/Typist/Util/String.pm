package Typist::Util::String;
use strict;

use base qw( Exporter );
use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( decode_html decode_xml remove_html encode_html encode_xml
  encode_js encode_php encode_phphere encode_url );

sub encode_js {
    my ($str) = @_;
    return '' unless defined $str;
    $str =~ s!(['"\\])!\\$1!g;
    $str =~ s!\n!\\n!g;
    $str =~ s!\f!\\f!g;
    $str =~ s!\r!\\r!g;
    $str =~ s!\t!\\t!g;
    $str;
}

sub encode_php {
    my ($str, $meth) = @_;
    return '' unless defined $str;
    if ($meth eq 'qq') {
        $str = encode_phphere($str);
        $str =~ s!"!\\"!g;    ## Replace " with \"
    } elsif (substr($meth, 0, 4) eq 'here') {
        $str = encode_phphere($str);
    } else {
        $str =~ s!\\!\\\\!g;    ## Replace \ with \\
        $str =~ s!'!\\'!g;      ## Replace ' with \'
    }
    $str;
}

sub encode_phphere {
    my ($str) = @_;
    $str =~ s!\\!\\\\!g;        ## Replace \ with \\
    $str =~ s!\$!\\\$!g;        ## Replace $ with \$
    $str =~ s!\n!\\n!g;         ## Replace character \n with string \n
    $str =~ s!\r!\\r!g;         ## Replace character \r with string \r
    $str =~ s!\t!\\t!g;         ## Replace character \t with string \t
    $str;
}

sub encode_url {
    my ($str) = @_;
    $str =~ s!([^a-zA-Z0-9_.~-])!uc sprintf "%%%02x", ord($1)!eg;
    $str;
}

sub decode_url {
    my ($str) = @_;
    $str =~ s!%([0-9a-fA-F][0-9a-fA-F])!pack("H*",$1)!eg;
    $str;
}

{
    my $Have_Entities = eval 'use HTML::Entities; 1' ? 1 : 0;
    my $NoHTMLEntities = 1;    # hard coded. make switch? purpose?

    sub encode_html {
        my ($html, $can_double_encode) = @_;
        return '' unless defined $html;
        $html =~ tr!\cM!!d;
        if ($Have_Entities && !$NoHTMLEntities) {
            $html = HTML::Entities::encode_entities($html);
        } else {
            if ($can_double_encode) {
                $html =~ s!&!&amp;!g;
            } else {
                ## Encode any & not followed by something that looks like
                ## an entity, numeric or otherwise.
                $html =~ s/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w{1,8});)/&amp;/g;
            }
            $html =~ s!"!&quot;!g;    #"
            $html =~ s!<!&lt;!g;
            $html =~ s!>!&gt;!g;
        }
        $html;
    }

    sub decode_html {
        my ($html) = @_;
        return '' unless defined $html;
        $html =~ tr!\cM!!d;
        if ($Have_Entities && !$NoHTMLEntities) {
            $html = HTML::Entities::decode_entities($html);
        } else {
            $html =~ s!&quot;!"!g;    #"
            $html =~ s!&lt;!<!g;
            $html =~ s!&gt;!>!g;
            $html =~ s!&amp;!&!g;
        }
        $html;
    }
}

{
    my %Map = (
               '&'  => '&amp;',
               '"'  => '&quot;',
               '<'  => '&lt;',
               '>'  => '&gt;',
               '\'' => '&apos;'
    );
    my %Map_Decode = reverse %Map;
    my $RE         = join '|', keys %Map;
    my $RE_D       = join '|', keys %Map_Decode;

    sub encode_xml {
        my ($str, $nocdata) = @_;
        return '' unless defined $str;
        if (
            !$nocdata
            && $str =~ m/
            <[^>]+>  ## HTML markup
            |        ## or
            &(?:(?!(\#([0-9]+)|\#x([0-9a-fA-F]+))).*?);
                     ## something that looks like an HTML entity.
        /x
          ) {
            ## If ]]> exists in the string, encode the > to &gt;.
            $str =~ s/]]>/]]&gt;/g;
            $str = '<![CDATA[' . $str . ']]>';
          } else {
            $str =~ s!($RE)!$Map{$1}!g;
        }
        $str;
    }

    sub decode_xml {
        my ($str) = @_;
        return '' unless defined $str;
        if ($str =~ s/<!\[CDATA\[(.*?)]]>/$1/g) {
            ## Decode encoded ]]&gt;
            $str =~ s/]]&(gt|#62);/]]>/g;
        } else {
            $str =~ s!($RE_D)!$Map_Decode{$1}!g;
        }
        $str;
    }
}

sub remove_html {
    my ($text) = @_;
    return $text if !defined $text;    # suppress warnings
    $text =~ s!<[^>]+>!!gs;
    $text =~ s!<!&lt;!gs;
    $text;
}

1;

=head1 NAME

Typist::Util::String - Utility methods for string manipulation

=head1 METHODS

=over

=item decode_html

=item decode_xml

=item remove_html

=item encode_html

=item encode_xml

=item encode_js

=item encode_php

=item encode_phphere

=item encode_url

=back

=end
