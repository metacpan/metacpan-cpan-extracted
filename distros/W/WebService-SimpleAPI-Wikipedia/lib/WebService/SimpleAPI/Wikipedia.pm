package WebService::SimpleAPI::Wikipedia;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use LWP::UserAgent;
use Readonly;
use URI;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw/ ua /);

use WebService::SimpleAPI::Wikipedia::Parser;

Readonly my $ApiHost => 'wikipedia.simpleapi.net';

sub api {
    my($self, $opt) = @_;

    unless ($self->ua) {
        $self->ua( LWP::UserAgent->new );
        $self->ua->agent(sprintf '/', __PACKAGE__, $self->VERSION);
    }

    my $uri = $self->_make_uri('/api', $opt);
    return unless $uri;

    my $res = $self->ua->get($uri);
    croak $res->status_line if $res->is_error;

    return $res->content if $opt->{output} && $opt->{output} ne 'xml';

    my $rs = WebService::SimpleAPI::Wikipedia::Parser->parse($res->content);
    return wantarray ? @$rs : $rs;
}

sub _make_uri {
    my($self, $path, $opt) = @_;
    return '' unless $self->_validator($opt);

    my $uri = URI->new;
    $uri->scheme('http');
    $uri->host($ApiHost);
    $uri->path($path);
    $uri->query_form($opt);

    return $uri->as_string;
}

sub _validator {
    my($self, $opt) = @_;

    for my $key (qw/ keyword q /) {
        utf8::encode($opt->{$key}) if $opt->{$key} and utf8::is_utf8($opt->{$key});
    }

    $opt->{keyword} or $opt->{q} or croak 'No parameters was given';
    $opt;
}

1;

__END__

=head1 NAME

WebService::SimpleAPI::Wikipedia - Handle WikipediaAPI of SimpleAPI

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WebService::SimpleAPI::Wikipedia;

    my $api = WebService::SimpleAPI::Wikipedia->new;
    my $res = $api->api({ keyword => 'Google', search => 1 });

    print $res->nums, ' Results\n';
    for my $r (@{ $res }) {
        print $r->language;
        print $r->id;
        print $r->url; # URI Object
        print $r->url->host;
        print $r->url->path;
        print $r->title;
        print $r->body;
        print $r->length;
        print $r->redirect;
        print $r->strict;
        print $r->datetime; # DateTime Object
        print $r->datetime->year;
        print $r->datetime->month;
        print $r->datetime->day;
    }


    my $api = WebService::SimpleAPI::Wikipedia->new({ quiet => 1 });
    my $json = $api->api({ keyword => 'Google', search => 1, output => 'json' });


=head1 DESCRIPTION

The content of Wikipedia concerning the specified key word is made a digest and it returns it. 
Detailed explanation is L<http://wikipedia.simpleapi.net/>. (Japanese)

=head1 Methods

=over 4

=item api($options)

returns api results as a result set.

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<http://wikipedia.simpleapi.net/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
