package WWW::VieDeMerde;

use warnings;
use strict;

use Carp;
use LWP::UserAgent;
use XML::Twig;

use WWW::VieDeMerde::Message;
use WWW::VieDeMerde::Comment;

=encoding utf8

=head1 NAME

WWW::VieDeMerde - A perl module to use the viedemerde.fr API

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

    use WWW::VieDeMerde;
    
    my $toto = WWW::VieDeMerde->new();
    my $tata = $toto->last();
    my $tata = $toto->page(17);
    my $tata = $toto->random();
    my $tata = $toto->get(1234);
    
    print $tata->text, $tata->author;

=head1 DESCRIPTION

viedemerde.fr and fmylife.com are microblogs where people post short
messages in order to show how their life is crappy. It offers a simple
but efficient http-based API.

This module aims to implement a full interface for the version 2.0 of
the API. The full documentation is here:
L<http://dev.betacie.com/viewtopic.php?id=6>.

=head1 METHODS

=head2 new

Creates a new WWW::VieDeMerde object.

Parameters are:

=over 4

=item * key

Your developper key. The defaults value ("readonly") is sufficient for
readonly functions. You can ask for a key here:
L<http://www.viedemerde.fr/api/developpeurs> or L<http://www.fmylife.com/api/developers>.

=item * token

The authentification to use an user account. See the API doc.

Not sure it will works.

=item * url

The URL of the API server. Do not change it, the defaults value ("api.betacie.com") is good enough.

=back

=cut

sub new {
    my $class  = shift;
    my %params = @_;

    my %defaults = (
        key => 'readonly',
        token => undef,
        url => 'http://api.betacie.com',
        autoerrors => 0,
        lang => 'fr',
        );

    my $self = {};
    bless($self, $class);

    for (keys %defaults) {
        if (exists $params{$_}) {
            $self->{$_} = $params{$_};
        }
        else {
            $self->{$_} = $defaults{$_};
        }
    }

    $self->{ua} = LWP::UserAgent->new();
    $self->{twig} = XML::Twig->new();

    return $self;
}

=head2 page

C<< $vdm->page() >> returns the last 15 entries.

C<< $vdm->page($n) >> the $n page (0 is the last one).

If the page you ask is empty, returns an empty list.

=cut

sub page {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'last', $page);

    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 last

C<< $vdm->last >> alias for C<< $vdm->page >>.

=cut

sub last {
    my $self = shift;

    return $self->page();
}

=head2 random

C<< $vdm->random() >> returns a random entry.

=cut

sub random {
    my $self = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'random');
    if (defined($xml)) {
        my @l = WWW::VieDeMerde::Message->parse($t);
        return $l[0];
    }
    return undef;
}

=head2 get

C<< $vdm->get($id) >> returns the item number $id.

=cut

sub get {
    my $self = shift;
    my $id = shift;
    my $t = $self->{twig};

    my $xml = $self->_run('view', $id, 'nocomment');
    if (defined($xml)) {
        my @l = WWW::VieDeMerde::Message->parse($t);
        return $l[0];
    }
    return undef;
}

=head2 comments

C<< $vdm->comments($id) >> returns the comments of the item $id.

=cut

sub comments {
    my $self = shift;
    my $id = shift;
    my $t = $self->{twig};

    my $xml = $self->_run('view', $id);
    if (defined($xml)) {
        my @l = WWW::VieDeMerde::Comment->parse($t);
        return @l;
    }
    return undef;
}


=head2 top

C<< $vdm->top() >> returns the 15 better ranked entries.

This function and all the top_* and flop_* functions accept a page
number as argument.

=cut

