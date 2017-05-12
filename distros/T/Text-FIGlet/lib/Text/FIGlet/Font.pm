package Text::FIGlet::Font;
use strict;
use vars qw($REwhite $VERSION);
use Carp qw(cluck confess);
use Symbol; #5.005 support
use Text::Wrap;
$VERSION = '2.19.3';

#'import' core support functions from parent with circular dependency
foreach( qw/UTF8len UTF8ord _canonical _no _utf8_on/){
  no strict 'refs';
  *$_ = *{'Text::FIGlet::'.$_};
}


sub new{
  shift();
  my $self = {_maxLen=>0, -U=>-1, -m=>-2, @_};
  $self->{-m} = -3 if defined($self->{-m}) && $self->{-m} eq '-0';
  $self->{-f} ||= $ENV{FIGFONT} || 'standard';
  $self->{-d} ||= $ENV{FIGLIB}  || '/usr/games/lib/figlet/';
  _load_font($self);
  bless($self);
}

sub _load_font{
  my $self = shift();
  my $font = $self->{_font} = [];
  my(@header, $header, $path, $ext);
  local($_);

#MAGIC minifig0
  $self->{_file} = _canonical($self->{-d}, $self->{-f}, qr/\.[ft]lf/,
			      $^O =~ /MSWin32|DOS/i);
  #XXX bsd_glob .[ft]lf
  $self->{_file} = (glob($self->{_file}.'.?lf'))[0] unless -e $self->{_file};

  #open(FLF, $self->{_file}) || confess("$!: $self->{_file}");
  $self->{_fh} = gensym;            #5.005 support
  eval "use IO::Uncompress::Unzip"; #XXX sniff for 'PK\003\004'instead?
  unless( $@ ){
      $self->{_fh} = eval{ IO::Uncompress::Unzip->new($self->{_file}) } ||
	  confess("No such file or directory: $self->{_file}");
  }
  else{
      open($self->{_fh}, '<'.$self->{_file}) || confess("$!: $self->{_file}");
      #$^W isn't mutable at runtime in 5.005, so we have to conditional eval
      #to avoid "Useless use of constant in void context"
      eval "binmode(\$fh, ':encoding(utf8)')" unless $] < 5.006;
  }
#MAGIC minifig1

  my $fh = $self->{_fh};  #5.005 support
  chomp($header = <$fh>); #5.005 hates readline & $self->{_fh} :-/
  confess("Invalid FIGlet 2/TOIlet font") unless $header =~ /^[ft]lf2/;

  #flf2ahardblank height up_ht maxlen smushmode cmt_count rtol
  @header = split(/\s+/, $header);
  $header[0] =~ s/^[ft]lf2.//;
  #$header[0] = qr/@{[sprintf "\\%o", ord($header[0])]}/;
  $header[0] = quotemeta($header[0]);
  $self->{_header} = \@header;

  if( defined($self->{-m}) && $self->{-m} eq '-2' ){
    $self->{-m} = $header[4];
  }

  #Discard comments
  <$fh> for 1 .. $header[5] || cluck("Unexpected end of font file") && last;

  #Get ASCII characters
  foreach my $i(32..126){
    &_load_char($self, $i) || last;
  }

  #German characters?
  unless( eof($fh) ){
    my %D =(91=>196, 92=>214, 93=>220, 123=>228, 124=>246, 125=>252, 126=>223);

    foreach my $k ( sort {$a <=> $b} keys %D ){
      &_load_char($self, $D{$k}) || last;
    }
    if( $self->{-D} ){
      $font->[$_] = $font->[$D{$_}] for keys %D;
      #removal is necessary to prevent 2nd reference to same figchar,
      #which would then become over-smushed; alas 5.005 can't delete arrays
      $#{$font} = 126; #undef($font->[$_]) for values %D;
    }
  }

  #ASCII bypass
  close($fh) unless $self->{-U};

  #Extended characters, with extra readline to get code
  until( eof($fh) ){
    $_ = <$fh> || cluck("Unexpected end of font file") && last;
    
    /^\s*$Text::FIGlet::RE{no}/;
    last unless $2;
    my $val = _no($1, $2, $3, 1);
    
    #Bypass negative chars?
    if( $val > Text::FIGlet->PRIVb && $self->{-U} == -1 ){
      readline($fh) for 0..$self->{_header}->[1]-1;
    }
    else{
      #Clobber German chars
      $font->[$val] = '';
      &_load_char($self, $val) || last;
    }
  }
  close($fh);


  #Fixed width
  if( defined($self->{-m}) && $self->{-m} == -3 ){
    my $pad;
    for(my $ord=0; $ord < scalar @{$font}; $ord++){
      next unless defined $font->[$ord];
      foreach my $i (-$header[1]..-1){
        #next unless exists($font->[$ord]->[2]); #55compat
        next unless defined($font->[$ord]->[2]);

	# The if protects from a a 5.6(.0)? bug
	$font->[$ord]->[$i] =~ s/^\s{1,$font->[$ord]->[1]}//
	  if $font->[$ord]->[1];

  	$pad = $self->{_maxLen} - UTF8len($font->[$ord]->[$i]);
#  	print STDERR "$pad = $self->{_maxLen} - UTF8len($font->[$ord]->[$i]);\n";
  	$font->[$ord]->[$i] = " " x int($pad/2) .
  	  $font->[$ord]->[$i] . " " x ($pad-int($pad/2));
      }
    }
  }
  #Full width
  elsif( defined($self->{-m}) && $self->{-m} == -1 ){
    for(my $ord=32; $ord < scalar @{$font}; $ord++){
      next unless defined $font->[$ord];
      foreach my $i (-$header[1]..-1){
	next unless $font->[$ord]->[$i];
	# The if protects from a a 5.6(.0)? bug
	$font->[$ord]->[$i] =~ s/^\s{1,$font->[$ord]->[1]}//
	  if $font->[$ord]->[1];
        substr($font->[$ord]->[$i], 0, 0, ' 'x$font->[$ord]->[1]);
        $font->[$ord]->[$i] .= ' 'x$font->[$ord]->[2];
      }
    }
  }
  #Kern glyph boxes
  elsif( !defined($self->{-m}) || $self->{-m} > -1 ){
    for(my $ord=32; $ord < scalar @{$font}; $ord++){
      next unless defined $font->[$ord];
      foreach my $i (-$header[1]..-1){
	next unless $font->[$ord]->[$i];
	# The if protects from a a 5.6(.0)? bug
	$font->[$ord]->[$i] =~ s/^\s{1,$font->[$ord]->[1]}//
	  if $font->[$ord]->[1];
      }
    }
  }
}


