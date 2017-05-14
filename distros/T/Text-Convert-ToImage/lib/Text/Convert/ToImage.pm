package Text::Convert::ToImage;
use 5.006001;
use strict;
use warnings;
use Carp;
use base qw( Image::Magick );
use vars qw( $VERSION $LEGAL_ATTRIBUTES );
our $VERSION = sprintf("%d.%02d", q$Revision: 0.00 $ =~ /(\d+)\.(\d+)/);

our $LEGAL_ATTRIBUTES = {
    LINE_HEIGHT => 18,
    LINE_LENGTH => 100,
    OUTPUT_FILE => 'www.hjackson.org',
    IMAGE_EXT   => 'png',
    POINT_SIZE  => 12,
    TEXT        => 'http://www.hjackson.org',
    BG_COLOR    => 'white',
    TEXT_COLOR  => 'blue',
    FONT        => 'Bookman-Demi',
    INPUT_FILE  => 'xc:white',
    MAGICK      => undef, 
    LEVEL       => 0,
    FONT        => 'Courier',
    XSKEW       => 0,
    YSKEW       => 0,
};

my $magick_setup = {
    size => undef,
    pointsize => undef,
};

sub _init {
    my ($self, $config) = @_;
    for my $field ( keys %{ $LEGAL_ATTRIBUTES } ) {
        my $lc_field = lc $field; 
        no strict "refs"; 
        *$lc_field = sub { 
            my $self = shift;
            return $self->(uc $field, @_);
        };      
    }
    while ( my ($key, $val) = each %{ $config }) {
        $key = lc($key);
        $self->$key($val);
    }
    unless( ref($self->magick()) ) {
        my $magick = Image::Magick->new() || die "Unable to create Image::Magick Object $!";
        $self->magick( $magick );
    } 
}



sub _get_metrics {
    my ($self, $filename) = @_;
    
    if(ref($filename) ne 'GLOB') {
        my $file = $self->untaint($filename);
        croak "Possible security problem with filename: $filename" unless($file);
        open ($filename, "<$file") or die "$!\n"; 
    }
   
    my $text;
    my $line_length = 0;
    my $metrics = {
        max_line_length    => 0,
        max_line_length_at => 0,
        linecount          => 0,
        text               => 0,
    };

    my $line;
    while(<$filename>) {
        $text .= $_;
        $line = $_;
        $line_length = length($line);
        if($line_length > $metrics->{max_line_length}) {
            $metrics->{max_line_length_at} = $metrics->{linecount};
            $metrics->{max_line_length} = $line_length;
        }
        $metrics->{linecount}++;
    }
    $metrics->{text} = $text;
    return $metrics;
}

sub generate {
    my ($self, $config) = @_;
    my $metrics = $self->_get_metrics($config->{filename});
    my $point_size = $config->{point_size};
    my $font       = $config->{font};
    
    # I need to make sure that windows is handled as well
    my @lines = split( /\n/, $metrics->{text});
   
    my $size = "size=>'10" . "x" . "20'";
    $self->Set(eval $size);
    $self->Read('xc:white');
    
    my ($x_ppem, $y_ppem, $ascender, $descender, $width, $height, $max_advance) =
        $self->QueryFontMetrics(text      =>$lines[$metrics->{max_line_length_at}],
                                pointsize =>$point_size,
                                font      =>$font);
                                
    $width = $width+$max_advance+$x_ppem;
    
    $self->Scale(width=>$width,height=>$height * $metrics->{linecount});
    
    my $x = $point_size;
    my $y = $point_size;
    $self->Comment("http://www.hjackson.org/");
    foreach (@lines) {
    ($x_ppem, $y_ppem, $ascender, $descender, $width, $height, $max_advance) =
        $self->QueryFontMetrics(text=>$_,pointsize=>$point_size,font=>$font);
        $self->Annotate( text  => $_,
                         font  => $font, 
                         fill  =>'black',
                         align =>'Left' ,
                         pointsize=>$point_size,
                         x => $x,
                         y => $y,
                         );
                         $y = $y+$height;
                         
    }
    #$self->Set(compression=>'None');
}



#---------------------------------------------------------
#
#
#
#---------------------------------------------------------

sub untaint {
    my ($self, $data) = @_;
    if ($data =~ /^([-\@\w.]+)$/) {
        $data = $1;                     # $data now untainted
    } else {
        return undef;
    }
    return $data;
}


