package WWW::Alexa::TrafficRank;

use strict;
use warnings;
use vars qw($VERSION);
use LWP::UserAgent;

$VERSION = '1.11';

sub new
{
    my $class = shift;
    my %par = @_;
    my $self;
  
    $self->{ua} = LWP::UserAgent->new(agent => $par{agent} || 'Opera 11.1') or return;
    $self->{ua}->proxy('http', $par{proxy}) if $par{proxy};
    $self->{ua}->timeout($par{timeout})     if $par{timeout};

    bless ($self, $class);
}

sub get 
{
    my ($self, $domain) = @_;

    return unless defined $domain;

    my $res = $self->{ua}->get("http://xml.alexa.com/data?cli=10&dat=nsa&url=$domain");
    return $res->status_line if !$res->is_success;

    my ($rank) = $res->content =~ /<POPULARITY URL=".+" TEXT="(\d+)"/i;

    return $rank;
}

1;

__END__

=head1 NAME

WWW::Alexa::TrafficRank - Query Alexa.com Traffic Rank of website.

=head1 SYNOPSIS

use WWW::Alexa::TrafficRank;
 
my $tr = WWW::Alexa::TrafficRank->new();
 
print $tr->get('filedir.com');

=head1 DESCRIPTION

The C<WWW::Alexa::TrafficRank> is a class implementing a interface for
querying Alexa.com Traffic Rank.

To use it, you should create C<WWW::Alexa::TrafficRank> object and use its
method get(), to query traffic rank of Domain.

It uses C<LWP::UserAgent> for making request to Alexa.com

=head1 CONSTRUCTOR METHOD

=over 4

=item  $tr = WWW::Alexa::TrafficRank->new(%options);

This method constructs a new C<WWW::Alexa::TrafficRank> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options correspond to attribute methods described below:

  KEY                     DEFAULT
  -----------             --------------------
  agent                   "Opera 10.0"
  proxy                   undef
  timeout                 undef

C<agent> specifies the header 'User-Agent' when querying Alexa. If
the C<proxy> option is passed in, requests will be made through
specified poxy. C<proxy> is the host which serve requests to Alexa.

=back

=head1 QUERY METHOD

=over 4

=item  $rank = $tr->get('filedir.com');

Queries Alexa for a specified traffic rank URL and returns traffic rank
text value. If query fails for some reason (Alexa unreachable, undefined 
url passed) it return error string.

=back

=head1 BUGS

If you find any, please report ;)

=head1 AUTHOR

FileDir
  F<E<lt>guruperl@cpan.orgE<gt>>.
  
=head1 COPYRIGHT

Copyright 2016, FileDir, All Rights Reserved.

You may use, modify, and distribute this package under the
same terms as Perl itself.