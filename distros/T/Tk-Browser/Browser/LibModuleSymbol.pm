package Browser::LibModuleSymbol;
my $RCSRevKey = '$Revision: 1.1.1.1 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=0.53;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
push @ISA, qw( Exporter DB );

=head1 NAME

Browser::LibModuleSymbol.pm -- Scanning of Perl symbol tables and
library modules.

=head1 DESCRIPTION

Browser::LibModuleSymbol.pm Provides Perl symbol table and lexical
routines for Tk::Browser(3).

=head1 REVISION

$Id: LibModuleSymbol.pm,v 1.1.1.1 2015/04/18 18:43:42 rkiesling Exp $

=head1 SEE ALSO

Browser::LibModule(3), Tk::Browser(3), perlmod(1), perlmodlib(1), perl(1).

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;
  my $self = {
	      pathname => undef,
	      packagename => undef,
	      version => undef,
	      refsymbols => []
	      };
  bless( $self, $class);
  return $self;

}

my @scannedpackages;

sub scannedpackages {
  if( @_ ) { @scannedpackages = @_ }
  return @scannedpackages;
}

sub text_symbols {
  my $p = shift;
  my (@text, $pathname) = @_;
  my @matches;
  my $nmatches;
  my $package;
  my @unsortedsymbols;
  my ($i, $j, $k);
  if ($text[0] =~ /^package/) { $package = $text[0] };
  if ($package) {
      $package =~ s/(^package\s+)|(\s*\;.*$)//g;
      chop $package;
  } else {
      return undef;
  }
  @matches = grep /$package/, @scannedpackages;
  return undef if ( $nmatches = @matches );
  @matches = grep /\$VERSION/, @text;
  $matches[0] =~ /(\$VERSION[ \t]*=[ \t]*(.*?)\;)/ if $matches[0];
  my $ver = $2;
  $p -> {pathname} = $pathname;
  $p -> {packagename} = $package;
  $p -> {version} = $ver;
  # find subs;
  @{$p -> {refsymbols}} = grep /^sub\s+\S*?.*$/, @text;
  # find everything else
  @matches = grep /[\$\@\%]\w+/, @text;
  VARS: foreach $i ( @matches ) {
      $i =~ /([\$\@\%]\w+)/;
      $j = $1;
      foreach $k ( @{$p -> {refsymbols}} ) {
	next VARS if $k eq $j;  
      }
      push @{$p -> {refsymbols}}, ($j);
    }
  push @scannedpackages, ($package);
  return 1;
}

my %xrefcache;

sub xrefcache {
    my $self = shift;
    if (@_) { $self -> {xrefcache} = shift; }
    return $self -> {xrefcache}
}

sub xrefs {
  my $symobject = shift;
  my ($sym) = @_;
  my $key;
  my $modulepathname;
  my @packagefiles = ();
  my @text;
  my @matches;
  my $nmatches;
  my $i = 0;
  foreach $key ( keys %{*{"main\:\:"}} ) {
    if( $key =~ /^\_\<(.*)$/ ) {
      $modulepathname = $1;
      next if $modulepathname !~ /\.pm$/;
      if( $xrefcache{$modulepathname} ) {
	push @text, @{$xrefcache{$modulepathname}};
      } elsif( open MODULE, "<$modulepathname" ) {
	@text = <MODULE>;
	# weed out comments
	foreach (@text) { $_ =~ s/\#.*$// }
	close MODULE;
	push @{$xrefcache{$modulepathname}}, @text;
      }
      if ( &usesTk ) {
	&Tk::Event::DoOneEvent(255);
      }
      @matches = grep /$sym/, @text;
      $nmatches = @matches;
#      print "$sym: $nmatches match(es): in $modulepathname:\n";
#      foreach (@matches ) {print "   $_\n";}
      push @packagefiles, ($modulepathname) if ($nmatches > 0) ;
    }
  }
  return @packagefiles;
}

sub pathname {
    my $self = shift;
    if (@_) { $self -> {pathname} = shift; }
    return $self -> {pathname}
}

sub packagename {
    my $self = shift;
    if (@_) { $self -> {packagename} = shift; }
    return $self -> {packagename}
}

sub refsymbols {
    my $self = shift;
    if (@_) { $self -> {refsymbols} = shift; }
    return $self -> {refsymbols}
}

sub usesTk {
  return ( exists ${"main\:\:"}{"Tk\:\:"} );
}

1;

