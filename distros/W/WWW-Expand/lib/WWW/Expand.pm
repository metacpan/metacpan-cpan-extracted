package WWW::Expand;
$WWW::Expand::VERSION = '0.1.5';
use strictures 1;
use Exporter qw/import/;
use LWP::UserAgent;
use HTTP::Request;
use Carp ();

# When version isn't specified, assume DEV.
our $VERSION ||= 'DEV';

our @EXPORT = our @EXPORT_OK = qw/expand/;
our $DEFAULT_USERAGENT = "URL::Expand/$VERSION (https://metacpan.org/module/URL::Expand)";

sub expand {
    my ($url, %options) = @_;

    # Get hash value and remove it
    my $agent = delete $options{agent};

    Carp::croak "Unknown options: ", join " ", keys %options if %options;

    unless (ref $agent && $agent->isa('LWP::UserAgent')) {
        my $text_agent = defined $agent ? $agent : $DEFAULT_USERAGENT;
        $agent = LWP::UserAgent->new(agent => $text_agent);
    }
    
    $agent->request(HTTP::Request->new(HEAD => $url))->request->uri;
}
"https://github.com/xfix";

=head1 NAME

WWW::Expand - Expand any URL shortener link

=head1 SYNOPSIS

    use 5.010;
    use strictures 1;
    use WWW::Expand;
    
    print expand 'http://git.io/github';

=head1 DESCRIPTION

`expand()` is a function that expands any URL from URL shortener.

=head1 EXPORTS

All functions are exported using L<Exporter>. If you don't want this
(but why you would use this module then) try importing it using empty
list of functions.

    use WWW::Expand ();

=over 4

=item expand $url, %options

The only function in this module. It expands C<$url> from URL shortener.
It supports one option in C<%options>.

=over 4

=item agent

Can be either instance of L<LWP::UserAgent> or string containing user
agent name.

=back

=back

=head1 CAVEATS

This module tries to expand every URL, even if it isn't from URL
shortener. This could be what you want, but if not, try module such
as L<WWW::Lengthen>.

=head1 SEE ALSO

L<WWW::Lengthen>, L<WWW::Shorten>

=head1 AUTHOR
 
Konrad Borowski <glitchmr@myopera.com>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2012 by Konrad Borowski.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
