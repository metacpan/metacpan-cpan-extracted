use strict;
use warnings;
package WebService::Bukget;
{
  $WebService::Bukget::VERSION = '1.00';
}
# ABSTRACT: Provides access to the v3 Bukget API
use Mojo::Base '-base';
use Mojo::JSON;
use Mojo::UserAgent;
use Try::Tiny qw/try catch/;
use boolean;

has     '_ua'           =>  sub { Mojo::UserAgent->new };

# these are here so they can be overridden if needed
has     'url_base'      =>  'http://dev.bukget.org/3';

sub _fetch {
    my $self = shift;
    my $e    = shift;
    my $args = shift;
    my $p    = $args->{'params'} || {};

    my $u = Mojo::URL->new(sprintf('%s/%s', $self->url_base, $e));
    foreach my $pk (keys(%$p)) {
        $u->query->param($pk => $p->{$pk});
    } 

    if(my $tx = $self->_ua->get($u)) {
        if(my $res = $tx->success) {
            $args->{on_success}->($self => $res->json) if(defined($args->{on_success}));
        } else {
            my ($err, $code) = $tx->error;
            $args->{on_failure}->($self => $err => $code) if(defined($args->{on_failure}));
        }
    } else {
        $args->{on_failure}->($self) if(defined($args->{on_failure}));
    }
}

sub _fix_fields {
    my $self = shift;
    my $s    = shift;

    $s->{params}->{fields} = join(',', @{$s->{params}->{fields}}) if(defined($s->{params}->{fields}) && ref($s->{params}->{fields}) eq 'ARRAY');
    return $s;
}

# endpoint accessors
sub geninfo { shift->_fetch('geninfo' => shift) }

sub plugins { 
    my $self = shift;
    my $s    = shift;
    my $e    = 'plugins';

    unless(defined($s) && ref($s) eq 'HASH') {
        $e .= '/' . $s;
        $s = shift;
    }
    $self->_fetch($e => $self->_fix_fields($s));
}

sub categories { 
    my $self = shift;
    my $e    = 'categories';
    my $scn  = shift;
    my $cn   = shift;
    my $s    = shift;

    if(defined($scn) && ref($scn) eq 'HASH') {
        # plain categories
        $self->_fetch('categories' => $self->_fix_fields($scn));
    } elsif(defined($cn) && ref($cn) eq 'HASH') {
        # categories/categoryname
        $self->_fetch(sprintf('categories/%s', $scn) => $self->_fix_fields($cn));
    } elsif(defined($scn) && defined($cn) && defined($s) && ref($s) eq 'HASH') {
        # categories/server/categoryname
        $self->_fetch(sprintf('categories/%s/%s', $scn, $cn) => $self->_fix_fields($s));
    } 
}

sub authors { 
    my $self = shift;
    my $e    = 'authors';
    my $san  = shift;
    my $an   = shift;
    my $s    = shift;

    if(defined($san) && ref($san) eq 'HASH') {
        # plain authors 
        $self->_fetch('authors' => $self->_fix_fields($san));
    } elsif(defined($an) && ref($an) eq 'HASH') {
        # authors/authorname
        $self->_fetch(sprintf('authors/%s', $san) => $self->_fix_fields($an));
    } elsif(defined($san) && defined($an) && defined($s) && ref($s) eq 'HASH') {
        # authors/server/authorname
        $self->_fetch(sprintf('authors/%s/%s', $san, $an) => $self->_fix_fields($s));
    } 
}

1;

__END__
=pod

=head1 NAME

WebService::Bukget - Provides access to the v3 Bukget API

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    use WebService::Bukget;

    my $bukget = WebService::Bukget->new();
    my $authors = $bukget->authors;

=head1 NAME

WebService::Bukget - A module that allows easy access to the Bukget API

=head1 CALLING CONVENTIONS

All methods used to access Bukget endpoints expect you to pass at the very least a hashref
with the following keys:

=over 4

=item * on_success - A coderef that gets the WebService::Bukget instance and the decoded JSON result as parameters

=item * on_failure - A coderef that gets an arrayref of code and status as parameters

=back

Optionally you can pass another key called C<params> which should be a hashref of parameters to pass to the get request.
See the examples below for more information, and also see the API documentation at L<http://bukget.org/pages/docs/API3.html>

=head1 METHODS

=head2 geninfo

Maps to the C<geninfo> endpoint

=head2 categories

Maps to the C<categories> endpoint

=head2 plugins

Maps to the C<plugins> endpoint

=head2 authors

Maps to the C<authors> endpoint

=head1 EXAMPLES

    # Fetch the latest geninfo 
    $bukget->geninfo({
        on_success => sub {
            my ($b, $r) = (@_);

            print 'Last updated: ', $r->[0]->{timestamp}, "\n";
        },
        on_failure => sub {
            die 'oops, ';
        },
    });

    # Fetch the latest 5 geninfo entries
    $bukget->geninfo({
        params => { 
            size => 5 
        },
        on_success => sub {
            my ($b, $r) = (@_);

            print 'Last updated: ', $_->{timestamp}, "\n" for(@$r);
        },
        on_failure => sub {
            die 'oops, ';
        },
    });

    # Fetch the first page of plugins from the 'Admin Tools' category,
    # using 10 items per page, and only fetching the slug, logo and game version fields
    $bukget->categories('Admin Tools' => {
        params => { 
            size   => 10,
            start  => 0,
            fields => [qw/slug logo versions.game_version/],
        },
        on_success => sub {
            my ($b, $r) = (@_);

            ...
        },
        on_failure => sub {
            die 'oops, ';
        },
    });

=head1 TO-DO$

=over 4

=item * Clean up the code some since it's rather ugly

=item * Add support for the search function in the Bukget API

=back

=head1 AUTHOR

Ben van Staveren, C<< <madcat at cpan.org> >>

=head1 BUGS/CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/benvanstaveren/WebService-Bukget/issues>. 
You can fork my Git repository at L<https://github.com/benvanstaveren/WebService-Bukget/> if you want to make changes or supply me with patches.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ben van Staveren.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Ben van Staveren <madcat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ben van Staveren.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

