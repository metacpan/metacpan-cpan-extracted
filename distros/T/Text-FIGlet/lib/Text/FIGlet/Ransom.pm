package Text::FIGlet::Ransom;
require 5;
use strict;
use vars qw/$VERSION @ISA/;
use Carp 'croak';
$VERSION = 2.17;
@ISA = 'Text::FIGlet::Font';

#Roll our own for 5.005, and remove somewhat heavy List::Util dependency
sub max{ (sort @_)[-1]; }
sub sum{ my $cnt; $cnt += $_ foreach @_; return $cnt}

sub new{
  shift();
  my $self = {-U=>0, -v=>'center', -m=>-1, @_};
  my(@fonts, %fonts);


  if( ref($self->{-f}) eq 'HASH' ){
    croak "No default specified" unless defined($self->{-f}->{undef});
    croak "Insufficient number of fonts, 2 or more please" unless keys(%{$self->{-f}}) > 1;
    $self->{_fonts} = [delete($self->{-f}->{undef}), keys %{$self->{-f}}];
  }
  else{
    croak "Insufficient number of fonts, 2 or more please" unless scalar(@{$self->{-f}}) > 1;
    $self->{_fonts} = $self->{-f};
  }


  #Load the fonts
  my $x =0;
  foreach my $font ( @{$self->{_fonts}} ){
      push(@fonts, Text::FIGlet::Font->new(%$self, -f=>$font));
      $fonts{$font} = $x++;
  }


  #Synthesize a header
  #Hardblank = DEL
  $self->{_header}->[0] = "\x7F";
  #Height
  $self->{_header}->[1] = max( map {$_->{_header}->[1]} @fonts );
  #Base height
  $self->{_header}->[2] = max( map {$_->{_header}->[2]} @fonts );
  #Max glyph width
  $self->{_header}->[3] = $self->{_maxLen} = max( map {$_->{_maxLen}} @fonts );
  #Smush = none
  $self->{_header}->[4] = 0;
  #Comment line count, calculated when dumping @_ ... include chr to font mapping?
  #R2L = false
  $self->{_header}->[6] = 0;

  if( $self->{-v} eq 'base' ){
    my $descender = max( map {$_->{_header}->[1] - $_->{_header}->[2]} @fonts );
    $self->{_header}->[1] = $self->{_header}->[2] + $descender;
  }


  #Assemble the body
  for(my $i=32; $i<127; $i++ ){
    my($c, $R);
    if( ref($self->{-f}) eq 'HASH' ){
      while( my($k,$v) = each(%{$self->{-f}}) ){
	if( chr($i) =~ /$v/ ){
	  $c = $fonts[$R=$fonts{$k}]->{_font}->[$i];
	  #Reset counter, may be more trouble than the short-circuit is worth
	  keys %{$self->{-f}};
	  last;
	}
      }
      $c = $fonts[$R=0]->{_font}->[$i] unless $c;
    }
    else{
      $R = rand(scalar(@fonts));
      $c = $fonts[$R]->{_font}->[$i];
      $self->{_map}->[$R] .= chr($i);
    }

    #Vertical-alignment & padding
    if( my $delta = $self->{_header}->[1] - $fonts[$R]->{_header}->[1] ){
      #Parens around qw for 5.005
      local($self->{-v}) = (qw/top center center bottom/)[rand(4)]
	if $self->{-v} eq 'random';


      my $ws = $self->{-m} == 0 ? $c->[0] : sum(@$c[0,1,2]);
      if( $self->{-v} eq 'top' ){
	push(@$c, (' 'x$ws)x$delta);
      }
      elsif( $self->{-v} eq 'baseline' ){
	my $t = $self->{_header}->[2] - $fonts[$R]->{_header}->[2];
	my $b = $self->{_header}->[1] - $fonts[$R]->{_header}->[1] - $t;
	splice(@$c, 3, 0, (' 'x$ws)x$t) if $t;
	push(@$c, (' 'x$ws)x$b) if $b;
      }
      elsif( $self->{-v} eq 'bottom' ){
	splice(@$c, 3, 0, (' 'x$ws)x$delta);
      }
      elsif( $self->{-v} eq 'center' ){
	my $t = int($delta/2);
	my $b = $delta - $t;
	splice(@$c, 3, 0, (' 'x$ws)x$t) if $t;
	push(@$c, (' 'x$ws)x$b) if $b;
      }
    }


    #XXX -m... freeze/thaw? horizontally center w/ padding -height..-1

    #Common hardblank
    my $iHard=$fonts[$R]->{_header}->[0];
    foreach my $j(-$self->{_header}->[1]..-1){
      $c->[$j]=~ s/$iHard/$self->{_header}->[0]/g;
      #$c->[$j].= Text::FIGlet::UTF8len($c->[$j]);
    }

    $self->{_font}->[$i] = $c;
  }

  bless($self);
}

