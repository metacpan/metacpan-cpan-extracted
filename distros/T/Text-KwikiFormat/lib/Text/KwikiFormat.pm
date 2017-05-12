package Text::KwikiFormat;

use 5.006;
use strict;
use warnings;

=head1 NAME

Text::KwikiFormat - Translate Kwiki formatted text into HTML

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Text::KwikiFormat;
    my $html = Text::KwikiFormat::format('some kwiki text');

=head1 DESCRIPTION

This module allows you to convert Kwiki text using the L<Kwiki::Formatter>
module.  In the current version, it only passes the input to the formatter and
spits out the converted HTML content as it.  Customization is not supported.

For people interested in using L<CGI::Kwiki> to convert the Kwiki text, see the
module L<Text::KwikiFormatish>.

=cut

use Kwiki 0.39;

=head1 EXPORT

You can also import a customized subroutine with default options set up, pretty much the
same way as in L<Text::WikiFormat>.  Currently, only two keys are
supported:

=over 4

=item * C<prefix>, the KwikiLink prefix

=item * C<as>, an alias for the imported function (defaults 'C<wikiformat>')

=back

Examples:

    # import 'kwikiformat'
    use Text::KwikiFormat 'kwikiformat';

    # ... the same thing
    use Text::KwikiFormat as => 'kwikiFormat';

    # import 'wikiformat' with a custom prefix
    use Text::KwikiFormat prefix => 'http://www.example.com/';
    my $text = wikiformat 'some kwiki text';

=cut

sub import {
    my $class = shift;
    return unless @_;
    
    my %args = 
	@_ == 1? (as => shift): (as => 'wikiformat', @_);

    my $name = delete $args{as};
    my $caller = caller();

    no strict 'refs';
    *{$caller. "::$name"} = sub {
	my ($text, $newtags, $opts) = @_;
	$opts ||= {};
	Text::KwikiFormat::format($text, $newtags, { %$opts, %args });
    };
}

=head1 SUBROUTINES/METHODS

This module supports only one interface subroutine C<format()>.

=head2 format($text, $newtags, $opts)

The first argument C<$text> is the text to convert.

The second argument is not used.  I keep it here to comply with the
L<Text::WikiFormat> calling convention.

The options are specified as a hash reference via the third argument C<$opts>.  
Currently, only one option is supported:

=over 4

=item * prefix

This is the path to the Wiki.  The actual linked item itself will be appended
to the prefix.  This is useful to create full URIs:

	{ prefix => 'http://example.com/kwiki.pl?page=' }

=back

=cut

sub format {
    my ($text, $newtags, $opts) = @_;
    my %options = (
	prefix => '', 
	ref $opts eq 'HASH' ? %$opts: (),
    );

    my $hub = Kwiki->new->hub;
    $hub->config->add_config({ database_directory => '' });
    $hub->config->script_name($options{prefix});
    return $hub->formatter->text_to_html($text);
}

=head1 LIMITATIONS

The current version does one and only one thing: send the input to Kwiki and
fetch the output AS IS.  To customize the output format, one needs to subclass
all the necessary Kwiki::Formatter::* modules and rework the HTML output, which
is a lot of work. (I will reconsider implementing that based on the number of
RT tickets asking for this feature.)

=head1 AUTHOR

Ruey-Cheng Chen, C<< <rueycheng at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-kwikiformat at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-KwikiFormat>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ruey-Cheng Chen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Text::KwikiFormat
