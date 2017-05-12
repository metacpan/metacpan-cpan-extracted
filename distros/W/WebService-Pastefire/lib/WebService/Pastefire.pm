package WebService::Pastefire;
use 5.008001;
use utf8;
use strict;
use warnings;
use parent 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw!
    username password expire url max
!);

use Carp;
use LWP::Simple;
use URI;
our $VERSION = '0.02';

sub new { my $class = shift; #{{{
    my $args = ref $_[0] ? $_[0] : +{@_};
    croak 'please specify email & password'
        unless defined $args->{username} && defined $args->{password};

    return $class->SUPER::new(+{
        url => 'https://pastefire.com/set_bookmarklet.php',
        expire => 3600,
        max => 300,
        %$args,
    });
} #}}}

sub paste { my ($self, $str) = @_; #{{{
    substr($str, -3) = '...' if $self->max < length $str;

    my $uri = URI->new($self->url);
    $uri->query_form(
        clipboard => $str,
        email => $self->username,
        pwd => $self->password,
        kexp => $self->expire,
        optin => 0,
    );
    my $res = get($uri->as_string);

    if ($res eq $str) {
        return 1;
    } else {
        return 0;
    }
} #}}}

1;
__END__

=encoding UTF-8

=head1 NAME

WebService::Pastefire - module for using Pastefire.com

=head1 SYNOPSIS

    use WebService::Pastefire;
    my $pf = WebService::Pastefire->new(
        username => 'someuser',
        password => 'somepass',
    );
    $pf->paste('PASTE ME!');

=head1 DESCRIPTION

C<WebService::Pastefire> is for using Pastefire.com - can send text to your iOS
devices.

To specify you and your devices, you need username (= email address) & password.
You must install Pastefire App to your devices and set the same username /
password.

See L<Pastefire app › Home|http://pastefire.com/> for detail setting.

=head1 METHODS

=over 4

=item * new()

Constructor. C<username> & C<password> are mandatory.

=item * paste()

Set text you want paste to a parameter. 

=back

=head1 AUTHOR

JINNOUCHI Yasushi E<lt>delphinus@remora.cxE<gt>

=head1 SEE ALSO

L<Pastefire app › Home|http://pastefire.com/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