sub freeze{
    my $self = shift;
    my $font;

    foreach my $opt ( sort grep {/^-/} keys %{$self} ){
	my $val = $self->{$opt};
	if( ref($val) eq 'ARRAY' ){
	    $val = '[qw/'. join(' ', @$val) . '/]';
	    if( $opt eq '-f' ){
		for(my $f=0; $f< scalar @{$self->{_map}}; $f++ ){
		    $val .= "\n#\tfont$f $self->{_map}->[$f]";
		    $self->{_header}->[5]++;
		}
	    }
	}
	elsif( ref($val) eq 'HASH' ){
	    $val = '{undef,'. $self->{_fonts}->[0] .','. join(',',%{$val}) .'}';
	}
	$font .= sprintf "#%s => %s\n", $opt, $val;
	$self->{_header}->[5]++;
    }

    $font = sprintf("flf2a%s %s %s %s %s %s %s\n", @{$self->{_header}}). $font;

    for(my $i=32; $i<= scalar @{$self->{_font}}; $i++ ){
	my $c = $self->{_font}->[$i];
	foreach my $j(-$self->{_header}->[1]..-1){
	    $font .= $c->[$j] . ($j<-1?"\x1F\n":"\x1F\x1F\n");
	}
    }
    return $font;
}

1;
__END__
=pod

=head1 NAME

Text::FIGlet::Ransom - blended/composite font support for Text:FIGlet

=head1 SYNOPSIS

  use Text::FIGlet;

  my $ransom = Text::FIGlet->new(-f=>[ qw/big block banner/ ]);

  print $ransom->figify("Hi mom");

             _
  _|    _|  (_) #    #        #    #
  _|    _|   _  ##  ##   ___  ##  ##
  _|_|_|_|  | | # ## #  / _ \ # ## #
  _|    _|  | | #    # | (_) |#    #
  _|    _|  |_| #    #  \___/ #    #
                #    #        #    #

=head1 DESCRIPTION

This class creates a new FIGlet font using glyphs from user-specified fonts.
Output from the resulting hybrid font is suitable for basic textual CAPTCHA,
but also has artistic merit. As the output is automatically generated though,
some manual adjustment may be necessary; particularly since B<Text::FIGlet>
still does not support smushing.

=head2 TODO

=over

=item Treat 0x20 specially?

=item Unicode support...

=back

=head1 OPTIONS

=head2 C<new>

Loads the specified set of fonts, and assembles glyphs from them to create
the new font.

Except where otherwise noted below, options are inherited from
L<Text::FIGlet::Font>.

=over

=item B<-f=E<gt>>I<\@fonts> | I<\%fonts>

The array reference form accepts a reference to a list of fonts to use
in constructing the new font. When the object is instantiated B<Ransom>
iterates over all of the codepoints, randomly copying the glyph for that
index from one of the specified fonts.

