package Tk::TextHighlight::Xresources;

use vars qw($VERSION);
$VERSION = '0.2';

use strict;
use base('Tk::TextHighlight::Template');

sub new {
  	my ($proto, $rules) = @_;
  	my $class = ref($proto) || $proto;
	if (not defined($rules)) {
		$rules =  [
			['Comment', -foreground => 'lightblue'],
			['Path', -foreground => 'brown'],
			['Command', -foreground => 'blue'],
			['Separator', -foreground => 'darkblue'],
			['Value', -foreground => 'orange'],
			['False', -foreground => 'red'],
		];
	};
	my $self = $class->SUPER::new($rules);
  	bless ($self, $class);
  	return $self;
}

sub highlight {
	my ($hlt, $in) = @_;
	$hlt->snippet('');
	my $out = $hlt->out;
	@$out = ();
	if ($in =~ /^(\s+!|!)/go) {
		$hlt->snippet($in);
		$hlt->tokenParse('Comment');
	} elsif ($in =~ /^(\s+#|#)/go) {
		$hlt->snippet($in);
		$hlt->tokenParse('Command');
	} elsif ($in =~ /([^:]+)(:)([^:]+)/go) {
		$hlt->snippet($1);
		$hlt->tokenParse('Path');
		$hlt->snippet($2);
		$hlt->tokenParse('Separator');
		$hlt->snippet($3);
		$hlt->tokenParse('Value');
	} else {
		$hlt->snippet($in);
		$hlt->tokenParse('False');
	}
	return @$out;
}

sub syntax {
	my $hlt = shift;
	return 'Xresources';
}

1;

__END__


=head1 NAME

Tk::TextHighlight::Xresources - a Plugin for xresources files syntax highlighting

=head1 SYNOPSIS

 require Tk::TextHighlight::Xresources;
 my $sh = new Tk::TextHighlight::Xresources([
    ['Comment', -foreground => 'lightblue'],
    ['Path', -foreground => 'brown'],
    ['Command', -foreground => 'blue'],
    ['Separator', -foreground => 'darkblue'],
    ['Value', -foreground => 'orange'],
    ['False', -foreground => 'red'],
 ]);

=head1 DESCRIPTION

Tk::TextHighlight::Xresources is a  plugin module that provides syntax highlighting
for xresources files to a Tk::TextHighlight text widget.

It inherits Tk::TextHighlight::Template. See also there.

=head1 METHODS

=over 4

=item B<highlight>(I<$string>);

returns a list of string snippets and tags that can be inserted
in a Tk::Text like widget instantly.

=cut

=head1 AUTHOR

Hans Jeuken (haje@toneel.demon.nl)

=cut

=head1 BUGS

Unknown

=cut