sub calculate {
    my ($self, $config) = @_;
    my $text  = $config->{TEXT};
    my $level = $config->{LEVEL};
    my $font  = $config->{FONT};
    my $xskew = $config->{XSKEW};
    my $yskew = $config->{YSKEW};
    
    my @lines = split (/\n/, $text);
    my $measure;
    foreach (@lines) {
         my $len = length($_);
         $measure->{LENGTH} = $len unless ($measure->{LENGTH} &&  $measure->{LENGTH} > $len); 
    }
    # Need to handle references to scalars Filhandles and all other sorts of
    # text that people my want converted.
    my $nullchar_count = ($text =~ tr[.|/][]);
    $nullchar_count = $nullchar_count * 5 ;
    my $point_size = $config->{POINTSIZE};
    my $border = ($point_size / 5);
    my $size = "size=>'10" . "x" . "20'";
    $self->Set(eval $size);
    $self->Read('xc:white');
    my ($x_ppem, $y_ppem, $ascender, $descender, $width, $height, $max_advance) =
        $self->QueryFontMetrics(text=>$text,pointsize=>$point_size,font=>$font);
    $width = $width+$max_advance+$x_ppem+$nullchar_count;
    $self->Scale(width=>$width,height=>$height);
    
    $self->obfuscate($width, $height, $level, $point_size); 

    my $x = $point_size;
    my $y = $point_size;
    my @letters = split (//, $text);
    $self->Comment("http://www.hjackson.org/");
    foreach (@letters) {
    ($x_ppem, $y_ppem, $ascender, $descender, $width, $height, $max_advance) =
        $self->QueryFontMetrics(text=>$_,pointsize=>$point_size,font=>$font);
        #warn "letter == $_\n";
        $self->Annotate( text  => $_,
                         font  => $font, 
                         fill  =>'black',
                         align =>'Left' ,
                         pointsize=>$point_size,
                         x => $x,
                         y => $y,
                         skewX =>int(rand($xskew * 3 )),
                         skewY =>int(rand($yskew * 3 )),
                         );
                         $x = $x+$width;
                         
    }
    $self->Set(compression=>'None');
    return $self;
}

sub obfuscate {

    my ($self, $width, $height, $level, $point_size ) = @_; 
    return $self if ($level eq 0);
    my @colors = qw(white red black green blue);
    my $loop = $level * 10 * int($level/2);
    my @pixel_pos = ();
    #$self->Blur();
    #$self->AddNoise(noise=>'Uniform');
    foreach (1 .. $loop) {
        my $col = int(rand(4));
        $pixel_pos[0] = int(rand($width));
        $pixel_pos[1] = int(rand($height));
        my $string = "'pixel[ $pixel_pos[0], $pixel_pos[1] ]'=>$col";
        $self->Set(eval $string);
        #warn "" . $pixel_pos[0] . "," . $pixel_pos[1] . "\n";
        
    }
    #$self->Set('pixel[5,5]'=>'red');
    return $self;
}

sub calculate_lines {
    my $self = shift;
}

1;


__END__

=head1 NAME

Text::Convert::ToImage

=head1 SYNOPSIS

 use Text::Convert::ToImage;
 my $tti =  Text::Convert::ToImage->new();
 my $length = length($email);
 if ($length > 150) {
     $email = "Your text length of $length is too large:";
 }
 my $config = {
     TEXT      => $email ? $email : "y\@hn.org",
     POINTSIZE => $point_size ? $point_size : 14,
     LEVEL     => $level ? $level : 0,
     FONT      => $font,
     XSKEW     => $xskew, 
     YSKEW     => $yskew, 
     
 };
 $tti->calculate($config);
 print "Content-type: image/png\n\n";
 binmode STDOUT; 
 $tti->Write('png:-');


=head1 DESCRIPTION


This was knocked up a long time ago and someone asked me if the source was
available so I decided to put it on CPAN. There is very little documentation
with it. 

There are also very few tests. If more than me and the person who asked for the
module use it then I will write some tests for it.

At the moment I have been using it top obfuscate emails and not much else. A demo
can be found at L<http://www.hjackson.org/cgi-bin/tools/email.pl>

There are some undocumented features to this module and they are this way because I
have not tested to see if they work yet. 

=head1 SEE ALSO

L<Image::Magick>

=head1 AUTHOR

Harry Jackson

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Harry Jackson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
