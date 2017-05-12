package Tickit::Builder;
# ABSTRACT: Define Tickit widget structures
use strict;
use warnings FATAL => 'all';
use Tickit;
use Data::Dump qw();
use Module::Load qw();

our $VERSION = '0.001';

=head1 NAME

Tickit::Builder - widget layout definition from Perl structure or file

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Tickit::Async;
 use Tickit::Builder;
 my $layout = Tickit::Builder->new;
 $layout->run({
	widget => {
		type => 'VBox',
		children => [
			{ widget => { type => "Menu", bg => 'blue', children => [
				{ widget => { type => "Menu::Item", text => "File" } },
				{ widget => { type => "Menu::Item", text => "Edit" } },
				{ widget => { type => "Menu::Spacer", text => " " }, expand => 1 },
				{ widget => { type => "Menu::Item", text => "Help" } },
			] }},
			{ widget => { type => "HBox", text => "Static entry", children => [
				{ widget => { type => "VBox", children => [
					{ widget => { type => "Static", text => "Left panel" } },
				] }, expand => 0.15 },
				{ widget => { type => "VBox", children => [
					{ widget => { type => "Frame", style => 'single', children => [
						{ widget => { type => "Static", text => "Centre bit", fg => 'yellow' }, expand => 1 },
					] }, expand => 1 },
					{ widget => { type => "VBox", children => [
						{ widget => { type => "Static", text => "lower panel" } },
					] } },
				] }, expand => 0.85 },
			] }, expand => 1 },
			{ widget => { type => "Static", text => "Status bar", bg => 0x04, fg => 'white', } },
		],
	}
 });

=head1 DESCRIPTION

Very basic helper class for reading a widget layout definition and instantiating the required
objects. Intended to be used with the web-based or Tickit-based layout editor.

=head1 METHODS

=cut

=head2 new

Instantiate a new L<Tickit::Builder> object. Takes no parameters.

=cut

sub new {
	bless {}, shift;
}

=head2 report

Debug output.

=cut

sub report {
	my $self = shift;
	my $msg = shift;
	my @args = @_;
	foreach my $item (@args) {
		while(my $ref = ref $item) {
			if($ref eq 'CODE') {
				$item = $_->();
			} elsif(grep $ref eq $_, qw(ARRAY HASH)) {
				$item = Data::Dump::dump($item);
			} else {
				$item = "$item";
			}
		}
	}
	if(@args) {
		my $txt = join ' ', scalar(localtime), sprintf $msg, @args;
		print "$txt\n";
	} else {
		printf("%s %s\n", scalar(localtime), $msg);
	}
}

=head2 parse_widget

Parse a widget definition from a hashref.

=cut

sub parse_widget {
	my $self = shift;
	my $spec = shift;
	$self->report("Parsing widget %s", $spec);

	my %args = %$spec;
	my $class = 'Tickit::Widget::' . delete $args{type};
	my $children = delete $args{children} || [];
	my $kb = delete $args{keybindings} || {};
	my $id = delete $args{id};
	my $classname = delete $args{class};
	Module::Load::load($class);
	die "$class not found" unless $class->can('new');

	# Build up the widget in this object
	my $w;

	# Manual overrides... expect to end up with a lot of these over time :(
	if($class eq 'Tickit::Widget::Scroller::Item::Text') {
		$w = $class->new($args{text});
	} else {
		$w = $class->new(%args);
	}

	# Any nested children entries will be recursed into
	foreach my $child_def (@$children) {
		my %child_spec = %$child_def;
		$self->report("Found child def %s", $child_def);
		my $child = $self->parse_widget(delete $child_spec{widget});
		if($class eq 'Tickit::Widget::Scroller') {
			$w->push($child);
		} else {
			$w->add($child, %child_spec);
		}
	}

	# We'll also support some basic key binding
	foreach my $k (keys %$kb) {
		my $v = $kb->{$k};
		if($w->can('bind_keys')) {
			$self->report('%s is fine for binding', $class);
			$w->bind_keys($k, $v);
		} else {
			$self->report('%s cannot bind', $class);
		}
		$self->report($k . " bind for " . $v);
		my @ks = split ' ', $k;
		# this looks incomplete, perhaps we should be doing something else here?
	}

	if(defined $id) {
		die "ID [$id] was defined already\n" if exists $self->{by_id}{$id};
		Scalar::Util::weaken($self->{by_id}{$id} = $w);
	}
	if(defined $classname) {
		push @{ $self->{by_class}{$classname} }, $w;
		Scalar::Util::weaken($self->{by_class}{$classname}[-1]);
	}
	return $w;
}

=head2 by_id

Returns the widget with the given ID.

=cut

sub by_id { $_[0]->{by_id}{$_[1]} }

=head2 by_class

Returns a list of all widgets matching the given classname.

=cut

sub by_class { @{ $_[0]->{by_class}{$_[1]} } }

=head2 parse

Parse the top-level layout spec (hashref).

=cut

sub parse {
	my $self = shift;
	my $spec = shift;
	$self->report("Parsing %s", $spec);
	my $w;
	if(my $widget_def = $spec->{widget}) {
		$w = $self->parse_widget($widget_def);
	}
	die "no widget" unless $w;
	$w;
}

=head2 apply_layout

Apply the given layout to the L<Tickit> instance.

Takes two parameters:

=over 4

=item * $tickit - a L<Tickit> instance.

=item * $layout - a hashref representing the requested layout.

=back

=cut

sub apply_layout {
	my $self = shift;
	my $tickit = shift;
	my $layout = shift;
	my $root = $self->parse($layout);
	$tickit->set_root_widget($root);
}

=head2 run

Helper method to parse and run the layout definition using L<Tickit::Async>.

=cut

sub run {
	my $self = shift;
	my $spec = shift;
	my $root = $self->parse($spec);

	require Tickit::Async;
	require IO::Async::Loop;
	my $tickit = Tickit::Async->new;
	$tickit->set_root_widget($root);
	my $loop = IO::Async::Loop->new;
	$loop->add($tickit);
	$tickit->run;
}

=head2 parse_file

Parse definition from a file.

=cut

sub parse_file {
	my $self = shift;
	my ($file, $type) = @_;
	$type = 'json' unless $type;
	open my $fh, '<:encoding(utf-8)', $file or die "opening $file - $!";
	my $txt = do { local $/; <$fh> };
	if($type eq 'json') {
		require JSON;
		return JSON->new->decode($txt);
	} else {
		die 'unsupported';
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
