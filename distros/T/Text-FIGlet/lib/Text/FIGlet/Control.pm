package Text::FIGlet::Control;
use strict;
use vars '$VERSION';
use Carp 'croak';
$VERSION = 2.15;

#'import' core support functions from parent with circular dependency
foreach( qw/_canonical _no/){
  no strict 'refs';
  *$_ = *{'Text::FIGlet::'.$_};
}

sub new{
  my $proto = shift;
  my $self = {-C=>[]};
  local($_, *FLC);

  my $code = '';
  my(@t_pre, @t_post);
  while( @_ ){
    my $s = shift;
    if( $s eq '-C' ){
	push(@{$self->{-C}}, shift); }
    else{
	$self->{$s} = shift; }
  }
  $self->{-d} ||= $ENV{FIGLIB}  || '/usr/games/lib/figlet/';
  $self->{"_\\"} = 1 if $^O =~ /MSWin32|DOS/i;


#  my $no = qr/0x[\da-fA-F]+|\d+/;

  foreach my $flc ( @{$self->{-C}} ){
    $self->{'_file'} = _canonical($self->{-d},
						$flc,
						qr/\.flc/,
						$self->{"_\\"});
    open(FLC, $self->{'_file'}) || croak("$!: $flc [$self->{_file}]");
    while(<FLC>){
      next if /^flc2a|\s*#|^\s*$/;

      #XXX Is this adequate?
      $code .= 'use utf8;' if /^\s*u/;

      if( /^\s*$Text::FIGlet::RE{no}\s+$Text::FIGlet::RE{no}\s*/ ){
	#Only needed for decimals?!

	push @t_pre,  sprintf('\\x{%x}', _no($1, $2, $3));
	push @t_post, sprintf('\\x{%x}', _no($4, $5, $6));
      }
      elsif( /^\s*t\s+\\?$Text::FIGlet::RE{no}(?:-\\$Text::FIGlet::RE{no})?\s+\\?$Text::FIGlet::RE{no}(?:-\\$Text::FIGlet::RE{no})?\s*/ ){
	push @t_pre,  sprintf( '\\x{%x}', _no( $1, $2, $3));
	push @t_post, sprintf( '\\x{%x}', _no( $7, $8, $9));
	$t_pre[-1] .= sprintf('-\\x{%x}', _no( $4, $5, $6)) if$5;
	$t_post[-1].= sprintf('-\\x{%x}', _no($10,$11,$12))if$11;
      }
      elsif( /^\s*t\s+([^\s](?:-[^\s])?)\s+([^\s](?:-[^\s])?)\s*/ ){
	push @t_pre,  $1;
	push @t_post, $2;
      }
      if( /^\s*f/ || eof(FLC) ){
	@{$_} = map { s%/%\\/%g, $_ } @{$_} for( \@t_pre, \@t_post );
	$code  .= 'tr/' . join('', @t_pre) . '/' . join('', @t_post) . '/;';
	@t_pre = @t_post = ();
      }
    }
    close(FLC);
  }
  $self->{_sub} = eval "sub { local \$_ = shift; $code; return \$_ }";
  bless($self);
}

sub tr($){
  my $self = shift;
  $self->{_sub}->( shift || $_ );
}
1;
__END__
=pod

=head1 NAME

Text::FIGlet::Control - control file support for Text::FIGlet

=head1 SYNOPSIS

  use Text::FIGlet;

  my $flc = Text::FIGlet->new(-C=>'upper.flc');

  print $flc->tr("Hello World");

=head1 DESCRIPTION

Text::FIGlet::Control uses control files, which tell it to
map certain input characters to certain other characters,
similar to the Unix tr command. Control files can be
identified by the suffix I<.flc>. Most Text::FIGlet::Control
control files will be stored in FIGlet's default font directory.

The following control file commands are supported, for more
detail see F<figfont.txt> included with this distribution.

=over

=item f Freeze

A kind of "save state",
executes all previously accumulated translations before continuing.

=item t Translate

Both the explicit forms "t in out" and "t in-range out-range"
as well as the implicit form "number number".

B<Note that if you are mapping in negative characters,
you will need to C<figify> in Unicode mode I<-U>>. See also B<u> below.

=item u Unicode

Process text as Unicode (UTF-8).

Note that this is required for perl 5.6 if you are doing negative mapping.

=back

=head1 OPTIONS

=head2 C<new>

=over

=item B<-C=E<gt>>F<controlfile>

Control objects are used to peform various text translations specified
by an I<flc> file.

  $_ = "Hello World";
  my $flc = Text::FIGlet::Control->new(-C=>'rot13');
  print $font->figify($flc->());
  #The text "Urryb Jbeyq" is output.

Multiple -C parameters may be passed, and the object
returned will be an aggregate of the specified controls.

  my $flc  = Text::FIGlet::Control->new(-C=>'upper', -C=>'rot13');
  my $out0 = $flc->();
  #The text "uRRYB jBEYQ" is output.

  #This is equivalent
  my $flc1  = Text::FIGlet::Control->new(-C=>'upper',);
  my $flc2  = Text::FIGlet::Control->new(-C=>'rot13');
  my $out1 = $flc2->($flc1->();

  #So is this
  my $out2 = $flc1->($flc2->());
  #NOTE: Controls are not commutative.
  #Order of chained controls is only
  #insignificant for some controls.

=back

=head2 C<tr>

=over

=item I<scalar>

Process text in I<scalar>.

=back

=head1 ENVIRONMENT

B<Text::FIGlet::Control>
will make use of these environment variables if present

=over

=item FIGLIB

The default location of fonts.
If undefined the default is F</usr/games/lib/figlet>

=back

=head1 FILES

FIGlet control files are available at

  ftp://ftp.figlet.org/pub/figlet/

=head1 CAVEATS

There is a mystery bug in perls 5.6.1 and 5.6.2 which can cause seemingly
simple transliterations to fail. The standard figlet(1) F<upper.flc> is an
example of such a transliteration. For this reason, the enclosed F<upper.flc>
uses a C<freeze> after the ASCII swapping. I've no idea why, but it seems to
work. If you experience similar problems with other control files, try some
shotgun debugging with freezes yourself. Modern perls, 5.6.0 and even 5.005_05
do not have this problem.

=head1 SEE ALSO

L<Text::FIGlet>, L<figlet(6)>, L<tr(1)>

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