sub _load_char{
  my($self, $i) = @_;
  my $font = $self->{_font};
  my($length, $wLead, $wTrail, $end, $line, $l) = 0;
  
  $wLead = $wTrail = $self->{_header}->[3];

  my $fh = $self->{_fh}; #5.005 support
  
  my $REtrail;
  foreach my $j (0..$self->{_header}->[1]-1){
    $line = $_ = <$fh> ||
      cluck("Unexpected end of font file") && return 0;
    #This is the end.... this is the end my friend
    unless( $REtrail ){
      /(.)\s*$/;
      $end = $1;
      #The negative leading anchor is for term.flf 0x40
      $REtrail = qr/(?<!^)([ $self->{_header}->[0]]+)\Q$end{1,2}\E?\s*$/;
    }
    if( $wLead && s/^(\s+)// ){
      $wLead  = $l if ($l = length($1)) < $wLead;
    }
    else{
      $wLead  = 0;
    }
    if( $wTrail && /$REtrail/ ){
      $wTrail = $l if ($l = length($1)) < $wTrail;
    }
    else{
      $wTrail = 0;
    }
    $length = $l if ($l =                    UTF8len($_)
		     -(s/(\Q$end\E+)$/$end/&&UTF8len($1))  ) > $length;
    $font->[$i] .= $line;
  }
  #XXX :-/ stop trying at 125 in case of charmap in ~ or extended....
  $self->{_maxLen} = $length if $i < 126 && $self->{_maxLen} < $length;

  #Ideally this would be /o but then all figchar's must have same EOL
  $font->[$i] =~ s/\015|\Q$end\E{1,2}\s*\r?$//mg;
  $font->[$i] = [$length,#maxLen
		 $wLead, #wLead
		 $wTrail,#wTrail
		 split(/\r|\r?\n/, $font->[$i])];
  return 1;
}


