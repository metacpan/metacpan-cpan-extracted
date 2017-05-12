package WWW::Yandex::BarTIC;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.05';

use base 'Object::Accessor';

use base 'Exporter';
our @EXPORT_OK = qw(get_tic);

use LWP::UserAgent;
use URI::Escape;
use Carp qw/carp croak/;

# Defaults
my $DEF_URL_TEMPLATE = 'http://bar-navig.yandex.ru/u?url=%s&show=1';
my $DEF_UA_AGENT     = 'Mozilla/5.0 (Ubuntu; X11; Linux i686; rv:9.0.1) Gecko/20100101 Firefox/9.0.1 YB/6.5.0-en';
my $TIC_RE           = qr#<tcy rang="\d+" value="(\d+)"/>#;
my @ATTRS            = qw/ua url_template/;

sub new {
  my ($class, %args) = @_;

  my $self = $class->SUPER::new(@ATTRS);
  $self->ua($args{ua} || LWP::UserAgent->new(agent => $DEF_UA_AGENT));
  $self->url_template($DEF_URL_TEMPLATE);

  return $self;
}


sub get {
  my ($self, $url) = @_;

  croak 'I am waiting for url param' unless defined $url;
  unless ($url =~ m[^https?://]i) {
    carp 'use "http://some.domain" format for url';
    return;
  }

  my $query = sprintf($self->url_template, uri_escape($url));
  my $resp = $self->ua->get($query);

  if ($resp->is_success and $resp->content =~ $TIC_RE) {
    return wantarray ? ($1, $resp) : $1;
  }
  else {
    return wantarray ? (undef, $resp) : undef;
  }

}

sub get_tic {
  my ($url) = @_;
  return __PACKAGE__->new()->get($url);
}


=head1 NAME

WWW::Yandex::BarTIC - Query Yandex citation index (Яндекс ТИЦ in russian)

=head1 VERSION

Version 0.04

=cut


=head1 SYNOPSIS

    use WWW::Yandex::BarTIC 'get_tic';
    
    # OO Style
    my $yb = WWW::Yandex::BarTIC->new();
    my ($tic, $resp) = $yb->get('http://cpan.org');
    
    # Function
    my ($tic, $resp) = get_tic('http://cpan.org');


=head1 DESCRIPTION


The C<WWW::Yandex::BarTIC> is a class implementing a interface for
querying yandex citation index.

It uses L<LWP::UserAgent> for making request to Yandex.

=head1 FUNCTIONS

=head2 C<get_tic>

You can use C<get_tic> function, but you must import it before
  
  use WWW::Yandex::BarTIC 'get_tic';
  my ($tic, $resp) = get_tic('http://mail.ru');
  
See L</"get"> method for description

=head1 METHODS

C<WWW::Yandex::BarTIC> implements the following methods.

=head2 C<new>

  my $yb = WWW::Yandex::BarTIC->new;
  my $yb = WWW::Yandex::BarTIC->new(ua => LWP::UserAgent->new);

Creates a new object. If C<ua> attribute is empty, it will be created automatically with following defaults:

   KEY                     DEFAULT
   -----------             --------------------
   agent                   "Mozilla/5.0 (Ubuntu; X11; Linux i686; rv:9.0.1) Gecko/20100101 Firefox/9.0.1 YB/6.5.0-en"


=head2 C<get>

  my ($tic, $resp) = $yb->get('http://cpan.org');
  my $tic = $yb->get('http://cpan.org');

Queries Yandex for a specified URL and returns TIC. If
query successfull, integer value > 0 returned. If query fails
for some reason (yandex unreachable, url does not begin from
'http://', undefined url passed) it returns C<undef>.

In list context this function returns list from two elements where
first is the result as in scalar context and the second is the
C<HTTP::Response> object (returned by C<LWP::UserAgent::get>). This
can be usefull for debugging purposes and for querying failure
details.


=head1 ATTRIBUTES

=head2 C<ua>

  $yb->ua(LWP::UserAgent->new);
  $yb->ua->agent('MyAgent');

Get/Set L<LWP::UserAgent> object for making request to Yandex

=head1 AUTHOR

Alex, C<< <alexbyk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-yandex-bartic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Yandex-BarTIC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Yandex::BarTIC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Yandex-BarTIC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Yandex-BarTIC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Yandex-BarTIC>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Yandex-BarTIC/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alex.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of WWW::Yandex::BarTIC
