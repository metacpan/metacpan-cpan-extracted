package ImagePwd;

use Image::Magick;

use strict;

##############################################
# ImagePwd module written by Julian Lishev
# This module is part of WebTools package!
# Privacy and terms are same as WebTools!
##############################################
# Prerequirment: Image::Magick (PerlMagick)
##############################################


=head2 $img = ImagePwd::new (%inp);

 %inp hash can contain follow members:
 
   len      - Count of password string.
   width    - Width of generated image.
   height   - Height of generated image.
   f_max    - Maximum size of font.
   f_min    - Minimum size of font.
   fixed    - If you want to use one color for all chars please set this
              to '1' other else to '0'
   rot      - Maximum(minimum) rotate angle (0 up to 90)
   fonts    - Pointer to array of fonts that will be used for image password.
              (NT users should specify full path to fonts!)
   bgcolor  - Use only if you want to fix used bgcolor for image!!!
   color    - Use only if you want to fix used color for text!!!
   quality  - Quality of new generated image (variate of 0 up to 128)
   password - This member contain 'password' with length 'len'
   cell     - Set to '1' if you want over image to be placed cells,
              drawn with random color.
   
Note: Font sizes variates from 'f_min' up to 'f_max' pixels.

=cut

BEGIN
 {
  use vars qw($VERSION @ISA @EXPORT);
  $VERSION = "1.16";
  @ISA = qw(Exporter);
  @EXPORT = qw();
  srand();
 }

sub new
{ 
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $this = {};
 
 my %inp = @_;

 $this->{'len'} = $inp{'len'} || '4';
 $this->{'len'} =~ s/^.*?(\d*).*?$/$1/sgi;

 $this->{'width'} = $inp{'width'} || '200';
 $this->{'width'} =~ s/^.*?(\d*).*?$/$1/sgi;

 $this->{'height'} = $inp{'height'} || '60';
 $this->{'height'} =~ s/^.*?(\d*).*?$/$1/sgi;

 $this->{'f_max'} = $inp{'f_max'} || 32;
 $this->{'f_max'} =~ s/^.*?(\d*).*?$/$1/sgi;
 
 $this->{'f_min'} = $inp{'f_min'} || 14;
 $this->{'f_min'} =~ s/^.*?(\d*).*?$/$1/sgi;
 
 $this->{'rot'} = $inp{'rot'} || 20;
 $this->{'rot'} =~ s/^.*?(\d*).*?$/$1/sgi;
 
 $this->{'quality'} = $inp{'quality'} || 128;
 $this->{'quality'} =~ s/^.*?(\d*).*?$/$1/sgi;
 
 $this->{'bgcolor'} = $inp{'bgcolor'} || '';
 
 $this->{'color'} = $inp{'color'} || '';
 
 $this->{'fixed'} = exists($inp{'fixed'}) ? $inp{'fixed'} : 1;
 if($this->{'fixed'} =~ m/YES/is) {$this->{'fixed'} = 1;}
 if($this->{'fixed'} =~ m/TRUE/is) {$this->{'fixed'} = 1;}
 if($this->{'fixed'} != 1) {$this->{'fixed'} = 0;}
 
 $this->{'password'} = $inp{'password'} || '';
 
 $this->{'cell'} =~ s/yes/1/si;
 $this->{'cell'} =~ s/on/1/si;
 $this->{'cell'} =~ s/no/0/si;
 $this->{'cell'} =~ s/off/0/si;
 $this->{'cell'} = $inp{'cell'} || 0;
 $this->{'cell'} =~ s/^.*?(\d*).*?$/$1/sgi;

 if(ref($inp{'fonts'}))
  {
   my @tmparrsf = @{$inp{'fonts'}};
   $this->{'fonts'} = \@tmparrsf;
  }
 else
  {
   my @tmparrsf = ();
   $this->{'fonts'} = \@tmparrsf;
  }
   
 bless($this,$class);
 return($this);
}