sub figify{
    my $self = shift();
    my $font = $self->{_font};
    my %opts = (-A=>'', -X=>'', -x=>'', -w=>'', -U=>0, @_);
    my @buffer;
    local $_;

    $opts{-w} ||= 80;

    #Prepare the input
    $opts{-X} ||= $self->{_header}->[6] ? 'R' : 'L';
    if( $opts{-X} eq 'R' ){
	$opts{-A} = join('', reverse(split('', $opts{-A})));
    }

    $opts{-A} =~ y/\t/ /;
    $opts{-A} =~ s%$/%\n% unless $/ eq "\n";
    if( defined($self->{-m}) && $self->{-m} == -3 ){
	$Text::Wrap::columns = int($opts{-w} / $self->{_maxLen})+1;
	$Text::Wrap::columns =2 if $Text::Wrap::columns < 2;
	$opts{-A} = Text::Wrap::wrap('', '', $opts{-A});
	&Encode::_utf8_off($opts{-A}) if $] >= 5.008;
    }
    elsif( $opts{-w} > 0 ){
	&Encode::_utf8_off($opts{-A}) if $] >= 5.008;
	$Text::Wrap::columns = $opts{-w}+1;
	unless( $opts{-w} == 1 ){
	  ($_, $opts{-A}) = ($opts{-A}, '');
#	  $opts{-A} .= "\0"x(($font->[ ord($1) ]->[0]||1)-1) . $1 while /(.)/g;
	  while( $opts{-U} ?
		 /$Text::FIGlet::RE{UTFchar}/g :
		 /$Text::FIGlet::RE{bytechar}/g ){
	    $opts{-A} .= "\0"x(($font->[
					$opts{-U} ? UTF8ord($1) : ord($1)
				]->[0]||1)-1) . $1;
	  }
	}
	#XXX pre 5.8 Text::Wrap is not Unicode happy?
        $opts{-A} = Text::Wrap::wrap('', '', $opts{-A});
	$opts{-A} =~ tr/\0//d;
    }

    #Assemble glyphs
    my $X = defined($self->{-m}) && $self->{-m} < 0 ? '' : "\000";
    foreach( split("\n", $opts{-A}) ){
      my(@lchars, @lines);
      s/^\s*//o; #XXX
#      push(@lchars, ord $1) while /(.)/g;
      while( $opts{-U} ?
	     /$Text::FIGlet::RE{UTFchar}/g :
	     /$Text::FIGlet::RE{bytechar}/g ){
	push @lchars, ($opts{-U} ? UTF8ord($1) : ord($1));
      }

      foreach my $i (-$self->{_header}->[1]..-1){
	my $line='';
	foreach my $lchar (@lchars){
	  if( $font->[$lchar] ){
	    $line .= $font->[$lchar]->[$i] . $X if $font->[$lchar]->[$i];
	  }
	  else{
	    $line .= $font->[32]->[$i] . $X;
	  }
	}

	$line =~ s/\000$//;
	push @lines, $line;
      }

      #Kern glyphs?
      if( !defined($self->{-m}) || $self->{-m} > -1 ){
	for(my $nulls = 0; $nulls < scalar @lchars ; $nulls++){
	  my $matches = 0;
	  my @temp;
	  for(my $i=0; $i<scalar @lines; $i++){
	    $matches += ($temp[$i] = $lines[$i]) =~
	      s/^([^\000]*(?:\000[^\000]*){$nulls})(?: \000|\000(?: |\Z))/$1\000/;
	    
	    #($_ = $temp[$i]) =~ s/(${stem}{$nulls})/$1@/;
	    #print "$nulls, $i) $matches == @{[scalar @lines]} #$_\n";
	    if( $i == scalar(@lines)-1 && $matches == scalar @lines ){
	      @lines = @temp;
	      $matches = 0;
	      $i = -1;
	    }
	  }
	}
      }

      push @buffer, @lines;
    }


    #Layout
    $opts{-x} ||= $opts{-X} eq 'R' ? 'r' : 'l';
    foreach my $line (@buffer){
      #Smush
      if( !defined($self->{-m}) || $self->{-m} > 0 ){
	

	#Universal smush/overlap
	$line =~ s/\000 //g;
	$line =~ s/$Text::FIGlet::RE{UTFchar}\000//g;
      }
      else{
	$line =~ y/\000//d;
      }

      #Alignment
      if( $opts{-x} eq 'c' ){
	$line = " "x(($opts{-w}-UTF8len($line))/2) . $line;
      }
      elsif( $opts{-x} eq 'r' ){
	$line = " "x($opts{-w}-UTF8len($line)) . $line;
      }

      #Replace hardblanks
      $line =~ s/$self->{_header}->[0]/ /g;
    }


    if( $] < 5.006 ){
	return wantarray ? @buffer : join($/, @buffer).$/;
    }
    else{
	#Properly promote (back) to utf-8
	return wantarray ? map{_utf8_on($_)} @buffer :
	    _utf8_on($_=join($/, @buffer).$/);
    }


}
1;
__END__
=pod

