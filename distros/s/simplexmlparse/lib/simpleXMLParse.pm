package simpleXMLParse;

# Perl Module: simpleXMLParse
# Author: Daniel Edward Graham
# Copyright (c) Daniel Edward Graham 2008-2018
# Date: 01/01/2018
# License: LGPL 3.0
# 

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Data::Dumper;
@ISA = qw(Exporter);

# This allows declaration	use simpleXMLParse ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '3.1';

use Carp;
use strict;
no warnings;

#use open ':encoding(utf8)';

my @cdata;
my $cdataInd = 0;
my $MAXIND = 10000;

sub new {
    my $class = shift;
    my %args = (@_ == 1) ? ((ref($_[0]) eq 'HASH') ? %{$_[0]}:(input => $_[0])):@_;
    my $altstyle = 0;
    my $fn;
    $fn = $args{"input"};
    $altstyle = 1 if ($args{"style"} eq '2');
    my $self = {};
    $self->{"xml"}  = undef;
    $self->{"data"} = undef;
    open (INFILE1, "$fn") or croak "Unable to process [$fn] $! \n";
    binmode(INFILE1);
    my ($c1, $c2, $c3);
    read(INFILE1, $c1, 1);
    read(INFILE1, $c2, 1);
    read(INFILE1, $c3, 1);
    close(INFILE1);
    if (($c1 eq "\xFE" && $c2 eq "\xFF") || ($c1 eq "\xFF" && $c2 eq "\xFE")) {
        # UTF-16
        open(INFILE, '<:encoding(UTF-16)', "$fn") or croak "Unable to process [$fn] $!\n";
        $self->{"xml"} = join '', <INFILE>;
    } else {
	if ($c1 eq "\xEF" && $c2 eq "\xBB" && $c3 eq "\xBF") {
	    # UTF-8 with BOM...
            open(INFILE, '<:encoding(UTF-8)', "$fn") or croak "Unable to process [$fn] $!\n";
            my $str = join '', <INFILE>;
#	    $str =~ s/^\xEF\xBB\xBF//g;
	    $str =~ s/^\x{fffe}//g;
	    $str =~ s/^\x{feff}//g;
            $self->{"xml"} = $str;
	 } else {
	    # UTF-8 with NO BOM
            open(INFILE, '<:encoding(UTF-8)', "$fn") or croak "Unable to process [$fn] $!\n";
            $self->{"xml"} = join '', <INFILE>;
	  }
       }
    close(INFILE);
    $self->{"data"} = _ParseXML( $self->{"xml"}, $altstyle );
    my $ret = bless $self;
    if ($altstyle) {
        $ret->_convertToStyle();
    }
    $cdataInd = $cdataInd % $MAXIND;
    return $ret;
}

sub parse {
    my $self = shift;
    return $self->{data};
}

sub _convertToStyle {
    my $self = shift;
    my @recursearr = ($self->{"data"});
    while (@recursearr) {
        my $i = pop @recursearr;
        if (ref($i) eq "HASH") {
            foreach my $j (keys %$i) {
                if ($j =~ /^(.*?)\_(.*?)\_([0-9]+)\_attr$/) {
                    my ($attrnm, $tagnm, $cnt) = ($1, $2, $3);
                    $attrnm =~ s/0x0/_/gs;
                    $tagnm =~ s/0x0/_/gs;
                    my $n = undef;
                    if (ref($i->{$tagnm}) eq "ARRAY") {
                        my $hold;
                        if (ref($i->{$tagnm}->[$cnt]) eq '') {
                            $hold = $i->{$tagnm}->[$cnt];
                            $i->{$tagnm}->[$cnt] = { };
                            if ($hold !~ /^\s*$/ ) {
                                $i->{$tagnm}->[$cnt]->{content} = $hold;
                            }
                        }      
                        while (defined($i->{$tagnm}->[$cnt]->{$attrnm.$n})) {
                            $n++;
                        }
                        $i->{$tagnm}->[$cnt]->{$attrnm.$n} = $i->{$j};
                     } else {
                         if (ref($i->{$tagnm}) eq "HASH") { 
                             my $n = undef;
                             while (defined($i->{$tagnm}->{$attrnm.$n})) {
                                $n++;
                             }
                             $i->{$tagnm}->{$attrnm.$n} = $i->{$j};
                         } else {
                             my $hold;
                             $hold = $i->{$tagnm};
                             $i->{$tagnm} = { };
                             if ($hold !~ /^\s*$/) {
                                 $i->{$tagnm}->{content} = $hold;
                             }
                             $i->{$tagnm}->{$attrnm} = $i->{$j};
                         }
                     }
                     delete $i->{$j};
               } else {
                   push @recursearr, $i->{$j};
               }
           }
        } else {
            if (ref($i) eq "ARRAY") {
                foreach my $j (@$i) {
                    push @recursearr, $j;
                }
            }
       }
   }
}