sub _set_val
{
 my $this = shift(@_);
 my $name = shift(@_);
 my @params = @_;
 if(defined($_[0]))
  {
   my $code = '$this->{'."'$name'".'} = $_[0];';
   eval $code;
   return($_[0]);
  }
 else
  {
   my $code = '$code = $this->{'."'$name'".'};';
   eval $code;
   return($code);
  }
}

sub len       { shift->_set_val('len', @_); }
sub width     { shift->_set_val('width', @_); }
sub height    { shift->_set_val('height', @_); }
sub f_max     { shift->_set_val('f_max', @_); }
sub f_min     { shift->_set_val('f_min', @_); }
sub fixed     { shift->_set_val('fixed', @_); }
sub rot       { shift->_set_val('rot', @_); }
sub quality   { shift->_set_val('quality', @_); }
sub bgcolor   { shift->_set_val('bgcolor', @_); }
sub color     { shift->_set_val('color', @_); }
sub fonts     { shift->_set_val('fonts', @_); }
sub password  { shift->_set_val('password', @_); }
sub cell      { shift->_set_val('cell', @_); }

sub ImagePassword
{
 my $obj = shift;
 my $i;
 my $len = $obj->len();
 my $width = $obj->width();
 my $height = $obj->height();
 my $f_max = $obj->f_max();
 my $f_min = $obj->f_min();
 my $fixed = $obj->fixed();
 my $rot = $obj->rot();
 my $quality = $obj->quality();
 my $f_bgcolor = $obj->bgcolor();
 my $f_color = $obj->color();
 my $cell = $obj->cell();
 my ($cx,$cy);
 my $str = $obj->password() || _generatestring($len);
 $obj->password($str);
 my $i_x = 0;
 my @pnts = ();

 $cy = rand(20) + $height/2;
 $cx = rand(10);
 my $a_cx = $cx * $len;
 for ($i=0;$i<$len;$i++)
  {
   my $sz = $obj->f_min() + rand($obj->f_max() - $obj->f_min());
   push (@pnts,$sz);
   $i_x += $sz;
  }
 my $addl = $cx;
 $cx = ($width/2) - (($i_x+$a_cx)/2);
 my $image = Image::Magick->new(compression=>'LosslessJPEG',quality=>$quality);
 $image->Set(size=>$width.'x'.$height);
 my $bgcolor = $f_bgcolor || _generatebgcolor();
 my $color = $f_color || _choosecolor($bgcolor);
 $image->Set(antialias=>'True');
 $image->ReadImage('xc:'.$bgcolor);
 for ($i=0;$i<$len;$i++)
  {
   my $char = substr($str,$i,1);
   my $sz = $pnts[$i];
   my $rot = int(rand(10)) > 5 ? (-1)*rand($rot) : rand($rot);
   $image->Set(font=>$obj->_choosefont());
   $image->Annotate(pointsize=>$sz, rotate=>$rot, fill=>$color, text=>$char,x=>$cx,y=>$cy);
   if(!$fixed) { $color = $f_color || _choosecolor($bgcolor); }
   $cx += $sz+$addl;
   $cy = rand(20) + $height/2;
  }
 if($cell)
 {
  my $y;
  my $xstep = int(rand(12)+8);
  my $rowcolor = '#'.hex(rand(155)+100).hex(rand(55)+200).hex(rand(255));
  my $colcolor = '#'.hex(rand(100)+155).hex(rand(100)+155).hex(rand(200)+55);
  for ($y = 0; $y<int($height/$xstep)+1; $y++)
   {
    $image->Draw(stroke=>$rowcolor, primitive=>'line', points=>"0,".$y*$xstep.",$width,".$y*$xstep);
   }
  $image->Draw(stroke=>$rowcolor, primitive=>'line', points=>"0,".($height-2).",".$width.",".($height-2));
  my $x;
  my $ystep = int(rand(10)+10);
  for ($x = 0; $x<int($width/$ystep)+1; $x++)
   {
    $image->Draw(stroke=>$colcolor, primitive=>'line', points=>$x*$ystep.",0,".$x*$ystep.",$height");
   }
  $image->Draw(stroke=>$colcolor, primitive=>'line', points=>($width-2).",0,".($width-2).",$height");
 }
 return($image);
}

