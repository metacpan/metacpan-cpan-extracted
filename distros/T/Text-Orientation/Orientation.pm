package Text::Orientation;
use 5.006;
use String::Multibyte;
use Text::Orientation::StringOperation;
our $VERSION = '0.04';

#
# O_O;;
#

sub new{
    my $pkg = shift;;
    my %arg = @_;
    bless {
	_TEXTREF => ref($arg{TEXT}) eq "ARRAY" ? $arg{TEXT} : [ split("\n", $arg{TEXT}) ],
	_CHARSET => $arg{CHARSET},
    }, $pkg;
}

sub text { $_[0]->{_TEXTREF} = ref($_[1]) eq "ARRAY" ? $_[1] : [ split("\n", $_[1])] }
sub charset { $_[0]->{_CHARSET} = $_[1] }

sub maxlen {
    my $maxlen = 0;
    if($_[1]){
	my $mb = Text::Orientation::StringOperation->new($_[1]);
	for my $t (@{$_[0]}){ $maxlen = $mb->length($t) if $mb->length($t) > $maxlen }
    }
    else{
	for my $t (@{$_[0]}){ $maxlen = length($t) if length($t) > $maxlen }
    }
    $maxlen;
}


sub transpose      { $_[0]->manip('transpose') }
sub anti_transpose { $_[0]->manip('anti_transpose') }
sub mirror         { $_[0]->manip('mirror', $_[1]) }
sub rotate         { $_[0]->manip('rotate', $_[1]) }

sub manip {
    my ($pkg, $method, $options) = @_;
    {
	transpose      => \&_transpose,
	anti_transpose => \&_transpose,
	rotate         => \&_rotate,
	mirror         => \&_mirror,
    }->{$method}->(
		   $pkg->{_TEXTREF},
		   $pkg->{_CHARSET},
		   {
		       transpose => 1,
		       anti_transpose => 2,
		   }->{$method} || $options
		   );
}

sub _transpose{
    my ($textref, $charset, $options) = @_;
    my $mb = Text::Orientation::StringOperation->new($charset);
    my ($core, $text, $ml);
    my ($row, $col);
    $ml = maxlen($textref, $charset);
    for my $i (0..$#{$textref}){
	for my $k (0..$mb->length($textref->[$i])-1){
	    ($row, $col) = $options == 2?
		($mb->length($textref->[$i])-1- $k, $#{$textref}-$i) : ($k, $i);
	    $core->[$row]->[$col] = $mb->substr($textref->[$i], $k, 1);
	}
    }
    for my $i (0..$#{$core}){
	$text .= join('', @{$core->[$i]}).($i!=$#{$core}?"\n":'');
    }
    $text;
}    

sub _mirror {
    my ($textref, $charset, $options) = @_;
    my $mb = Text::Orientation::StringOperation->new($charset);
    my $text;
    if($options =~ /vertical/io){
	$text = join( "\n", reverse @{$textref}), "\n";
    }
    elsif($options =~ /horizontal/io){
	my $ml = maxlen($textref, '');
	$text = join( "\n", map { ' 'x($ml-length$_).$mb->reverse($_) } @{$textref});
    }
    $text;
}

sub _rotate {
    my ($textref, $charset, $dir) = @_;
    $dir %= 4;
    my $mb = Text::Orientation::StringOperation->new($charset);
    my ($core, $text, $ml);
    $ml = maxlen($textref, $charset);
    if($dir == 1){
	for my $i (0..$#{$textref}){
	    for my $k (0..$mb->length($textref->[$i])-1){
		$core->[$k]->[$#{$textref} - $i] =
		    $mb->substr($textref->[$i], $k, 1);
	    }
	    for my $k ($mb->length($textref->[$i])..$ml-1){
		$core->[$k]->[$#{$textref} - $i] = ' ';
	    }
	}
    }
    elsif($dir == 2){
	return _mirror(
		       [ split "\n",_mirror($textref, $charset, 'horizontal') ],
		       $charset, 'vertical'
		       );
    }
    elsif($dir == 3){
	for my $i (0..$#{$textref}){
	    for my $k (0..$mb->length($textref->[$i])-1){
		$core->[$mb->length($textref->[$i])-1 - $k]->[$i] =
		    $mb->substr($textref->[$i], $k, 1);
	    }
	}
    }
    for my $i (0..$#{$core}){
	$text .= join('', @{$core->[$i]}).($i!=$#{$core}?"\n":'');
    }
    $text;
}


#
# PerlIO layer
#

our $method;
our $param;
our $charset;

sub import {
    shift;
    my %arg = @_;
    $method = lc $arg{method};
    $param = $method ? lc $arg{param} : undef;
    $charset = $method ? $arg{charset} : undef;
}

sub PUSHED {
    die "Lacking method\n" unless $method;
    $_[0]->new( TEXT => undef, CHARSET => $charset );
}
sub FILL { my $line = <$_[1]>; $line ? $line : "\n" }
sub WRITE {
    $_[0]->{_TEXT} .= $_[1];
    return length($_[1]);
}
sub FLUSH {
    my ($obj,$fh) = @_;
    $obj->text($obj->{_TEXT});
    print $fh $obj->manip($method, $param) or return -1;
    $obj->{_TEXT} = '';
    return 0;
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Text::Orientation - Text Rotator

=head1 SYNOPSIS

  use Text::Orientation;

  # OO

  $rot = Text::Orientation->new( TEXT => "Rotate me!" );
  print $rot->mirror('horizontal');
  print $rot->rotate(+1);


  # PerlIO layer

  use Text::Orientation method => 'mirror', param => 'horizontal', charset=> 'Big5';
  binmode(STDOUT, ":via(Text::Orientation)") or die;

  print BLAH BLAH BLAH ...


=head1 DESCRIPTION

This module enables one to rotate text. For example, Chinese can be written downwards or leftwards, but it is usually not convenient to do so on one's computer. With Text::Orientation one can easily deal with this problem.

PerlIO layer interface is also provided for easier coding.

=head1 METHODS

=head2 new

 $rot = Text::Orientation->new( TEXT => text or text's ref, CHARSET => blah);

Constructor. As for TEXT, either a string or a reference to an array of text will do.
Please specify CHARSET If the input text is encoded in multibyte character set.

=head2 charset

Changes the encoding of the text. If not set, text is treated as encoded in single byte.

=head2 text

Changes the text to rotate.

=head2 transpose

Transposes text along the diagonal.

=head2 anti_transpose

Transposes text along the antidiagonal.

=head2 mirror

Generates the mirrored image of input string in two ways: 'vertical' or 'horizontal'.

=head2 rotate

Rotates the text. The parameter is an integer. Positive is for clockwise rotation, and negative for counterclockwise. E.g. -3 for 270-degree counterclockwise rotation

=head1 AUTHOR

xern <xern@cpan.org>

=head1 SEE ALSO

L<String::Multibyte>

=head1 LICENSE

Released under The Artistic License

=cut
