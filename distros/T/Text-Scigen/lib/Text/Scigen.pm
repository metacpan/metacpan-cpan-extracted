package Text::Scigen;

use 5.008001;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Scigen ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

use Carp;
use Text::Autoformat;
use Text::Scigen::scigen;

our $DATA_PATH = $INC{'Text/Scigen.pm'};
$DATA_PATH =~ s/Scigen\.pm$//;
$DATA_PATH .= "Scigen";
our $REL_PATH;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new
{
	my( $class, %self ) = @_;

	my $self = bless \%self, $class;

	Carp::croak( "Missing filename argument" )
		if !defined $self{filename};

	$self{filename} = "$DATA_PATH/$self{filename}"
		if $self{filename} !~ /^\//;

	$self{rel_path} = $self{filename};
	$self{rel_path} =~ s/\/[^\/]+$//;

	$self{debug} ||= 0;

	$self{pretty} = 1 if !defined $self{pretty};

	if( open(my $fh, "<:utf8", $self{filename}) ) {
		Text::Scigen::scigen::read_rules (
			$fh,
			$self{dat} = {},
			\$self{RE},
			$self{debug},
			$self
		);
	}
	else {
		Carp::croak( "Error reading from $self{filename}: $!" );
	}

	return $self;
}

sub generate
{
	my( $self, $start ) = @_;

	$start = [$start] if ref($start) ne "ARRAY";

	return join "\n", map { Text::Scigen::scigen::generate (
		$self->{dat},
		$_,
		$self->{RE},
		$self->{debug},
		$self->{pretty}
	) } @$start;
}

sub _find
{
	my( $self, $filename ) = @_;

	return $filename if -e $filename;
	return "$self->{rel_path}/$filename" if -e "$self->{rel_path}/$filename";

	die "Can't find $filename\n";
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::Scigen - Generate convincing-looking scientific articles

=head1 SYNOPSIS

  use Text::Scigen;
  
  my $scigen = Text::Scigen->new(
  	filename => $filepath,
  );
  print $scigen->generate( "SCI_TITLE" );

=head1 DESCRIPTION

"An Automatic CS Paper Generator"

=head2 Source Files

The following source files are included. To use a different file specify an absolute path (leading '/').

=over 4

=item functions.in

=item svg_figures.in

=item talkrules.in

=item graphviz.in

=item scirules.in

Generates a LaTeX document starting with SCIPAPER_LATEX.

=item system_names.in

=back

=head2 EXPORT

None by default.

=head1 METHODS

=over 4

=item $scigen = Text::Scigen->new( OPTIONS )

Create a new Science Paper generator.

Options:

	filename - source file to read from

=item $text = $scigen->generate( START )

Generates and returns text starting at key START. If START is an array ref concantenates (with space) each generated text.

=back

=head1 SEE ALSO

L<Text::Autoformat>, L<Text::Lorem>

http://pdos.csail.mit.edu/scigen/

=head1 MAINTAINER

Tim Brody, E<lt>tdb2@ecs.soton.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
