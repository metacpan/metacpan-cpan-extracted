package WWW::Hashbang::Pastebin;
use strict;
use warnings;
use 5.014000;
use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema);
use Dancer::Plugin::EscapeHTML qw(escape_html);
use Integer::Tiny;
use Try::Tiny;
use DateTime;

# ABSTRACT: command line pastebin
our $VERSION = '0.004'; # VERSION


my $mapper = do {
    my $key = config->{key} || join '', ('a'..'z', 0..9);
    $key =~ tr/+//d;
    Integer::Tiny->new($key);
};


get '/' => sub {
    return template 'index';
};

post '/' => sub {
    my $paste_content = param('p') || param('sprunge');
    my $lang = param('lang');

    unless ($paste_content) {
        status 'bad_request';
        return 'No paste content received';
    }

    my $now = DateTime->now( time_zone => 'UTC' );
    my $row = schema->resultset('Paste')->create({
        paste_content => $paste_content,
        paste_date    => $now,
    });

    my $ext_id  = $mapper->encrypt($row->id);
    my $ext_url = uri_for("/$ext_id");
    $ext_url = "$ext_url?$lang" if $lang;
    debug "Created paste $ext_id: $ext_url";
    headers
        'X-Pastebin-ID'     => $ext_id,
        'X-Pastebin-URL'    => $ext_url;
    return "$ext_url\n";
};

get '/:id' => sub {
    my $ext_id = param('id');
    my $line_nos = ($ext_id =~ s{\+$}{});

    my $int_id = try { $mapper->decrypt( $ext_id ) } || do {
        status 'bad_request';
        return "'$ext_id' is not a valid paste ID";
    };
    debug "paste ID requested: $int_id";

    my $paste = schema->resultset('Paste')->find( $int_id );

    unless ($paste) {
        my $msg = "No such paste as '$ext_id'";
        warning $msg;
        content_type('text/plain');
        status 'not_found';
        return $msg;
    }
    elsif ($paste->deleted) {
        warning "Request was for deleted paste '$ext_id'->'$int_id'";
        status 'gone';
        return "No such paste as '$ext_id'";
    }

    headers 'X-Pastebin-ID' => $ext_id;
    if ($line_nos) {
        open my $in, '<', \$paste->content;
        1 while (<$in>);
        my $lines = $.;
        close $in;
        return template paste => { content => $paste->content, lines => [1..$lines] };
    }
    else {
        content_type('text/plain');
        return $paste->content;
    }
};


true;

__END__
=pod

=encoding utf-8

=head1 NAME

WWW::Hashbang::Pastebin - command line pastebin

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    $ (hostname ; uptime) | curl -F 'p=<-' http://p.hashbang.ca
    http://p.hashbang.ca/f4s2
    $ chromium-browser http://p.hashbang.ca/f4s2+#l2

=head1 DESCRIPTION

This pastebin has no user interface - use C<curl> or L<WWW::Hashbang::Pastebin::Client>'s
C<p> command to POST paste content. Your paste's ID is returned in the
C<X-Pastebin-ID> header; the URL in the C<X-Pastebin-URL>, as well as the response
content.

Append a plus sign to the URL to get line numbers. Add an anchor like C<#l1> to
jump to the given line number, or click the line number you want. The line number
for the selected line will be highlighted.

=for test_synopsis 1;
__END__

=head1 SEE ALSO

=over 4

=item * L<http://sprunge.us>

=item * L<http://p.defau.lt>

=back

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/WWW-Hashbang-Pastebin/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/WWW::Hashbang::Pastebin/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/WWW-Hashbang-Pastebin>
and may be cloned from L<git://github.com/doherty/WWW-Hashbang-Pastebin.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/WWW-Hashbang-Pastebin/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