sub top {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'top', $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 top_day

C<< $vdm->top_day() >> returns the top of the day.

=cut

sub top_day {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'top_day', $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 top_jour

C<< $vdm->top_jour >> is an alias for C<< $vdm->top_day >>.

=cut

sub top_jour {
    my $self = shift;
    my $page = shift;

    return $self->top_day($page);
}


=head2 top_week

C<< $vdm->top_week() >> return the week top.

=cut

sub top_week {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'top_week', $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 top_semaine

C<< $vdm->top_semaine >> is an alias for C<< $vdm->top_week >>.

=cut

sub top_semaine {
    my $self = shift;
    my $page = shift;

    return $self->top_week($page);
}


=head2 top_month

C<< $vdm->top_month() >> returns the month top.

=cut

sub top_mois {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'top_mois', $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 top_mois

C<< $vdm->top_mois >> is an alias for C<< $vdm->top_month >>.

=cut

sub top_month {
    my $self = shift;
    my $page = shift;

    return $self->top_month($page);
}

=head2 flop

C<< $vdm->flop() >> returns the global top.

=cut

sub flop {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'flop', $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 flop_day

C<< $vdm->flop_day() >> returns day flop.

=cut

sub flop_day {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'flop_day', $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 flop_jour

C<< $vdm->flop_jour >> is an alias for C<< $vdm->top_day >>.

=cut

sub flop_jour {
    my $self = shift;
    my $page = shift;

    return $self->flop_day($page);
}

=head2 flop_week

C<< $vdm->flop_week() >> returns week flop.

=cut

sub flop_week {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'flop_week', $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 flop_semaine

C<< $vdm->flop_semaine >> is an alias for C<< $vdm->flop_semain >>.

=cut

sub flop_semaine {
    my $self = shift;
    my $page = shift;

    return $self->flop_week($page);
}

=head2 flop_month

C<< $vdm->flop_month() >> returns month flop.

=cut

sub flop_month {
    my $self = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'flop_month', $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 flop_mois

C<< $vdm->flop_mois >> is an alias for C<< $vdm->flop_month >>.

=cut

sub flop_mois {
    my $self = shift;
    my $page = shift;

    return $self->flop_month($page);
}

=head2 categories

C<< $vdm->categories($cat) >> returns a list for all categories.

=cut

sub categories {
    my $self = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', 'categories');
    warn 'WWW::VieDeMerde->categories gives raw xml';
    return $xml;
    # if (defined($xml)) {
    #     my @result = WWW::VieDeMerde::Message->parse($t);
    #     return @result;
    # }
    # return undef;
}

=head2 from_cat

C<< $vdm->from_cat($cat) >> returns entries of the category $cat.

=cut

sub from_cat {
    my $self = shift;
    my $cat = shift;
    my $page = shift;

    my $t = $self->{twig};

    my $xml = $self->_run('view', $cat, $page);
    if (defined($xml)) {
        my @result = WWW::VieDeMerde::Message->parse($t);
        return @result;
    }
    return undef;
}

=head2 errors

Read/write accessor for errors.

=cut

sub errors {
    my $self = shift;
    my $e = shift;
    if (defined $e) {
        $self->{errors} = $e;
        return;
    }
    else {
        return $self->{errors}
    }
}

=head1 INTERNAL METHODS AND FUNCTIONS


=head2 _run

Build the request by joining arguments with slashes.

=cut

sub _run {
    my $self = shift;
    my @commands = grep {defined $_} @_;

    my $token = $self->{token};
    my $key = $self->{key};
    my $url = $self->{url};
    my $lang = $self->{lang};

    my $ua = $self->{ua};
    my $t = $self->{twig};

    my $cmd = $url . '/' . join('/', @commands);
    my $args = '';
    if (defined $key) {
        $args .= '?key=' . $key;
    }
    if (defined $token) {
        $args .= '&token=' . $token;
    }
    if (defined $lang) {
        $args .= '&language=' . $lang;
    }

    my $response = $ua->get($cmd . $args);

    if ($response->is_success) {
        my $xml = $response->content;
        return undef if $self->_errors($xml) == 1;
        return $xml;
    }
    else {
        carp $response->status_line;
        $self->errors([$response->status_line]);
        return undef;
    }
}

=head2 _errors 

Detect errors in an xml fragment returned by _run.

=cut

sub _errors {
    my $self = shift;
    my $xml = shift;

    my $t = $self->{twig};

    if (defined($xml) and $t->safe_parse($xml)) {
        my $root = $t->root;

        my $errors = $root->first_child('errors');
        my @errors = map {$_->text} $errors->children('error');
        if (@errors) {
            map {carp($_)} @errors;
            $self->errors(\@errors);
            return 1;
        }
        
        my $items = $root->first_child('items');
        my @items = $items->children('item');
        if (! @items) {
            my $error = 'No item found';
            carp $error;
            $self->errors([$error]);
                return 2;
        }
        return 0;
    }
}

=head2 raw_xml

Outputs raw xml for the given commands.

=cut

sub raw_xml {
    my $self = shift;
    return $self->_run(@_);
}

=head1 AUTHOR

Olivier Schwander, C<< <olivier.schwander at ens-lyon.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-vdm at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-VieDeMerde>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

A darcs repository is available here :

L<http://chadok.info/darcs/WWW-VieDeMerde>

You can find documentation for this module with the perldoc command.

    perldoc WWW::VieDeMerde


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-VieDeMerde>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-VieDeMerde>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-VieDeMerde>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-VieDeMerde>

=back

=head1 SEE ALSO

L<WWW::FMyLife>

In early development, it seems to intend to support votes and comments
which is not my priority right now. Supports both French and English
version, despite the name.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Olivier Schwander, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::VieDeMerde
