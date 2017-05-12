#===============================================================================
#
#  DESCRIPTION:  Block CHANGES
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package WriteAt::CHANGES;
use strict;
use warnings;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

=pod
From 
 =CHANGES
 date (revnumber) (\t|\s{2,} ) revremark [authorinitials]

 =CHANGES :authorinitials('zag')
 06.04.2011(v0.15)[zag]   test text
 some text at line

to
        <revhistory>
              <revision>
                 <revnumber>v0.15</revnumber>
                 <date>Feb 10th 2011</date>
                 <authorinitials>zag</authorinitials>
                 <revremark>test text</revremark>
               </revision>
        </revhistory>
=cut

sub to_docbook {
    my ( $self, $to ) = @_;
    my $w = $to->w;
    $w->raw('<revhistory>');
    my $recs = $self->parse_content($self->{''});
    foreach my $rec (@$recs) {
        $w->raw('<revision>');
        while( my ($k, $v) = each %$rec) {
            next unless $k;
            $w->raw("<$k>");
            $w->print($v);
            $w->raw("</$k>");
        }
        $w->raw('</revision>');
    }
    $w->raw('</revhistory>');
}

sub parse_content {
    my $self = shift;
    my $txt = shift;
    my $r = do {
        use Regexp::Grammars;
        qr{
        \A .*? <[lines=line]>+ % ([\s\n]+) (^ = .* )?\Z
        #Sep 19th 2011(v0.7)[zag]   ¿¿¿¿¿¿ ¿ ¿¿¿¿¿¿¿
        <rule: line><nocontext:>^
                (?!=) <date=(.*?)> 
                \( <revnumber=(.*?)> \) 
                \[ <authorinitials=(\w+)> \] 
                <revremark=(.*?)>
        }xms
    };
    if ($txt =~ $r ) {
        return $/{lines}
    } else {
        die 'error parse CHANGES'
    }
}
1;