The hash form accepts a reference to a hash with fonts as keys, and
regular expressions as values. If a character matches the supplied regular
expression, the glyph for that character is copied from the corresponding
font. In addition, a default font to pull glyphs from B<must be included>,
but it is specified in reverse, with a I<key> of C<undef> and the font as
the I<value>.

  Text::FIGlet->new(-f=>{block=E<gt>qr/[ A-Z]/, undef=>'lean'})

  _|_|_|_|_|                          __
      _|         _____  ____  ____   / /
      _|        / ___/ / __ \/_  /  / /
      _|       / /    / /_/ / / /_ /_/
      _|      /_/     \____/ /___/(_)


In the text above, I<font> means any value accepted by the B<-f> parameter
of C<Text::FIGlet::new>.

In either form, an error occurs if less than 2 fonts are given.

=item B<-U=E<gt>>I<boolean>

Not yet implemented.

A true value is necessary to load Unicode font data,
regardless of your version of perl. B<The default is false>.

B<Note that you must explicitly specify I<1> if you are mapping in negative
characters with a control file>. Otherwise, I<-1> is more appropriate.
See L<Text::FIGlet::Font/CAVEATS> for more details.

=item B<-v>=E<gt>'I<vertical-align>'

Because fonts vary in size, it is necessary to provide vertical padding
around smaller glyphs, and this option controls how the padding is added.
The default is to S<center> the glyphs.

=over

=item I<top>

Align the tops of the glyphs

=item I<center>

Align the center of the glyphs

=item I<baseline>

Align the the base of the glyphs i.e; align characters such as "q" and "p"
as if they had no descenders, thusly having their loops in line with "o".

=item I<bottom>

Align the bottom of the glyphs

=item I<random>

Randomly select an alignment for each character when assembling the font.

For code simplicity I<baseline> is not one of the random alignments used,
and instead I<center> is twice as likely for an overall distribution of
25% I<top>, 50% I<center> and 25% I<bottom>.

=back

=back

=head2 C<figify>

Inherited from L<Text::FIGlet::Font>.

=head2 C<freeze>

Returns a string containing the current font. This allows for the preservation
of the current (random) font for reuse, and to avoid the performance penalty
incurred upon B<Ransom>-ization.

To cope with the vagaries of input font formatting, a frozen B<Ransom> font has
hardblank & endmark characters converted to DEL (x7F) and US (x1F) respectively.

The frozen font also includes as comments the parameters used to create it.
The comments for random ARRAYREF fonts, a map of which characters are pulled
from which source font.

=head1 ENVIRONMENT

B<Text::FIGlet::Ransom>
will make use of these environment variables if present

=over

=item FIGLIB

The default location of fonts.
If undefined the default is F</usr/games/lib/figlet>

=back

=head1 CAVEATS

B<Ransom> does not work well with B<-m> modes other than I<-1> & I<0> at this time.

As noted above, though it is easy to overlook, B<Ransom> only supports ASCII input.

Very few so-called "monospace" display fonts are fixed-width across all
codepoints, and the results of mixing FIGlet and TOIlet fonts may be
mangled in such a font. Some true monspace fonts include Bitstream Monospace
and GNU FreeFont FreeMono. OCR A Std and OCR B MT also work at 9, 11 and 12
points, but not 10.

=head1 SEE ALSO

L<Text::FIGlet::Font>, L<Text::FIGlet>, L<figlet(6)>

=head1 AUTHOR

Jerrad Pierce

                **                                    />>
     _         //                         _  _  _    / >>>
    (_)         **  ,adPPYba,  >< ><<<  _(_)(_)(_)  /   >>>
    | |        /** a8P_____88   ><<    (_)         >>    >>>
    | |  |~~\  /** 8PP"""""""   ><<    (_)         >>>>>>>>
   _/ |  |__/  /** "8b,   ,aa   ><<    (_)_  _  _  >>>>>>> @cpan.org
  |__/   |     /**  `"Ybbd8"'  ><<<      (_)(_)(_) >>
               //                                  >>>>    /
                                                    >>>>>>/
                                                     >>>>>

=cut
