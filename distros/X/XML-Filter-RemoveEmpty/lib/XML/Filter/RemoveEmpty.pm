=head1 NAME

XML::Filter::RemoveEmpty - Filter out tags with no character data

=cut

package XML::Filter::RemoveEmpty;

use strict;
use warnings;

use base qw(XML::SAX::Base);

use Alias 'attr';
use Text::Trim;
use XML::Filter::BufferText;
$Alias::AttrPrefix = "main::";

use enum qw(EMPTY FULL);

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Removes tags which contain neither character data nor descendants containing
character data. Considers whitespace meaningless by default and trims it, but
can preserve it; defaults to removing comments, but this can also be changed.

    use XML::Filter::RemoveEmpty;
    use XML::SAX::Machines qw( :all );

    my $filter = XML::Filter::RemoveEmpty->new(
        Comments       => 'strip' # (default)
        # or Comments  => 'preserve', # (NOT WORKING)
        TrimWhitespace => 'only' # (only removes ws-only data)
        # or
        #    TrimWhitespace => 'always'
        #    (default - always trims leading and trailing whitespace)
    );

    my $machine = Pipeline( $filter => \*STDOUT );

    $machine->parse_file(\*STDIN);

=head1 METHODS

Overrides new(), start_element(), end_element(), characters(), and comment()
from L<XML::SAX::Base>.

=over 4

=item new

Takes a list of key-value pairs for configuration (see SYNOPSIS).

=cut

sub new {
	my $type = shift;
	my %defaults = (
		TrimWhitespace	=> 'always',
		Comments		=> 'strip',
	);
	my %args = @_;
	my %force = (
		Comments	=> 'strip',
		Handler		=> XML::Filter::BufferText->new,
	);
	$type->SUPER::new(%defaults, %args, %force);
}

=item start_element

See L<XML::SAX::Base/start_element>

=cut

sub start_element {
	my $self = attr shift;
	my ($data) = @_;
	my $val = {
		data	=> $data,
		status	=> EMPTY
	};
	push @::stack, $val;
}

=item end_element

See L<XML::SAX::Base/end_element>

=cut

sub end_element {
	my $self = attr shift;
	my $top = $::stack[-1];
	if ($top->{status} == FULL or $top->{printed}) {
		$self->_print_stack(@::stack);
		$self->SUPER::end_element($top->{data});
	}
	pop @::stack;
}

=item characters

See L<XML::SAX::Base/characters>

=cut

sub characters {
	# We assume we have been passed all character data at once (use other
	# modules to acheive this effect)
	my $self = attr shift;
	my ($data) = @_;
	my $td = $self->_handle_text($data->{Data});
	# Can't just check value because we might preserve only whitespace
	if (length $td) {
		# FIXME: Doesn't preserve mixed order of mixed-type tags
		$::stack[-1]->{characters}{Data} = $td;
		$::stack[-1]->{status} = FULL;
	}
}

=item comment

See L<XML::SAX::Base/comment>

=cut

sub comment {
	my $self = shift;
	$self->{Comments} eq 'preserve' and $self->SUPER::comment(@_)
}

=item _print_stack

Called when character data encountered; generates SAX events for pending tags

=cut

sub _print_stack {
	my ($self, @stack) = @_;
	return unless @stack;
	my $bottom = shift @stack;
	unless ($bottom->{printed}) {
		$self->SUPER::start_element($bottom->{data});
		$self->SUPER::characters($bottom->{characters});
		$bottom->{printed}++;
	}
	$self->_print_stack(@stack);
}

=item _handle_text

Does string manipulation depending on trim settings

=cut

sub _handle_text {
	my $self = attr shift;
	local $_ = defined $_[0] ? $_[0] : "";
	(defined $_ && length $_)
		? ($::TrimWhitespace eq 'only' and s/^\s*$//, $_)
			|| trim($_)
		: "";
	
}

=back

=head1 BUGS

May not preserve the content ordering of mixed-content tags (a tag with both
character data and other tags within it). Specifically, all character data in a
particular tag will be printed together before any inner tags are printed.

Comments are currently always stripped because of a weakness in implmentation.

Please report any bugs or feature requests to
C<bug-xml-filter-removeempty at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Filter-RemoveEmpty>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Filter::RemoveEmpty

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Filter-RemoveEmpty>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Filter-RemoveEmpty>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Filter-RemoveEmpty>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Filter-RemoveEmpty>

=back

=head1 ACKNOWLEDGEMENTS

L<XML::Filter::Sort>, whose SYNOPSIS I stole.

=head1 AUTHOR

Darren Kulp, C<< <darren at kulp.ch> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Darren Kulp, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__END__