sub _generatestring
{
 my $size = shift(@_);
 my ($i,$str,$char) = ();
 
 for ($i = 0; $i < $size; $i++)
  {
   $char = chr(rand(ord('Z')-33)+33);
   if($char =~ m/^[A-Za-z0-9\@\#\$\&\(\)\=\+\\\[\]\?\/]$/s)
     {
      $str .= $char;
     }
   else {redo;}
  }
 return($str);
}

sub _generatebgcolor
{
 my @colors = ('black','blue','gray','green');
 my $colr = rand($#colors+1);
 return($colors[$colr]);
}

sub _choosecolor
{
 my $bgcolor = shift(@_);
 my @colors = ('white','black','red','blue','gray','yellow','orange');
 my $colr;
 while (1)
  {
   $colr = rand($#colors+1);
   if($bgcolor ne $colors[$colr]){return($colors[$colr]);}
  }
}

sub _choosefont
{
 my $obj = shift(@_);
 my @fonts = @{$obj->fonts()};
 return($fonts[rand($#fonts+1)]);
}

sub DESTROY
{
 1;
}

1;
__END__

=head1 NAME

 ImagePwd.pm - Full featured Image password generator for Web

=head1 DESCRIPTION

=over 4

ImagePwd is written in pure Perl and generate images that can be used against automatic scripts: about registrations, 
submittions, flood and any multiple undesired actions.

Prerequirements:
 - PerlMagick package, often became with ImageMagick (http://www.imagemagick.org/)

Features:
You can automatize many aspects of generated image:

   - Length of password string.
   - Width of generated image.
   - Height of generated image.
   - Maximum size of font.
   - Minimum size of font.
   - You can use fixed color for all password chars.
   - You can rotate chars on random angle (0 up to 90)
   - To use array of fonts for generated image password.
   - To use one fixed bgcolor for image.
   - To use fixed color for text
   - To set quality level (variate of 0 up to 128)
   - To write your custom "password" text
   - To set over image cells, drawn with random color.

=back

=head1 SYNOPSIS

 use ImagePwd;
 $obj = ImagePwd->new(len=>6, height=>60, width=>280, fixed=>1, rot=>10,
                      quality=>128, cell=>1, f_min=>20);
                      
 $obj->fonts(['c:/Windows/FONTS/Verdana.TTF','c:/Windows/FONTS/Arial.TTF',
              'c:/Windows/FONTS/comic.TTF','c:/Windows/FONTS/georgiab.TTF',
              'c:/Windows/FONTS/micross.TTF','c:/Windows/FONTS/tahoma.TTF',
             ]);
 # $obj->fonts(['kai.ttf']); # And more fonts for Unix/Linux users
 
 $img = $obj->ImagePassword();
 $| = 1;
 binmode STDOUT;
 print "Content-type: image/png\n\n";
 print $img->Write('png:-');
 
 OR
 
<?perl
 use ImagePwd;

 $obj = ImagePwd->new(len=>6, height=>60, width=>280, fixed=>1, rot=>10,
                     quality=>128, cell=>1, f_min=>20);

 $obj->fonts(['c:/Windows/FONTS/Verdana.TTF','c:/Windows/FONTS/Arial.TTF',
             'c:/Windows/FONTS/comic.TTF','c:/Windows/FONTS/georgiab.TTF',
             'c:/Windows/FONTS/micross.TTF','c:/Windows/FONTS/tahoma.TTF',
             ]);
 # $obj->fonts(['kai.ttf']); # And more fonts for Unix/Linux users

 $img = $obj->ImagePassword();

 ClearBuffer();
 ClearHeader();
 flush_print(1);
 set_printing_mode('');

 Header(type=>'raw',val=>"Content-type: image/png\n\n");
 print $img->Write('png:-');

?>

=head1 AUTHOR

 Julian Lishev - Bulgaria, Sofia, 
 e-mail: julian@proscriptum.com, 
 www.proscriptum.com

=cut