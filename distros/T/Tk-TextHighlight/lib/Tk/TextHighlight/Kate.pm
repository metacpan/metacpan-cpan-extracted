package Tk::TextHighlight::Kate;

use vars qw($VERSION);
$VERSION = '0.4';
#use Syntax::Highlight::Engine::Kate::All;
use base 'Syntax::Highlight::Engine::Kate';

use strict;
use Data::Dumper;

sub new {
	my ($proto, $lang, $rules) = @_;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new;
	$lang ||= 'Perl';
	$self->{kate} = new Syntax::Highlight::Engine::Kate(language => $lang);
	if (not defined($rules)) {
		$rules =  [
#			['Alert', -foreground => 'blue'],
			['Alert', -foreground => '#ff0000'],   #RED!
			['BaseN', -foreground => '#007f00'],
			['BString', -foreground => '#c9a7ff'],
			['Char', -foreground => 'green'],
			['Comment', -foreground => 'lightblue'],
			['DataType', -foreground => 'blue'],
			['DecVal', -foreground => 'yellow'],
			['Error', -foreground => '#ff0000'],
			['Float', -foreground => 'yellow'],
			['Function', -foreground => 'darkred'],
			['IString', -foreground => 'yellow'],
			['Keyword', -foreground => 'darkgreen'],
			['Normal', -foreground => 'black'],
			['Operator', -foreground => 'black'],   #NEEDS 2B SAME AS NORMAL SO " -opt => 'str'" looks right!
			['Others', -foreground => '#b03060'],
			['RegionMarker', -foreground => '#96b9ff'],
			['Reserved', -foreground => 'darkred'],
			['String', -foreground => 'green'],
			['Variable', -foreground => 'blue'],
			['Warning', -foreground => 'yellow'],

			['Pragma', -foreground => '#694D71'],   #LAVENDER
			['String Special Character', -foreground => '#FE7800'], #AMBER
			['Special Variable', -foreground => '#4650A9'],   #MOZBLUE
			['Pattern Internal Operator', -foreground => '#5A3C28'], #MOCHA
		];
	};
	$self->{'rules'} = [];
	bless ($self, $class);
	$self->rules($rules);
#	$self->unstable(1);     #KATE DOESN'T SUPPORT THIS!
	return $self;
}

sub highlight {
	my $hlt = shift;
	my $txt =  $hlt->{kate}->highlightText(shift);
	my @target = ();
	my @lst = split /\e\e\e/o, $txt; #start to retrieve the color info tags.
	while (@lst) { #set up the insert command options.
		push(@target, length(shift @lst), shift @lst);
	};
	return @target;
}

sub rules {
	my $hlt = shift;
	if (@_) {
		my $r = shift;
		my %format = ();
		foreach my $k (@$r) {
			$format{$k->[0]} = ["", "\e\e\e" . $k->[0] . "\e\e\e"];
		}
#		$hlt->set_format(%format);
		$hlt->{kate}->formatTable(\%format);
		$hlt->{kate}->reset;
		$hlt->{'rules'} = $r;
	}
	return $hlt->{'rules'};
}

sub stateCompare {
	my ($hlt, $state) = @_;
	my $h = [ $hlt->stateGet ];
	if ($#{$h} <= $#{$state})
	{
		my ($hstr, $sstr);
		for (my $i=0;$i<=$#{$h};$i++)
		{
			$hstr = join('|',@{$h->[$i]});
			$sstr = join('|',@{$state->[$i]});
			return 0  unless ($hstr eq $sstr);
		}
		return 1;
	}
	return 0;
}

sub stateGet {
	my $hlt = shift;
	my @v = $hlt->{kate}->stateGet;
	return @v;
}

sub stateSet {
	my $hlt = shift;
	return $hlt->{kate}->stateSet(@_);
}

sub syntax {
	my $hlt = shift;
	return 'Kate',
}

1;

__END__


=head1 NAME

Tk::TextHighlight::Perl - a Plugin for Perl syntax highlighting

=head1 SYNOPSIS

Tk::TextHighlight::Kate inherits Syntax::Highlight::Engine::Kate;

  use Tk;
  require Tk::TextHighlight;

  my $m = new MainWindow;

  my $e = $m->Scrolled("TextHighlight",
    -syntax => "Kate::Perl",     #SPECIFY "Kate::" AND THE LANGUAGE OF CHOICE.
    -scrollbars => "se",
    -background => "black",
  )->pack(-expand => 1, -fill => "both");

  #OPTIONALLY ADD KATE'S LANGUAGE LIST TO THE "Syntax.View" RIGHT-BUTTON MENU:

  my ($sections, $extensions) = $e->fetchKateInfo;
  $e->addKate2ViewMenu($sections);

  $m->MainLoop;

For its limitations see also there.
This module provides extra methods to provide syntax highlighting
for the Perl programming language.

=head1 METHODS

=over 4

=item B<highlight>(I<$string>);

returns a list of string snippets and tags that can be inserted
in a Tk::Text like widget instantly.

=item B<rules>(I<$txtwidget>,I<\@list>)

sets and returns a reference to a list of tagnames and options.
By default it is set to:

 [
   ['Alert', -foreground => 'blue'],
   ['BaseN', -foreground => '#007f00'],
   ['BString', -foreground => '#c9a7ff'],
   ['Char', -foreground => 'green'],
   ['Comment', -foreground => 'lightblue'],
   ['DataType', -foreground => 'blue'],
   ['DecVal', -foreground => 'yellow'],
   ['Error', -foreground => '#ff0000'],
   ['Float', -foreground => 'yellow'],
   ['Function', -foreground => 'darkred'],
   ['IString', -foreground => 'yellow'],
   ['Keyword', -foreground => 'darkgreen'],
   ['Normal', -foreground => 'black'],
   ['Operator', -foreground => 'black'],   #NEEDS 2B SAME AS NORMAL SO " -opt => 'str'" looks right!
   ['Others', -foreground => '#b03060'],
   ['RegionMarker', -foreground => '#96b9ff'],
   ['Reserved', -foreground => 'darkred'],
   ['String', -foreground => 'green'],
   ['Variable', -foreground => 'blue'],
   ['Warning', -foreground => 'yellow'],
 ]

=item B<rulesConfigure>(I<$txtwidget>,I<\@list>)

Used internally. Don't call it yourself.

=item B<rulesDelete>(I<$txtwidget>,I<\@list>)

=item B<stateCompare>(\@state);

Compares @state to the current state of the formatter.
returns true when equal.

=item B<stateGet>

Returns a list of the current state of the formatter. 
Called by the highlighting routines in Tk::TextHighlight.

=item B<stateSet>(I<@list>)

Sets the state of the formatter. Called by the highlighting routines
in Tk::TextHighlight.


=back

=cut

=head1 AUTHOR

Original CodeText Author:  Hans Jeuken (haje@toneel.demon.nl)

TextHighlight Author:  Jim Turner (turnerjw784@mesh.net)

=cut

=head1 BUGS

Probably plenty

=cut