=head1 NAME

Text::FIGlet::Font - font engine for Text::FIGlet

=head1 SYNOPSIS

  use Text::FIGlet;

  my $font = Text::FIGlet->new(-f=>"doh");

  print ~~$font->figify(-A=>"Hello World");

=head1 DESCRIPTION

B<Text::FIGlet::Font> reproduces its input as large glyphs made up of other
characters; usually ASCII, but not necessarily. The output is similar
to that of many banner programs--although it is not oriented sideways--and
reminiscent of the sort of I<signatures> many people like to put at the end
of e-mail and UseNet messages.

B<Text::FIGlet::Font> can print in a variety of fonts, both left-to-right and
right-to-left, with adjacent glyphs kerned and smushed together in various
ways. FIGlet fonts are stored in separate files, which can be identified by
the suffix I<.flf>. Most FIGlet font files will be stored in FIGlet's default
font directory F</usr/games/lib/figlet>. Support for TOIlet fonts I<.tlf>,
which are typically in the same location, has also been added.

This implementation is known to work with perl 5.005, 5.6 and 5.8, including
support for Unicode (UTF-8) in all three. See L</CAVEATS> for details.

=head1 OPTIONS

=head2 C<new>

=over

=item B<-d=E<gt>>F<fontdir>

Whence to load files.

Defaults to F</usr/games/lib/figlet>

=item B<-D=E<gt>>I<boolean>

B<-D> switches to the German (ISO 646-DE) character set.
Turns I<[>, I<\> and I<]> into umlauted A, O and U, respectively.
I<{>, I<|> and I<}> turn into the respective lower case versions of these.
I<~> turns into s-z.

This option is deprecated, which means it may soon be removed from
B<Text::FIGlet::Font>. The modern way to achieve this effect is with
L<Text::FIGlet::Control>.

=item B<-U=E<gt>>I<boolean>

A true value, the default, is necessary to load Unicode font data;
regardless of your version of perl

B<Note that you must explicitly specify I<1> if you are mapping in negative
characters with a control file>. See L</CAVEATS> for more details.

=item B<-f=E<gt>>F<fontfile>

The font to load; defaults to F<standard>.

The fontfile may be zipped if L<IO::Uncompress::Unzip> is available.
A compressed font should contain only the font itself, and the archive
should be renamed with the B<flf> extension.

=item B<-m=E<gt>>I<layoutmode>

Specifies how B<Text::FIGlet::Font> should "smush" and kern consecutive
glyphs together. This parameter is optional, and if not specified the
layoutmode defined by the font author is used. Acceptable values are
-3 through 63, where positive values are created by adding together the
corresponding numbers for each desired smush type.


  SUMMARY
  
  Value  Width  Old CLI  Description
   -3     +++            monospace
   -1      ++   -W       full width
    0       +   -k       kern
  undef     -   -o       overlap/universal smush

    1       -   -S -m1   smush equal characters
    2       -   -S -m2   smush underscores
    4       -   -S -m4   smush hierarchy
    8       -   -S -m8   smush opposite pairs
   16       -   -S -m16  smush big X
   32       -   -S -m32  smush hardblanks

   Old CLI is the figlet(6) equivalent option.
   Monospace is also available via the previous value of -0.

=over

=item I<-3>, Monospace

This will pad each glyph in the font such that they are all the same width.
The padding is done such that the glyph is centered in it's "box,"
and any odd padding is on the trailing edge.
      ____
     / ___|       ___      __      __
    | |          / _ \     \ \ /\ / /
    | |___      | (_) |     \ V  V /
     \____|      \___/       \_/\_/

  |-----------+-----------+-----------| -- equal-sized boxes

=item I<-1>, Full width

No smushing or kerning, glyphs are simply concatenated together.
     ____
    / ___|   ___   __      __
   | |      / _ \  \ \ /\ / /
   | |___  | (_) |  \ V  V /
    \____|  \___/    \_/\_/

=item I<0>, Kern

Kern only i.e; glyphs are pushed together until they touch.
    ____
   / ___| ___ __      __
  | |    / _ \\ \ /\ / /
  | |___| (_) |\ V  V /
   \____|\___/  \_/\_/

=item I<undef>, Universal smush

