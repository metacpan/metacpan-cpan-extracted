package WWW::Hashbang::Pastebin::Client;
use strict;
use warnings;
# ABSTRACT: a client library for WWW::Hashbang::Pastebin websites
our $VERSION = '0.003'; # VERSION

use HTTP::Tiny;
use Carp;


sub new {
    my $class = shift;
    my %args = @_;
    croak 'No pastebin URL provided' unless $args{url};
    croak 'Pastebin must be an absolute URL' unless $args{url} =~ m{^http};

    my $self = { url => $args{url} };
    $self->{ua} = HTTP::Tiny->new(
        agent => __PACKAGE__ . '/'
            . (__PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev')
            . ' (+https://metacpan.org/module/' . __PACKAGE__ . ')'
    );

    return bless $self, $class;
}


sub paste {
    my $self = shift;
    my %args = @_;

    if ($args{file}) {
        $args{paste} = do {
            local $/;
            open my $in, '<', $args{file}
                or die "Can't open $args{file} for reading: $!";
            <$in>
        };
    }
    croak 'No paste content given' unless $args{paste};

    my $post_response = $self->{ua}->post_form(
        $self->{url}, { p => $args{paste} }
    );

    return $post_response->{headers}->{'X-Pastebin-URL'} || $post_response->{content}
        if $post_response->{success};

    die $post_response->{status}, ' ' , $post_response->{reason}, ' ', $post_response->{content};
}


sub put {
    my $self = shift;
    $self->paste(@_);
}


sub get {
    my $self = shift;
    my $id   = shift;
    croak 'No paste ID given' unless $id;
    
    $id =~ s{^\Q$self->{url}\E}{} if ($id =~ m/\Q$self->{url}\E/);
    $id =~ s{^/}{};
    $id =~ s{\+$}{};
    chomp $id;

    my $URI = "$self->{url}/$id";
    my $get_response = $self->{ua}->get($URI);

    return $get_response->{content} if $get_response->{success};

    die $get_response->{status}, ' ' , $get_response->{reason}, ' ', $get_response->{content};
}


sub retrieve {
    my $self = shift;
    $self->get(@_);
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

WWW::Hashbang::Pastebin::Client - a client library for WWW::Hashbang::Pastebin websites

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WWW::Hashbang::Pastebin::Client;
    my $client = WWW::Hashbang::Pastebin::Client->new(url => 'http://p.hashbang.ca');

    # retrieve paste content by paste ID
    print $client->get('b'), "\n";

    # create a paste from a string
    my $pasted_string_url = $client->paste(paste => rand());

    # create a paste from a file
    my $pasted_file_url = $client->paste(file => '/var/log/syslog');

    print "$pasted_string_url\n$pasted_file_url\n";

=head1 DESCRIPTION

B<WWW::Hashbang::Pastebin::Client> is, as you  might expect, a client library
for interfacing with L<WWW::Hashbang::Pastebin> websites. It also ships with
an example command-line client L<p>.

=head1 METHODS

=head2 new

Creates a new client object. You must provide the URL of the
L<WWW::Hashbang::Pastebin> site you want to talk to:

    my $client = WWW::Hashbang::Pastebin::Client->new(url => 'http://p.hashbang.ca');

=head2 paste

Create a new paste on the specified website. Specify either C<file> to read in
the named file, or C<paste> to provide the text directly:

    # create a paste from a string
    my $pasted_string_url = $client->paste(paste => rand());

    # create a paste from a file
    my $pasted_file_url = $client->paste(file => '/var/log/syslog');

    print "$pasted_string_url\n$pasted_file_url\n";

=head2 put

This is a synonym for L</paste>.

=head2 get

Get paste content from the pastebin. Pass just the ID of the paste:

    # retrieve paste content by paste ID
    print $client->get('b'), "\n";

=head2 retrieve

This is a synonym for L</get>

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/WWW-Hashbang-Pastebin-Client/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/WWW::Hashbang::Pastebin::Client/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/WWW-Hashbang-Pastebin-Client>
and may be cloned from L<git://github.com/doherty/WWW-Hashbang-Pastebin-Client.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/WWW-Hashbang-Pastebin-Client/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

