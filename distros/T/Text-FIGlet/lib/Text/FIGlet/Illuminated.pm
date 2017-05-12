package Text::FIGlet::Illuminated;
require 5;
use strict;
use vars qw/$VERSION @ISA/;
use Text::FIGlet;
use Text::Wrap;
$VERSION = 2.19;
@ISA = 'Text::FIGlet::Font';

sub new{
    shift();
    bless(Text::FIGlet->new(@_));
}

sub illuminate{
    my $font = shift;
    my %opts = @_;

    my @buffer;
    if( $opts{-w} < 0 ){
	$opts{-w} = abs($opts{-w});
	@buffer = _illuminate($font, %opts);
    }
    else{
	foreach( split("$/$/", $opts{-A} ) ){
	    push @buffer, _illuminate($font, %opts, -A=>$_);
	}
    }

    return wantarray ? @buffer : join("\n", @buffer);
}

sub _illuminate{
    my $font = shift;
    my %opts = @_;

    my $text = $opts{'-A'};
    $opts{'-A'} = substr($text, 0, 1, '');

    my @illumination = $font->figify(%opts);

    my $empty;
    for(my $i=0; $i<=$#illumination; $i++ ){
	if( $illumination[$i] =~ /^\s+$/ ){
	    $empty = $i; }
	else{
	    last; }
    }
    splice(@illumination,0,$empty+1);
    for(my $i=$#illumination; $i>=0; $i-- ){
	if( $illumination[$i] =~ /^\s+$/ ){
	    $empty = $i; }
	else{
	    last; }
    }
    splice(@illumination,$empty, $#illumination-$empty);

    $opts{-w}||=80;
    my $cols = length($illumination[0]);
    my $freecols = $opts{-w} -$cols -2;
    my $rows = scalar(@illumination);

    $Text::Wrap::columns = $freecols;

    my @body = split /\n/, wrap('', '', $text);

    for(my $i=0; $i<=$#illumination; $i++ ){
	$illumination[$i] .= '  ' . shift(@body)||'';
    }

    if( scalar(@body) ){
	my $body = join(' ', @body);
	$body =~ y/\n//d;
	$Text::Wrap::columns = $opts{-w};
	push(@illumination, split(/\n/, wrap('', '', $body)));
    }

    return wantarray ? @illumination : join("\n", @illumination);
}

1;
__END__
=pod

=head1 NAME

Text::FIGlet::Illuminated - s/// 1st char of each/1st para. with ASCII art

=head1 SYNOPSIS

  use Text::FIGlet::Illuminated;

  my $illuminated = Text::FIGlet::Illuminated->new(-f=>'doh');

  my $ipsum =<<LOREM;
  Lorem ipsum dolor sit amet, consectetur adipisicing elit,
  Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
  Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris
  nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
  reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
  pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
  culpa qui officia deserunt mollit anim id est laborum.

  Sed ut perspiciatis unde omnis iste natus error sit voluptatem
  accusantium doloremque laudantium, totam rem aperiam, eaque ipsa
  quae ab illo inventore veritatis et quasi architecto beatae vitae
  dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas
  sit aspernatur aut odit aut fugit, sed quia consequuntur magni
  dolores eos qui ratione voluptatem sequi nesciunt. Neque porro
  quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur,
  adipisci velit, sed quia non numquam eius modi tempora incidunt ut
  labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima
  veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam,
  nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure
  reprehenderit qui in ea voluptate velit esse quam nihil molestiae
  consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla
  pariatur?
  LOREM

  print $illuminated->illuminate(-A=>$ipsum, -w=>-72);
  __DATA__
  LLLLLLLLLLL               orem ipsum dolor sit amet, consectetur	
  L:::::::::L               adipisicing elit, sed do eiusmod tempor
  L:::::::::L               incididunt ut labore et dolore magna aliqua.
  LL:::::::LL               Ut enim ad minim veniam, quis nostrud
    L:::::L                 exercitation ullamco laboris nisi ut aliquip
    L:::::L                 ex ea commodo consequat. Duis aute irure
    L:::::L                 dolor in reprehenderit in voluptate velit
    L:::::L                 esse cillum dolore eu fugiat nulla pariatur.
    L:::::L                 Excepteur sint occaecat cupidatat non
    L:::::L                 proident, sunt in culpa qui officia deserunt
    L:::::L                 mollit anim id est laborum.
    L:::::L         LLLLLL  	
  LL:::::::LLLLLLLLL:::::L  Sed ut perspiciatis unde omnis iste natus
  L::::::::::::::::::::::L  error sit voluptatem accusantium doloremque
  L::::::::::::::::::::::L  laudantium, totam rem aperiam, eaque ipsa
  LLLLLLLLLLLLLLLLLLLLLLLL  quae ab illo inventore veritatis et quasi
                            architecto beatae vitae dicta sunt explicabo.
  Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut
  fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem
  sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor
  sit amet, consectetur, adipisci velit, sed quia non numquam eius modi
  tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.
  Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis
  suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis
  autem vel eum iure reprehenderit qui in ea voluptate velit esse quam
  nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo
  voluptas nulla pariatur?

=head1 DESCRIPTION

Illumination replaces the first character a paragraph with the
corresponding figchar from the specified font. The remaining text
is then wrapped around the figchar, reminiscent of illuminated
texts, some magazines, or the CSS :first-letter pseudo-element.

=head1 OPTIONS

=head2 C<new>

Loads the specified font.

Default options are inherited from L<Text::FIGlet>.

=head2 C<illuminate>

Default options are inherited from L<Text::FIGlet::Font>.

Pass a negative width if you would like only the first paragraph of the
input to be illuminated, otherwise each paragraph will be illuminated.

=head1 ENVIRONMENT

B<Text::FIGlet::Illuminated>
will make use of these environment variables if present

=over

=item FIGFONT

The default font to load. If undefined the default is F<standard.flf>.
It should reside in the directory specified by FIGLIB.

=item FIGLIB

The default location of fonts.
If undefined the default is F</usr/games/lib/figlet>

=back

=head1 CAVEATS & RESTRICTIONS

Kerning and smushing modes make little sense with B<Illuminated>.

=over

=item $/ is used to separate the input

Consequently, make sure it is set appropriately i.e;
Don't mess with it, B<perl> sets it correctly for you.

=back

=head1 SEE ALSO

L<Text::FIGlet::Font>, L<Text::FIGlet::Ransom>, L<Text::FIGlet>, L<figlet(6)>

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