sub _cdatasub {
    my $cdata = shift;
    my $tmpind = $cdataInd++;
    $cdata[$tmpind] = $cdata;
    return "0x0CDATA0x0".($tmpind)."0x0";
} 
    
sub _cdatasubout {
    my $ind = shift; 
    my $cdata = $cdata[$ind];
    return $cdata;
} 

sub _unescp {
    my $firsttag = shift;
    $firsttag =~ s/\\\\/\\/gs;
    $firsttag =~ s/\\\*/\*/gs;
    $firsttag =~ s/\\\|/\|/gs;
    $firsttag =~ s/\\\$/\$/gs;
    $firsttag =~ s/\\\?/\?/gs;
    $firsttag =~ s/\\\{/\{/gs;
    $firsttag =~ s/\\\}/\}/gs;
    $firsttag =~ s/\\\(/\(/gs;
    $firsttag =~ s/\\\)/\)/gs;
    $firsttag =~ s/\\\+/\+/gs;
    $firsttag =~ s/\\\[/\[/gs;
    $firsttag =~ s/\\\]/\]/gs;
    $firsttag =~ s/\\\./\./gs;
    $firsttag =~ s/\\\^/\^/gs;
    $firsttag =~ s/\\\-/\-/gs;
    return $firsttag;
}

sub hconv {
    my $arg = $_[0];
    my $p = pack "H*", $arg;
    return $p;
}

sub _entity {
    my $text = shift;
    $text =~ s/\&lt\;/\</g;
    $text =~ s/\&gt\;/\>/g;
    $text =~ s/\&amp\;/\&/g;
    $text =~ s/\&apos\;/\'/g;
    $text =~ s/\&quot\;/\"/g;
    $text =~ s/\&\#x([0-9a-fA-F]+)\;/&hconv($1)/ge;
    return $text;
}

