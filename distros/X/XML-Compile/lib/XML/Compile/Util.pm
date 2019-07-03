# Copyrights 2006-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Util;
use vars '$VERSION';
$VERSION = '1.63';

use base 'Exporter';

use warnings;
use strict;

my @constants  = qw/XMLNS SCHEMA1999 SCHEMA2000 SCHEMA2001 SCHEMA2001i/;
our @EXPORT    = qw/pack_type unpack_type/;
our @EXPORT_OK =
  ( qw/pack_id unpack_id odd_elements even_elements type_of_node
       escape duration2secs add_duration/
  , @constants
  );
our %EXPORT_TAGS = (constants => \@constants);

use constant
  { XMLNS       => 'http://www.w3.org/XML/1998/namespace'
  , SCHEMA1999  => 'http://www.w3.org/1999/XMLSchema'
  , SCHEMA2000  => 'http://www.w3.org/2000/10/XMLSchema'
  , SCHEMA2001  => 'http://www.w3.org/2001/XMLSchema'
  , SCHEMA2001i => 'http://www.w3.org/2001/XMLSchema-instance'
  };

use Log::Report 'xml-compile';
use POSIX  qw/mktime/;


sub pack_type($;$)
{      @_==1 ? $_[0]
    : !defined $_[0] || !length $_[0] ? $_[1]
    : "{$_[0]}$_[1]"
}


sub unpack_type($) { $_[0] =~ m/^\{(.*?)\}(.*)$/ ? ($1, $2) : ('', $_[0]) }


sub pack_id($$) { "$_[0]#$_[1]" }


sub unpack_id($) { split /\#/, $_[0], 2 }


sub odd_elements(@)  { my $i = 0; map {$i++ % 2 ? $_ : ()} @_ }
sub even_elements(@) { my $i = 0; map {$i++ % 2 ? () : $_} @_ }


sub type_of_node($)
{   my $node = shift or return ();
    pack_type $node->namespaceURI, $node->localName;
}


use constant SECOND =>   1;
use constant MINUTE =>  60     * SECOND;
use constant HOUR   =>  60     * MINUTE;
use constant DAY    =>  24     * HOUR;
use constant MONTH  =>  30.4   * DAY;
use constant YEAR   => 365.256 * DAY;

my $duration = qr/
  ^ (\-?) P (?:([0-9]+)Y)?  (?:([0-9]+)M)?  (?:([0-9]+)D)?
       (?:T (?:([0-9]+)H)?  (?:([0-9]+)M)?  (?:([0-9]+(?:\.[0-9]+)?)S)?
    )?$/x;

sub duration2secs($)
{   my $stamp = shift or return undef;

    $stamp =~ $duration
        or error __x"illegal duration format: {d}", d => $stamp;

    ($1 eq '-' ? -1 : 1)
  * ( ($2 // 0) * YEAR
    + ($3 // 0) * MONTH
    + ($4 // 0) * DAY
    + ($5 // 0) * HOUR
    + ($6 // 0) * MINUTE
    + ($7 // 0) * SECOND
    );
}


sub add_duration($;$)
{   my $stamp = shift or return;
    my ($secs, $min, $hour, $mday, $mon, $year) = gmtime(shift // time);

    $stamp =~ $duration
        or error __x"illegal duration format: {d}", d => $stamp;

    my $sign = $1 eq '-' ? -1 : 1;
    mktime
        $secs + $sign*($7//0)
      , $min  + $sign*($6//0)
      , $hour + $sign*($5//0)
      , $mday + $sign*($4//0)
      , $mon  + $sign*($3//0)
      , $year + $sign*($2//0)
}
1;
