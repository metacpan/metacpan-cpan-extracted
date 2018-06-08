package Text::Typifier;

use v5.14;
use List::AllUtils qw/ zip pairs pairwise /;
use HTML::TreeBuilder 5 -weak;
use HTML::Entities qw/ decode_entities /;
use Text::Markup;
use strict;
use warnings;
use utf8;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( separate typify );
@EXPORT_OK = qw();
%EXPORT_TAGS = (all => [@EXPORT_OK]);
$VERSION = '2.01';


my $delineator = qr/\u002D\u2010-\u2015\u2212\uFE63\uFF0D.;:/ux;  #- ‐ ‒ – — ― ﹣ － . ; :
my $month = qr/Jan(uary)? | Feb(ruary)? | Mar(ch)? | Apr(il)? | May | Jun(e)? | Jul(y)? | Aug(ust)? | Sep(tember)? | Oct(ober)? | Nov(ember)? | Dec(ember)?/ux;
my $ordinal = qr/st | nd | rd | th/ux;

my $cap_word = qr/[A-Z][A-Za-z]++/ux;
my $name = qr/(?: (?: $cap_word \h | [A-Z]\. \h*)++ (?: (?|of|in|at|with|the|and|for) \h+)*+ )++ $cap_word/ux;
my $abbr = qr/([A-Za-z]\.){2,}/ux;
my $numb = qr/\W? (?: \d{1,3}[,'_]?)++ (?: \. (\d{1,3}[,'_]?)*+)? \W? | \W? (?: \d{1,3}[,'_]?)*+ (?: \. (\d{1,3}[,'_]?)++) \W?/ux;
my $word = qr/(?'quote'[“"])? (?: $name | $abbr | $numb | ['‘]?\w (?: ['’\w-]* \w)? ['’]?) (?('quote')["”])/ux;
my $date = qr/(?(DEFINE)(?'month'$month))(?(DEFINE)(?'ordinal'$ordinal))
              (?| (?P>month) \h+ \d{1,2} (?P>ordinal)? ,? \h+ \d\d(\d\d)? 
                | \d{1,2} (?P>ordinal)? \h+ (?P>month) ,? \h+ \d\d(\d\d)? 

                | \d\d(\d\d)? \h+ (?P>month) \h+ \d{1,2} (?P>ordinal)? 

                | (?P>month) \d{1,2} (?P>ordinal)?

                | \d{1,2} (?P>ordinal) \h+ of \h+ (?P>month)

                | \d\d \/ \d\d \/ \d\d\d\d 
                | \d\d \- \d\d \- \d\d\d\d 
                | \d\d \. \d\d \. \d\d\d\d 

                | \d\d\d\d \/ \d\d \/ \d\d
                | \d\d\d\d \- \d\d \- \d\d
                | \d\d\d\d \. \d\d \. \d\d
            )/ux;

