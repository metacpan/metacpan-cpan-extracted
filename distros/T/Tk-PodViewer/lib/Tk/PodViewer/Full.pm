package Tk::PodViewer::Full;

use strict;
use warnings;
use vars qw ($VERSION);
$VERSION =  0.03;
use base qw(Tk::Derived Tk::PodViewer);

Construct Tk::Widget 'PodViewerFull';

=head1 NAME

Tk::PodViewer::Full - Deluxe Tk::PodViewer widget.

=head1 SYNOPSIS

 require Tk::PodViewer::Full
 my $podviewer = $app->PodViewerFull->pack;
 $podviewer->load('SomePerlFileWithPod.pm');

=head1 DESCRIPTION

Tk::PodViewer::Full is a deluxe verstion of L<Tk::PodViewer>.
It adds a toolbar and a popable search bar.

=head1 OPTIONS

=over 4

=item Switch: B<-nextimage>

Image to be used for the next button.

=item Switch: B<-previmage>

Image to be used for the previous button.

=item Switch: B<-zoominimage>

Image to be used for the zoom-in button.

=item Switch: B<-zoomoutimage>

Image to be used for the zoom-out button.

=item Switch: B<-zoomresetimage>

Image to be used for the zoom-reset button.

=back

=head1 ADVERTISED SUBWIDGETS

C<Searchbar> The poppable search bar.

C<Search> The entry inside the Searchbar.

C<Toolbar> The tool frame in the top.

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	my @bpack = (-side => 'left', -padx => 2, -pady => 2);
	my @bopt = (-relief => 'flat');
	my $txt = $self->Subwidget('txt');
#	my $parent = $txt->parent;
#	my $toolframe = $parent->Frame->pack(
	my $toolframe = $self->Frame->pack(
		-before => $txt,
		-fill => 'x',
		-padx => 2,
		-pady => 2,
	);
	$self->Advertise('Toolbar', $toolframe);
	
	#creating previous button
	my $prev = $toolframe->Button(@bopt,
		-text => '<- Previous',
		-command => ['previous', $self],
	)->pack(@bpack);
	
	#creating next button
	my $next = $toolframe->Button(@bopt,
		-text => '-> Next',
		-command => ['next', $self],
	)->pack(@bpack);
	
	#creating zoom in button
	my $zmin = $toolframe->Button(@bopt,
		-text => '+ Zoom',
		-command => ['zoomIn', $self],
	)->pack(@bpack);
	
	#creating zoom out button
	my $zmout = $toolframe->Button(@bopt,
		-text => '- Zoom',
		-command => ['zoomOut', $self],
	)->pack(@bpack);
	
	#creating zoom reset button
	my $zmreset = $toolframe->Button(@bopt,
		-text => '0 Zoom',
		-command => ['zoomReset', $self],
	)->pack(@bpack);
	
	#create the search bar
	my $searchbar = $self->Frame;
	$self->Advertise('Searchbar', $searchbar);

	my $case = '-case';
	my $find = '';
	my $reg = '-exact';
	$searchbar->Label(
		-text => 'Find',
	)->pack(@bpack);
	my $search = $searchbar->Entry(
		-textvariable => \$find,
	)->pack(@bpack, -expand => 1, -fill => 'x');
	$self->Advertise('Search', $search);
	$search->bind('<Escape>', [$self, 'searchClose']);
	$search->bind('<Return>', sub { $self->FindNext('-forward', $reg, $case, $find) });
	$searchbar->Button(
		-text => 'Next',
		-command => sub { $self->FindNext('-forward', $reg, $case, $find) },
	)->pack(@bpack); 
	$searchbar->Button(
		-text => 'Previous',
		-command => sub { $self->FindNext('-backward', $reg, $case, $find) },
	)->pack(@bpack);
	$searchbar->Button(
		-text => 'All',
		-command => sub { $self->FindAll($reg, $case, $find) },
	)->pack(@bpack);
	$searchbar->Checkbutton(
		-text => 'Case',
		-onvalue => '-case',
		-offvalue => '-nocase',
		-variable => \$case,
	)->pack(@bpack);
	$searchbar->Checkbutton(
		-text => 'Reg',
		-onvalue => '-regexp',
		-offvalue => '-exact',
		-variable => \$reg,
	)->pack(@bpack);
	$searchbar->Button(
		-text => 'Close',
		-command => ['searchClose', $self],
	)->pack(@bpack);
	$txt->bind('<Control-f>', [$self, 'searchPop']);

	$self->ConfigSpecs(
		-nextimage => [{-image => $next}],
		-previmage => [{-image => $prev}],
		-zoominimage => [{-image => $zmin}],
		-zoomoutimage => [{-image => $zmout}],
		-zoomresetimage => [{-image => $zmreset}],
	);
	$self->Delegates(
		'FindAll' => $txt,
		'FindNext' => $txt,
		DEFAULT => $self,
	);

}

sub searchClose {
	my $self = shift;
	my $searchbar = $self->Subwidget('Searchbar');
	$searchbar->packForget if $searchbar->ismapped;
	$self->Subwidget('txt')->focus;
}

sub searchPop {
	my $self = shift;
	my $searchbar = $self->Subwidget('Searchbar');
	$searchbar->pack(-fill => 'x', -padx => 2, -pady => 2) unless $searchbar->ismapped;
	$self->Subwidget('Search')->focus;
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

L<Tk::PodViewer>

=cut


1;