Glyphs are kerned, then shifted so that they overlap by column of characters:
   ____
  / ___|_____      __
 | |   / _ \ \ /\ / /
 | |__| (_) \ V  V /
  \____\___/ \_/\_/

=back

Other smush modes are not yet implemented, and therefore fall back to universal.

=back

=head2 C<figify>

Returns a a string or list of lines, depending on context.

=over

=item B<-A=E<gt>>I<text>

The text to transmogrify.

=item B<-U=E<gt>>I<boolean>

Process input as Unicode (UTF-8).

B<Note that this applies regardless of your version of perl>,
and is necessary if you are mapping in negative characters with a control file.

=item B<-X=E<gt>>I<[LR]>

These options control whether FIGlet prints left-to-right or right-to-left.
I<L> selects left-to-right printing. I<R> selects right-to-left printing.
The default is to use whatever is specified in the font file.

=item B<-x=E<gt>>I<[lrc]>

These options handle the justification of B<Text::FIGlet::Font> output.
I<c> centers the output horizontally. I<l> makes the output flush-left.
I<r> makes it flush-right. The default sets the justification according
to whether left-to-right or right-to-left text is selected. Left-to-right
text will be flush-left, while right-to-left text will be flush-right.
(Left-to-rigt versus right-to-left text is controlled by B<-X>.)

=item B<-m=E<gt>>I<layoutmode>

Although -B<-m> is best thought of as a font instantiation option,
it is possible to switch between layout modes greater than zero at
figification time. Your mileage may vary.

=item B<-w=E<gt>>I<outputwidth>

The output width, output text is wrapped to this value by breaking the
input on whitspace where possible. There are two special width values

 -1 the text is not wrapped.
  1 the text is wrapped after every character; most useful with -m=>-3

Defaults to 80

=back

=head1 ENVIRONMENT

B<Text::FIGlet::Font> will make use of these environment variables if present

=over

=item FIGFONT

The default font to load. If undefined the default is F<standard.flf>.
It should reside in the directory specified by FIGLIB.

=item FIGLIB

The default location of fonts.
If undefined the default is F</usr/games/lib/figlet>

=back

=head1 FILES

FIGlet font files are available at

  ftp://ftp.figlet.org/pub/figlet/

=head1 SEE ALSO

L<Text::FIGlet>, L<figlet(6)>

=head1 CAVEATS & RESTRICTIONS

=over

=item $/ is used to create the output string in scalar context

Consequently, make sure it is set appropriately i.e.;
Don't mess with it, B<perl> sets it correctly for you.

=item B<-m=>E<gt>'-0'

This mode is peculiar to B<Text::FIGlet>, and as such, results will vary
amongst fonts.

=item Support for pre-5.6 perl

This codebase was originally developed to be compatible with 5.005.03,
and has recently been manually checked against 5.005.05. Unfortunately,
the default test suite makes use of code that is not compatable with
versions of perl prior to 5.6. F<t/5005-lib.pm> attempts to work around
this to provide some basic testing of functionality.

=item Support for TOIlet fonts

Although the FIGlet font specification is not clear on the matter,
convention dictates that there be no trailing whitespace after the
end of line marker. Unfortunately some auto-generated TOIlet fonts
break with this convention, while also lacking critical hardspaces.
To fix these fonts, unzip then run C<perl -pi~ -e 's/@ $/$\@/'> on them.

=back

=head2 Unicode

=over

=item Pre-5.8

Perl 5.6 Unicode support was notoriously sketchy. Best efforts have
been made to work around this, and things should work fine. If you
have problems, favor C<"\x{...}"> over C<chr>. See also L<Text::FIGlet/NOTES>

=item Pre-5.6

Text::FIGlet B<does> provide limited support for Unicode in perl 5.005.
It understands "literal Unicode characters" (UTF-8 sequences), and will
emit the correct output if the loaded font supports it. It does not
support negative character mapping at this time.
See also L<Text::FIGlet/NOTES>

=item Negative character codes

There is limited support for negative character codes,
at this time only characters -2 through -65_535 are supported.

=back

=head2 Memory

The standard font is 4Mb with no optimizations.

Listed below are increasingly severe means of reducing memory use when
creating an object.

=over

=item B<-U=E<gt>-1>

This loads Unicode fonts, but skips negative characters. It's the default.

The standard font is 68kb with this optimization.

=item B<-U=E<gt>0>

This only loads ASCII characters; plus the Deutsch characters if -D is true.

The standard font is 14kb with this optimization.

=back

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
