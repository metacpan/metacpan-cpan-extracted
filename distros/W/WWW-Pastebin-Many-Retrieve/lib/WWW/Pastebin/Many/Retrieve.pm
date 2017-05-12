package WWW::Pastebin::Many::Retrieve;

use warnings;
use strict;

our $VERSION = '0.002';
use Carp;
use WWW::Pastebin::NoMorePastingCom::Retrieve;
use WWW::Pastebin::PastebinCa::Retrieve;
use WWW::Pastebin::PastebinCom::Retrieve;
use WWW::Pastebin::PastieCabooSe::Retrieve;
use WWW::Pastebin::PhpfiCom::Retrieve;
use WWW::Pastebin::RafbNet::Retrieve;
use WWW::Pastebin::UbuntuNlOrg::Retrieve;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw(
    _res
    _objs
    content
    response
    error
);

use overload q|""| => sub { shift->content };

sub new {
    my $self = bless {}, shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;
    $args{timeout} ||= 30;

    my %objs = (
        no_more_pasting => WWW::Pastebin::NoMorePastingCom::Retrieve->new(
            timeout => $args{timeout},
        ),
        pastebin_ca     => WWW::Pastebin::PastebinCa::Retrieve->new(
            timeout => $args{timeout},
        ),
        pastebin_com    => WWW::Pastebin::PastebinCom::Retrieve->new(
            timeout => $args{timeout},
        ),
        pastie_caboo_se => WWW::Pastebin::PastieCabooSe::Retrieve->new(
            timeout => $args{timeout},
        ),
        phpfi_com       => WWW::Pastebin::PhpfiCom::Retrieve->new(
            timeout => $args{timeout},
        ),
        rafb_net        => WWW::Pastebin::RafbNet::Retrieve->new(
            timeout => $args{timeout},
        ),
        ubuntu_nl_org   => WWW::Pastebin::UbuntuNlOrg::Retrieve->new(
            timeout => $args{timeout},
        ),
    );

    my %res = (
        no_more_pasting => qr{^
            (?:http://)?
            (?:www\.)?
            \Qnomorepasting.com/getpaste.php?\E
        }xi,
        pastebin_ca     => qr{(?:http://)? (?:www\.)? \S*? pastebin\.ca/}xi,
        pastebin_com    => qr{(?:http://)? (?:www\.)?\S*? pastebin\.com/}xi,
        pastie_caboo_se => qr{
            (?:http://)? (?:www\.)?
            \Qpastie.caboo.se/\E
            (\d+)
            /?
        }xi,
        phpfi_com       => qr{(?:http://)? (?:www\.)? phpfi\.com/(?=\d+)}xi,
        rafb_net        => qr{
            (?:http://)? (?:www\.)? rafb.net/p/ (\S+?) \.html
        }ix,
        ubuntu_nl_org   => qr{
            (?:http://)? (?:www\.)? paste\.ubuntu-nl\.org/ (\d+) /?
        }xi,
    );

    $self->_objs( \%objs );
    $self->_res( \%res  );

    return $self;
}

sub retrieve {
    my ( $self, $uri ) = @_;
    my $res_ref  = $self->_res;
    my $objs_ref = $self->_objs;

    $self->$_(undef) for qw(error content response);
    
    keys %$res_ref;
    while ( my ( $pastebin, $re ) = each %$res_ref ) {
        if ( $uri =~ $re ) {
            my $obj = $objs_ref->{$pastebin};
            my $response_ref = $obj->retrieve( $uri )
                or return $self->_set_error( $obj->error );

            $self->content( $obj->content );
            return $self->response( $response_ref );
        }
    }
    return $self->_set_error(
        'Your URI did not match any pastebin I can handle'
    );
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

1;
__END__

=head1 NAME

WWW::Pastebin::Many::Retrieve - retrieve pastes from many different pastebin sites

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::Pastebin::Many::Retrieve;

    my $paster = WWW::Pastebin::Many::Retrieve->new;

    my @pastes = qw(
        http://pastebin.ca/963177
        http://pastebin.com/d2fbd2737
        http://www.nomorepasting.com/getpaste.php?pasteid=10124
        http://pastie.caboo.se/172741
        http://phpfi.com/302683
        http://rafb.net/p/XU5KMo65.html
        http://paste.ubuntu-nl.org/61578/
    );

    for ( @pastes ) {
        print "Processing paste $_\n";

        $paster->retrieve( $_ )
            or warn $paster->error
            and next;

        print "Content on $_ is:\n$paster\n";
    }

=head1 DESCRIPTION

The module provides interface to retrieve pastes from several pastebins
(see "SUPPORTED PASTEBINS" section) using a single method
by giving it URI to the paste.

=head1 CONSTRUCTOR

=head2 C<new>

    my $paster = WWW::Pastebin::Many::Retrieve->new;

    my $paster = WWW::Pastebin::Many::Retrieve->new( timeout => 20 );

Constructs and returns a new WWW::Pastebin::Many::Retrieve object.
Takes one argument which is I<optional>:

=head3 C<timeout>

    my $paster = WWW::Pastebin::Many::Retrieve->new( timeout => 20 );

B<Optional>. Specifies the timeout in seconds this will be passed
into constructors for all the pastebin retrieving modules used under
the hood. See "SUPPORTED PASTEBINS" section below. B<Defaults to:>
whatever the default is for particular pastebin retrieving module; usually
it is C<30> seconds.

=head1 METHODS

=head2 C<retrieve>

    my $response = $paster->retrieve('http://uri_to_some_paste/')
        or die $paster->error;

Instructs the object to retrieve certain paste. Takes one mandatory argument
which must be the URI pointing to the paste on one of the supported
pastebin sites (see "SUPPORTED PASTEBINS" section). The return value on
success
will be what the return from C<retrieve()> method of a particular
pastebin retrieving module would return; this is differs enough to be
useless thus use the C<content()> method (see below)
to obtain the content of the paste. B<On failure returns> either C<undef>
or an empty list and the reason for failure will be available via
C<error()> method.

=head2 C<error>

    my $response = $paster->retrieve('http://uri_to_some_paste/')
        or die $paster->error;

Takes no arguments, returns a human parsable message explaining why
the call to C<retrieve()> method failed.

=head2 C<response>

    my $last_response = $paster->response;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the exact same thing last call to C<retrieve()> returned.

=head2 C<content>

    my $paste_content = $paster->content;

    print "Paste content is: $paster\n";

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the content of the paste you retrived. This method is also
overloaded as C<q|""|> thus you can simply interpolate your object
in a string to obtain the content of the paste.

=head1 SUPPORTED PASTEBINS

B<Note:> this module no longer supports http://paste.css-standards.org/
pastebin as the site no longer exists.

Currently the module is able to retrieve pastes from the following
pastebins:

=head2 http://pastebin.ca/963177

Handled by L<WWW::Pastebin::PastebinCa::Retrieve>

=head2 http://pastebin.com/d2fbd2737

Handled by L<WWW::Pastebin::PastebinCom::Retrieve>

=head2 http://www.nomorepasting.com/getpaste.php?pasteid=10124

Handled by L<WWW::Pastebin::NoMorePastingCom::Retrieve>

=head2 http://pastie.caboo.se/172741

Handled by L<WWW::Pastebin::PastieCabooSe::Retrieve>

=head2 http://phpfi.com/302683

Handled by L<WWW::Pastebin::PhpfiCom::Retrieve>

=head2 http://rafb.net/p/XU5KMo65.html

Handled by L<WWW::Pastebin::RafbNet::Retrieve>

=head2 http://paste.ubuntu-nl.org/61578/

Handled by L<WWW::Pastebin::UbuntuNlOrg::Retrieve>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-many-retrieve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-Many-Retrieve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::Many::Retrieve

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-Many-Retrieve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-Many-Retrieve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-Many-Retrieve>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-Many-Retrieve>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

