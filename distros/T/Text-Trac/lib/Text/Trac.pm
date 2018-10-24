package Text::Trac;

use strict;
use warnings;

use Text::Trac::Context;
use Text::Trac::BlockNode;

our $VERSION = '0.19';

my %Defaults = (
	html              => '',
	permalink         => '',
	min_heading_level => 1,
	class             => 1,
	id                => 1,
	span              => 1,
);

sub new {
	my ( $class, %args ) = @_;

	my $self = { %Defaults, %args, };

	bless $self, $class;
}

sub parse {
	my $self = shift;
	my $text = shift or return;

	$self->{trac_url} = '/' unless defined $self->{trac_url};
	for ( keys %$self ) {
		if ( $_ =~ /^trac.+url$/ ) {
			$self->{$_} .= '/' if $self->{$_} !~ m!/$!;
		}
	}

	my $c = Text::Trac::Context->new(
		{
			%$self, text => $text,
		}
	);

	my $node = Text::Trac::BlockNode->new(
		{
			context => $c,
		}
	);
	$node->parse;

	$self->{html} = $c->html;
}

sub html { $_[0]->{html}; }

*process = \&parse;

1;
__END__

=head1 NAME

Text::Trac - Perl extension for formatting text with Trac Wiki Style.

=head1 SYNOPSIS

    use Text::Trac;

    my $parser = Text::Trac->new(
        trac_url      => 'http://trac.mizzy.org/public/',
        disable_links => [ qw( changeset ticket ) ],
    );

    $parser->parse($text);

    print $parser->html;

=head1 DESCRIPTION

Text::Trac parses text with Trac WikiFormatting and convert it to html format.

=head1 METHODS

=head2 new

Constructs Text::Trac object.

Available arguments are:


=head3 trac_url

Base URL for TracLinks.Default is /. You can specify each type of URL individually.
Available URLs are:

=over

=item trac_attachment_url

=item trac_changeset_url

=item trac_log_url

=item trac_milestone_url

=item trac_report_url

=item trac_source_url

=item trac_ticket_url

=item trac_wiki_url

=back

=head3 disable_links

Specify TracLink types you want to disable.
All types are enabled if you don't specify this option.

    my $parser = Text::Trac->new(
        disable_links => [ qw( changeset ticket ) ],
    );

=head3 enable_links

Specify TracLink types you want to enable.Other types are disabled.
You cannot use both disable_links and enable_links at once.

    my $parser = Text::Trac->new(
        enable_links => [ qw( changeset ticket ) ],
    );



=head2 parse

Parses text and converts it to html format.

=head2 process

An alias of parse method.

=head2 html

Return converted html string.

=head1 SEE ALSO

=over 3

=item  L<Text::Hatena>

=item  L<Trac Guide|https://trac.edgewall.org/wiki/TracGuide>

=item  L<Trac WikiFormatting|https://trac.edgewall.org/wiki/WikiFormatting>

=back

=head1 AUTHORS

Gosuke Miyashita, C<< <gosukenator at gmail.com> >>

Hideaki Tanaka, C<< <drawn.boy at gmail.com)> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-trac at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Trac>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Trac

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Trac>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Trac>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Trac>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Trac>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Gosuke Miyashita, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