my $sen_init = qr/(?= [ \[\(\{\⟨ ]? ["“]? (?: $cap_word|[0-9]++) )/ux;
  #SENTENCE INITIATOR: detects beginning of a sentence (zero-width assertion)

my $sen_term = qr/(?(DEFINE)(?'sen_init'$sen_init))
                    [\.?!‽…⋯᠁]+

                  (?(?=["”])
                    (?: ["”](?= \h+ (?P>sen_init) )|(?:["”]\v))
                    |    [ \]\)\}\⟩ ]?  (?= (?:\s+ (?P>sen_init) )|\v|[^\w\d]
                  )
                )/ux;
  #SENTENCE TERMINATOR: matches any number of   [.?!] with optional final ["”]   followed by a new sentence or [\v] or the end of the block

my $flat_clause = qr/(?(DEFINE)(?'word'$word))
           (?'left' (?<= <) \/?)?  (?'text' (?P>word) (?: \h+ (?P>word))*+)  (*SKIP)  (?('left')(?! >))/ux;
  #matches a grouping of words that

my $comma_clause = qr/(?(DEFINE)(?'flat_clause'$flat_clause))
            (?P>flat_clause) ([,] \h+ (?P>flat_clause))++/ux;

my $quote_clause = qr/(?(DEFINE)(?'joint_clause'(?:$comma_clause)|(?:$flat_clause)))
            (?P>joint_clause)? [“"] (?P>joint_clause) ($sen_term)? ["”] (?P>joint_clause)? /ux;

my $semicolon_list = qr/(?(DEFINE)(?'comma_clause'$comma_clause))
            (?: (?P>comma_clause);\h+)++ (?P>comma_clause)/ux;
  #matches several clauses in a row, delineated by   [;]   or   [,]    (n.b. clauses separated by [;] may have [,] interally)

my $complex_clause = qr/ $semicolon_list  |  $quote_clause  |  $comma_clause  |  $flat_clause /ux;
  #matches either a   [semicolon_list]   or   [flat_clause]

my $sentence_list = qr/(?(DEFINE)(?'complex_clause'$complex_clause))
             (?P>complex_clause)   [:]\h+   (?P>complex_clause)/ux;
  #matches any   [complex_clause]   followed by a [:]   followed by a [complex_clause]

my $bracket_clause = qr/[ \[\(\{\⟨ ] (?| (?:$sentence_list \h*)  |  (?:$complex_clause) \h*  )++  [ \]\)\}\⟩ ]/ux;

my $sentence = qr/(?(DEFINE)(?'complex_clause')$complex_clause)
                  (?| $sentence_list
                    | (?: (?P>complex_clause)   (?: [\u002D\u2010-\u2015\u2212\uFE63\uFF0D.;:,] \h* (?: (?P>complex_clause)|$sentence_list)?)++)
                  )+
                  (?: \h+ $bracket_clause)
                  (?: $sen_term|  :(?=\v) )/ux;
    #matches either   a [sentence_list] followed by a sentence terminator   or   one or more delineated [complex_clause] followed by a sentence terminator

my $paragraph = qr/(?(DEFINE)(?'sentence'$sentence))(?P>sentence) (?: \s+ (?P>sentence))++/ux;
    #one or more   [sentence]   delineated by whitespace
my $title = qr/(*FAIL)/ux;
my $dateline = qr/(?| (?: $name , \h+)* $date | $date (?: , \h+ $name)+ ) /ux;

my $dialog = qr/(*FAIL)/ux;

my $html_bold = qr/<(?'tag' b)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_italic = qr/<(?'tag' i)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_under = qr/<(?'tag' u)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_strong = qr/<(?'tag' strong)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_title = qr/<(?'tag' title)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_table = qr/<(?'tag' table)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/sux;
my $html_ulist = qr/<(?'tag' ul)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/sux;
my $html_olist = qr/<(?'tag' ol)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/sux;
my $html_dlist = qr/<(?'tag' dl)>  (?'text' .*?(?:((?R)).*?)?)  <\/\g{tag}>/sux;
my $html_faq_div = qr/<(?'tag' faq-\w+)>  (.*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_head1 = qr/<(?'tag' h1)>  (.*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_head2 = qr/<(?'tag' h2)>  (.*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_head3 = qr/<(?'tag' h3)>  (.*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_head4 = qr/<(?'tag' h4)>  (.*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_head5 = qr/<(?'tag' h5)>  (.*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;
my $html_head6 = qr/<(?'tag' h6)>  (.*?(?:((?R)).*?)?)  <\/\g{tag}>/ux;

#THE FOLLOWING ARE PARAGRAPH-MATCHING BLOCKS FOR USE WHEN SEPARATING ADJACENT PARAGRAPHS WITHIN A TEXT
my $html_block = qr/(<(?'tag'[\w-]+)(?:\h[^>]*)?>(.*?(?:(?'inner'(?R)).*?)?)<\/\g{tag}>)/ux;
my $block_list = qr/(?(DEFINE)(?'delineator'[\x{002D}\x{2010}-\x{2015}\x{2212}\x{FE63}\x{FF0D}.;:]))
                    (?! <\w+ (\h+ .+)*>)
                    (?P<list>
                        ^ (?P<indent>\h+)*+ 

                        (?P<item>
                            (?P<open>  [ \[\(\{\⟨\< ] (?P<space> \h+ )?   )?
                            (?:   (?P<section> (?:[A-Za-z]+\.)+) |  (?P<bullet> [^ \[\(\{\⟨\< \w\s]++)  |  (?P<char>   (?P<alpha> [A-Za-z]++)  |  (?P<numer> \d++[A-Za-z]?)) (?P>delineator)  )
                            (?P<close>  (?(<open>)  (?(<space>) \h+ )  [ \>\]\)\}\⟩ ]  |  (?(<char>)  (?:[ \>\]\)\}\⟩ ]  |  \h*(?P>delineator) ) )  )
                        )
                        \h* .+
                    )

                    (?P<line>
                        \n{1,2} ^
                        (?(?!\s+)
                            (?(<open>) (?P=open) | )
                            (?(<char>)   (?(<alpha>) [A-Za-z]+ | \d+ )((?P>delineator)?\w+)*  |  (?: (?P=bullet)|(*FAIL) ))
                            (?P=close)
                        )
                    \h* .+
                    )*
                    )/ux;
my $offset_block = qr/\h+ \V+  (?: \v ^ \h+ \w++ \V+)++/ux;
my $block_par = qr/(?: (?!\h) \V+ (?: \v (?!\h) \V+)*+ )/ux;
my $indent_par = qr/\h+ \V+  (?: \v (?!\h) \V+ | (?=\v(?:\v|\h|\Z)) )++/ux;
my $catch_all = qr/\h* \V+/ux;


my %formats = (
    #grouping of words delineated by whitespace
    '010_flat_clause' => qr/$flat_clause/ux,

    #several clauses separated by commas
    '011_comma_clause' => qr/$comma_clause/ux,

    #list of three or more items, delineated by [,;]
    '020_semicolon_list' => qr/$semicolon_list/ux,

    #one or more clauses, ending in   [:]   followed by a [linear_list]
    '031_sentence_list' => qr/$sentence_list/ux,

    #any complex clause that opens and closes with a bracket
    '032_bracket_clause' => qr/$bracket_clause/ux,

    #complex clause contained in double-quotes
    '033_quote_clause' => qr/$quote_clause/ux,

    #sentence preceded by     one word or more words followed by a delineating symbol or [\s]
    '070_dialog' => qr/$dialog/ux,

    #fragment containing a date- or time-stamp
    '080_dateline' => qr/$dateline/ux,

    #fragment in all capitals or with trailing vertical whitespace
    '081_title' => qr/$title/ux,

    #sequence of capitalized words    or    [A-Z] followed by a [.]
    '082_name' => qr/$name/ux,

    #matches text tagged with <b></b>
    '090_bold' => qr/$html_bold/ux,

    #matches text tagged with <i></i>
    '091_italic' => qr/$html_italic/ux,

    #matches text tagged with <strong></strong>
    '092_under' => qr/$html_under/ux,

    #matches text tagged with <strong></strong>
    '093_strong' => qr/$html_strong/ux,

    '094_title' => qr/$html_title/ux,

    #matches text tagged with <table></table>
    '095_table' => qr/$html_table/ux,

    '096_ulist' => qr/$html_ulist/ux,

    '097_olist' => qr/$html_olist/ux,

    '098_dlist' => qr/$html_dlist/ux,

    #matches text tagged with <faq-[...]></faq-[...]>
    '099_faq_div' => qr/$html_faq_div/ux,

    '100_h1' => qr/$html_head1/ux,

    '101_h2' => qr/$html_head2/ux,

    '102_h3' => qr/$html_head3/ux,

    '103_h4' => qr/$html_head4/ux,

    '104_h5' => qr/$html_head5/ux,

    '105_h6' => qr/$html_head6/ux,

    #single complete sentence, must end in   [.?!]   or   ["”] followed by [\s][A-Z] or end of text
    '200_sentence' => qr/$sentence/ux,

    #one or more sentences
    '210_paragraph' => qr/$paragraph/ux,

    #single alphanumeric chain followed by a delineating symbol    or    symbol followed by [\s]
    '220_block_list' => qr/$block_list/ux,
);



sub separate {
    my $tree = shift;
    my (@extracted, @nodes);

    @nodes = $tree->elementify->find('body')->detach_content;

    @extracted = extract(@nodes);

    my $paragraph_match = qr/((?| (?: $html_block )
                                | (?: $block_list )
                                | (?: $offset_block )
                                | (?: $block_par )
                                | (?: $indent_par )
                                | (?: $catch_all )
                              )
                              (?: \v{2,} | \v (?=\h) | \Z))/mux;

    my @paragraphs;
    for my $chunk ( @extracted ) {
        while ($chunk =~ m/$paragraph_match/gmuxs) {
            chomp( my $par = $1 );

            push @paragraphs => $par if $par =~ /\S/;
        }
    }

    return @paragraphs;
}



sub extract {
  my @nodes = @_;

  my @paragraphs;
  NODE: for my $node ( @nodes ) {
    my $tag = ($node->can('tag') ? $node->tag() // '' : '');

    if ( !$node->can('descendants') ) {
        push @paragraphs => $node;

    } elsif ( $tag eq 'table' ) {
        my @header = $node->find('thead');
        my @body = $node->find('tbody');
        my @footer = $node->find('tfoot');
        my $concat = '';

        for ( @header ) {
            $concat .= (join " " => map { extract($_) } map { $_->detach_content } $node->find('th')->detach_content) . "\n" for $node->find('tr');
        }

        for ( pairwise { $b ? ($a, $b) : ($a) } @body, @footer ) {
            $concat .= (join " " => grep { /./ } map { $_ =~ s/\v|^\s+$//r } map { extract($_) } map { $_->detach_content } $_->find('td')) . "\n" for $node->find('tr');
        }

        push @paragraphs => "<$tag>$concat</$tag>";

    } elsif ( $tag eq 'ul' or $tag eq 'ol' ) {
        my $table_string = "<$tag>" . (join "\n" => map { extract($_) } map { $_->detach_content } $node->find('li')) . "</$tag>";
        push @paragraphs => $table_string;

    } elsif ( $tag eq 'dl' ) {
        my $table_string = "<$tag>" . (join "\n" => map { join "\ " => ($_[0]->as_text, $_[1]->as_text) } pairs $node->find('dt', 'dd')) . "</$tag>";
        push @paragraphs => $table_string;

    } elsif ( $tag eq 'div' and (my $class = $node->attr('class')) =~ /^faq-\w+$/ ) {
        my @content = $node->detach_content;
        my $concat = '';
        for ( @content ) {
            if ( $_->can('descendants') and $_->descendants ) {
                $concat = "<$class>$concat</$class>";
                push @paragraphs => $concat;
                push @paragraphs => extract($_->detach_content);
                $concat = '';
            } else {
                $concat .= join " " => extract($_);
            }
        }
        $concat = "<$class>$concat</$class>";
        push @paragraphs => $concat;

    } elsif ( $tag eq 'a' ) {
        my $parent = $node->parent;
        next NODE unless $parent;
        $node->replace_with_content;
        my @content = extract($node);
        push @paragraphs => @content;

    } elsif (   $tag eq 'b' or 
                $tag eq 'i' or 
                $tag eq 'u' or 
                $tag eq 'strong' or 
                $tag eq 'title' or 
                $tag =~ /h\d/
            ) {

        my @content = extract($node->content_list);
        if (@content) {
            $node->destroy_content;
            $node->push_content(@content);
        }

        push @paragraphs => $node->as_XML;

    } elsif ( $tag eq 'code' ) {
        push @paragraphs => $node->as_XML;

    } elsif ( $tag eq 'br' ) {
        push @paragraphs => "\n";

    } else {
        push @paragraphs => ( join "" => extract($node->content_list) );
    }
  }

  return @paragraphs;
}



sub typify {
    my $text = shift;

    open( my $temp, "+>:encoding(UTF-8)", "temp/raw.txt" ) or die "Can't open +> 'temp/raw.txt': $!";
    print $temp $text;
    close $temp;

    my $markup_parser = Text::Markup->new( default_format => 'markdown' );
    my $html = $markup_parser->parse(file => "temp/raw.txt");
    my $tree = HTML::TreeBuilder->new->parse_content($html);

    my @paragraphs = separate $tree;

    my @category;
    CHUNK: for my $chunk (@paragraphs) {
        my @type;

        decode_entities($chunk);

        TEST: for my $format (sort { substr($a,0,3) <=> substr($b,0,3) or $a cmp $b } keys %formats) {
            my $pattern = qr/$formats{ $format }/;
            my @scraps;

            while ( $chunk =~ m/($pattern)/gmuxs ) {
                push @scraps => $+{text} // $1;
            }

            push @type, ($format => \@scraps) if @scraps;
        }

        push @type, ('fragment' => \$chunk) unless @type;
        push @category => \@type;
    }

    my @zipped = zip @paragraphs, @category;

    return @zipped;
}



1;
__END__