sub _ParseXML {
    my ($xml, $altstyle) = @_;
#    $xml =~ s/\n//g;
    $xml =~ s/\<\!\[CDATA\[(.*?)\]\]\>/&_cdatasub($1)/egs;
    $xml =~ s/\<\!\-\-.*?\-\-\>//gs;
    $xml =~ s/\<\?xml.*?\?\>//gs;
    $xml =~ s/\<\?[^\>]*?\?\>//gs;
    $xml =~ s/\<\!\-\-[^\>]*?\-\-\>//gs;
    $xml =~ s/\<\!ELEMENT[^\>]*?\>//gs;
    $xml =~ s/\<\!ENTITY[^\>]*?\>//gs;
    $xml =~ s/\<\!ATTLIST[^\>]*?\>//gs;
    $xml =~ s/\<\!DOCTYPE[^\>]*?\>//gs;
    my $rethash = ();
    my @retarr;
    my $firsttag = $xml;
    my ( $attr, $innerxml, $xmlfragment );
    $firsttag =~ s/^[\s\n]*\<([^\s\>\n\/]*).*$/$1/gs;
    $firsttag =~ s/\\/\\\\/gs;
    $firsttag =~ s/\*/\\\*/gs;
    $firsttag =~ s/\|/\\\|/gs;
    $firsttag =~ s/\$/\\\$/gs;
    $firsttag =~ s/\?/\\\?/gs;
    $firsttag =~ s/\{/\\\{/gs;
    $firsttag =~ s/\}/\\\}/gs;
    $firsttag =~ s/\(/\\\(/gs;
    $firsttag =~ s/\)/\\\)/gs;
    $firsttag =~ s/\+/\\\+/gs;
    $firsttag =~ s/\[/\\\[/gs;
    $firsttag =~ s/\]/\\\]/gs;
    $firsttag =~ s/\./\\\./gs;
    $firsttag =~ s/\^/\\\^/gs;
    $firsttag =~ s/\-/\\\-/gs;

    if ( $xml =~ /^[\s\n]*\<${firsttag}(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*?)\<\/${firsttag}[\s\n]*\>(.*)$/s )
    {
        $attr        = $1;
        $innerxml    = $2;
        $xmlfragment = $3;
        $attr =~ s/\>$//gs;
    }
    else {
      if ( $xml =~ /^[\s\n]*\<${firsttag}(\/\>|[\s\n][^\>]*\/\>)(.*)$/s ) {
        $attr = $1;
        $innerxml = "";
        $xmlfragment = $2;
        $attr =~ s/\/\>$//gs;
      } else {
        if (!ref($xml)) {
            $xml = _entity($xml);
            $xml =~ s/0x0CDATA0x0(\d+?)0x0/&_cdatasubout($1)/egs;
        }
        if ($xml eq '') {
            return {};
        } else {
            return $xml;
        }
      }
    }
    my $ixml = $innerxml;
    while ($ixml =~ /^.*?\<${firsttag}(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*?)$/s) {
        $ixml = $2;
        $innerxml .= "</${firsttag}>";
        if ($xmlfragment =~ /^(.*?)\<\/${firsttag}[\s\n]*\>(.*)$/s) {
            my $ix = $1;
            $innerxml .= $ix;
            $ixml .= $ix; 
            $xmlfragment = $2;
        } else {
            die "Invalid XML innerxml: $innerxml\nixml: $ixml\nxmlfragment: $xmlfragment\n";
        }
    }        
    my $nextparse = _ParseXML($innerxml, $altstyle);
    $rethash->{&_unescp($firsttag)} = $nextparse;
    my @attrarr;
    while ( $attr =~ s/^[\s\n]*([^\s\=\n]+)\s*\=\s*(\".*?\"|\'.*?\')(.*)$/$3/gs ) {
        my ($name, $val) = ($1, $2);
        $val =~ s/^\'(.*)\'$/$1/gs;
        $val =~ s/^\"(.*)\"$/$1/gs;
        push @attrarr, $name;
        push @attrarr, _entity($val);
    }
    my $attrcnt = 0;
    while ( my $val = shift(@attrarr) ) {
        my ($val1, $firsttag1) = ($val, $firsttag);
        if ($altstyle) {
            $val1 =~ s/_/0x0/gs;
            $firsttag1 =~ s/_/0x0/gs;
        }
        $rethash->{ "$val1" . "_".&_unescp(${firsttag1})."_" . $attrcnt . "_attr" } = shift(@attrarr);
    }
    my $retflag = 0;
    my ( $xmlfragment1, $xmlfragment2 );
    my %attrhash;
    $attrcnt++;
    while (1) {
        if ( $xmlfragment =~
            /^(.*?)\<${firsttag}(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*?)\<\/${firsttag}[\s\n]*\>(.*)$/s )
        {
            if ( !$retflag ) {
                push @retarr, $nextparse;
            }
            $retflag      = 1;
            $xmlfragment1 = $1;
            $attr         = $2;
            $innerxml     = $3;
            $xmlfragment2 = $4;
        } else {
          if ( $xmlfragment =~ /^(.*?)\<${firsttag}(\/\>|[\s\n][^\>]*\/\>)(.*)$/s ) {
            if ( !$retflag ) {
                push @retarr, $nextparse;
            }
            $retflag      = 1;
            $xmlfragment1 = $1;
            $attr = $2;
            $innerxml = "";
            $xmlfragment2 = $3;
          } else {
            last;
          }
        }
        $attr =~ s/\/\>$//gs;
        $attr =~ s/\>$//gs;
        my %opening = ( );
        my %closing = ( );
        my $frag = $xmlfragment1;
        while ($frag =~ /^(.*?)\<([^\s\n\/\>]+)(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*)$/s) {
            my $tg = $2;
            $frag = $4;
            $opening{$tg}++;
        }
        my $frag = $xmlfragment1;
        while ($frag =~ /^(.*?)\<\/([^\s\n\>]+)[\s\n]*\>(.*)$/s) {
            my $tg = $2;
            $frag = $3;
            $closing{$tg}++;
        }
        my $frag = $xmlfragment1;
        while ($frag =~ /^(.*?)\<([^\s\n\/\>]+)[^\>]*?\/\>(.*)$/s) {
            my $tg = $2;
            $frag = $3;
            $opening{$tg}++;
            $closing{$tg}++;
        }
        my $flag = 0;
        foreach my $k (keys %opening) {
            if ($opening{$k} > $closing{$k}) {
                $xmlfragment = $xmlfragment1 . "<${firsttag}0x0 ${attr}>${innerxml}</${firsttag}0x0>". $xmlfragment2;
                $flag = 1;
                last;
            }
        }
        next if ($flag);
        my $ixml = $innerxml;
        while ($ixml =~ /.*?\<${firsttag}(\>|[\s\n]\>|[\s\n][^\>]*[^\/]\>)(.*?)$/s) {
            $ixml = $2;
            $innerxml .= "</${firsttag}>";
            if ($xmlfragment2 =~ /(.*?)\<\/${firsttag}[\s\n]*\>(.*)$/s) {
                my $ix = $1;
                $innerxml .= $ix;
                $ixml .= $ix;
                $xmlfragment2 = $2;
            } else {
                die "Invalid XML";
            }
        }        
        $xmlfragment  = $xmlfragment1 . $xmlfragment2;
        while ( $attr =~ s/^[\s\n]*([^\s\=\n]+)\s*\=\s*(\".*?\"|\'.*?\')(.*)$/$3/gs ) {
            my ($name, $val) = ($1, $2);
            $val =~ s/^\'(.*)\'$/$1/gs;
            $val =~ s/^\"(.*)\"$/$1/gs;
            push @attrarr, $name;
            push @attrarr, _entity($val);
        }
        while ( my $val = shift(@attrarr) ) {
            my ($val1, $firsttag1) = ($val, $firsttag);
            if ($altstyle) {
                $val1 =~ s/_/0x0/gs;
                $firsttag1 =~ s/_/0x0/gs;
            }
            $rethash->{ "$val1" . "_".&_unescp(${firsttag1})."_" . $attrcnt . "_attr" } = shift(@attrarr);
        }
        $attrcnt++;
        $nextparse    = _ParseXML($innerxml, $altstyle);
        push @retarr, $nextparse;
    }
    if (@retarr) {
        if (@retarr == 1) {
            $rethash->{_unescp($firsttag)} = $retarr[0];
        } else {
            $rethash->{_unescp($firsttag)} = \@retarr;
        }
    }
    $xmlfragment =~ s/${firsttag}0x0/${firsttag}/gs;
    my $remainderparse = _ParseXML($xmlfragment, $altstyle);
    my $attrcnt;
    my $attrfrag;
    if ( ref($remainderparse) eq "HASH" ) {
        foreach ( keys %{$remainderparse} ) {
            $rethash->{&_unescp($_)} = $remainderparse->{&_unescp($_)};
        }
    }
    if ( keys %{$rethash} ) {
        return $rethash;
    }
    else {
#        return undef;
        return {};
    }
}

1;
__END__

=head1 NAME

simpleXMLParse - Perl extension for pure perl XML parsing 

=head1 SYNOPSIS

  use simpleXMLParse;
  use Data::Dumper;
  my $parse = new simpleXMLParse(input => $fn, style => $style);

  print Dumper($parse->parse());

=head1 DESCRIPTION

  simpleXMLParse currently handles everything including CDATA
  with the exception of DTD and DTD syntax

  style is "1" or "2".

=head2 EXPORT

  None by default.  

=head1 SEE ALSO

=head1 AUTHOR

Daniel Graham, E<lt>daniel@firstteamsoft.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2015 by Daniel Edward Graham

LGPL 3.0

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
