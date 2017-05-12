use strict;
use warnings;
package WWW::curlmyip;
$WWW::curlmyip::VERSION = '0.04';
use HTTP::Tiny;
use 5.008;

# ABSTRACT: Returns your ip address using L<http://curlmyip.com>


BEGIN {
    require Exporter;
    use base 'Exporter';
    our @EXPORT = 'get_ip';
    our @EXPORT_OK = ();
}


sub get_ip {
    my $response = HTTP::Tiny->new(timeout => 3)->get('http://curlmyip.com');
    die join(' ', 'Error fetching ip: ',
                  ($response->{status} or ''),
                  ($response->{reason} or '')) unless $response->{success};
    my $ip = $response->{content};
    chomp $ip;
    $ip;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::curlmyip - Returns your ip address using L<http://curlmyip.com>

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use WWW::curlmyip;

    my $ip = get_ip(); # 54.123.84.6

=head1 WARNING

curlmyip is not currently responding, do not use this module.

=head1 EXPORTS

Exports the C<get_ip> function.

=head1 FUNCTIONS

=head2 get_ip

Returns your ip address, using L<http://curlmyip.com>.

    use WWW::curlmyip;
    my $ip = get_ip();

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Farrell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
