# $Id: JASRAC.pm 1 2006-03-14 18:30:19Z daisuke $
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package WWW::JASRAC;
use strict;
use Encode qw(encode decode);
use HTML::TreeBuilder;
use LWP::UserAgent;
use WWW::JASRAC::Result;
our $VERSION;

BEGIN {
    $VERSION = '0.01'
}

use constant O_NAIGAI   => 'naigai';
use constant O_DOMESTIC => 'naikoku';
use constant O_INTL     => 'gaikoku';
use constant O_ZENPOU   => 'zenpou';
use constant O_BUBUN    => 'bubun';
use constant O_KOHO     => 'koho';
use constant O_KANZEN   => 'kanzen';
use constant DEFAULT_OE => 'euc-jp';
use constant DEFAULT_IE => 'euc-jp';

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = bless {
        ie => $args{ie} || DEFAULT_OE,
        oe => $args{oe} || DEFAULT_IE,
        ua => LWP::UserAgent->new,
        uri => $args{uri} || 'http://www2.jasrac.or.jp/cgi-bin/db2www/jwid040.d2w/report',
    }, $class;

    return $self;
}


sub search
{
    my $self = shift;
    my %args = @_;

    my $ie = $args{ie} || $self->{ie};
    my $oe = $args{oe} || $self->{oe};

    my $ua   = $self->{ua};
    my %form = (
        Naigai => 'naigai',
        Kensu  => 110,
        # 作品名
        L_SakJ => undef,
        K_SakJ => undef, # 前方／部分／後方／完全一致
        L_SakK => undef,
        K_SakK => undef, # 前方／部分／後方／完全一致
        # 権利者名
        L_KenJ => undef,
        K_KenJ => undef,
        L_KenK => undef,
        K_KenK => undef,
        # アーティスト名
        L_KasJ => undef,
        K_KasJ => undef,
        L_KasK => undef,
        K_KasK => undef,
        # 作品コード
        L_SakC => undef,
        K_SakC => undef,
    );

    if ($args{code}) {
        my $f = ref($args{code}) eq 'HASH' ?
            $args{code} : { text => $args{code} };
        $form{L_SakC} = $f->{text};
        $form{K_SakC} = $f->{option} || O_KANZEN;
    }

    if ($args{title}) {
        my $f = ref($args{title}) eq 'HASH' ?
            $args{title} : { text => $args{title} };
        $form{L_SakJ} = $f->{text};
        $form{K_SakJ} = $f->{option} || O_KANZEN;
    }

    if ($args{title_yomi}) {
        my $f = ref($args{title_yomi}) eq 'HASH' ?
            $args{title_yomi} : { text => $args{title_yomi} };
        $form{L_SakK} = $f->{text};
        $form{K_SakK} = $f->{option} || O_KANZEN;
    }

    if ($args{rights_holder}) {
        my $f = ref($args{rights_holder}) eq 'HASH' ?
            $args{rights_holder} : { text => $args{rights_holder} };
        $form{L_KenJ} = $f->{text};
        $form{K_KenJ} = $f->{option} || O_KANZEN;
    }

    if ($args{rights_holder_yomi}) {
        my $f = ref($args{rights_holder_yomi}) eq 'HASH' ?
            $args{rights_holder_yomi} : { text => $args{rights_holder_yomi} };
        $form{L_KenK} = $f->{text};
        $form{K_KenK} = $f->{option} || O_KANZEN;
    }

    if ($args{artist}) {
        my $f = ref($args{artist}) eq 'HASH' ?
            $args{artist} : { text => $args{artist} };
        $form{L_KasJ} = $f->{text};
        $form{K_KasJ} = $f->{option} || O_KANZEN;
    }

    if ($args{artist_yomi}) {
        my $f = ref($args{artist_yomi}) eq 'HASH' ?
            $args{artist_yomi} : { text => $args{artist_yomi} };
        $form{L_KasK} = $f->{text};
        $form{K_KasK} = $f->{option} || O_KANZEN;
    }

    foreach my $key (keys %form) {
        unless ($form{$key}) {
            delete $form{$key} ;
            next ;
        }
        $form{$key} = encode('sjis', decode($ie, $form{$key}));
    }

    my $response = $ua->post($self->{uri}, \%form);
    my $content  = $response->content;
    my $original_encoding;
    if ($response->header('Content-Type') =~ /charset=([\w-]+)/) {
        $original_encoding = $1;
    }
    $original_encoding ||= 'sjis';

    $content = encode($oe, decode($original_encoding, $content));

    if ($content =~ /該当するデータは存在しませんでした/) {
        return undef;
    }

    my @ret;
    my $tree = HTML::TreeBuilder->new_from_content($content);
    foreach my $row ($tree->look_down(_tag => 'tr')) {
        my @list = $row->content_list;
        next unless ref $list[0];
        next unless $list[0]->as_text =~ /^([\d-]+)<\d+>$/;

        my $title = ($list[1]->look_down(_tag => 'a'));
        push @ret, WWW::JASRAC::Result->new(
            code => $1,
            link => $title->attr('href'),
            text => encode($self->{oe}, decode('euc-jp', $title->as_text)),
            rights => [
                grep { length($_) && !/^\s+$/ }
                map { s/　/ /g; s/\s$//; s/^\s+//; s/\s+/ /g;
                    encode($self->{oe}, decode('euc-jp', $_)) }
                grep { !ref($_) }
                $list[2]->content_list ],
            artists => [
                grep { length($_) && !/^\s+$/ }
                map { s/　/ /g; s/\s$//; s/^\s+//; s/\s+/ /g; 
                    encode($self->{oe}, decode('euc-jp', $_)) }
                grep { !ref($_) }
                $list[3]->content_list ],
        );
    }
    $tree->delete;

    return wantarray ? @ret : \@ret;
}

1;

__END__

=head1 NAME

WWW::JASRAC - Interact With JASRAC Search Interface 

=head1 SYNOPSIS

  use WWW::JASRAC;
  my $jasrac  = WWW::JASRAC->new(ie => 'euc-jp');
  my @results = $jasrac->search(title => $SongTitle);

  foreach my $r (@results) {
     print $r->title, "\n";
  }

=head1 DESCRIPTION

BEWARE! EXTREMELY ALPHA SOFTWARE!

WWW::JASRAC is a module to query and extract data out of JASRAC
(Japanese Society for Rights of Authors, Composers and Publishers) site's
search capabilities.

=head1 METHOD

=head2 new %ARGS

Creates a new WWW::JASRAC instance. The following arguments are accepted:

=over 4

=item ie

The input (i.e. what YOU supply) encoding. Default is 'euc-jp'. 

=item oe

The output (i.e. what comes out of WWW::JASRAC) encoding. Default is 'euc-jp'

=back

=head2 search %ARGS

You can specify the following query criteria:

=over 4

=item code

The JASRAC code

=item title

The title of the song.

=item artist

The name of the artist.

=item rights_holder

the name of the rights holder (such as the writer or the publisher)

=back

Each of the criteria has a correspodngin "yomi" criteria as well. For example,
instead of specifying the song title, you may specify the "yomi" of the
title like so:

  $jasrac->search(title_yomi => $yomi);

Also, the value of each criteria may optionally be a hashref, so that you can
specify the search option, which are O_ZENPOU (prefix match), O_BUBUN
(partial match), O_KOHO (suffix match), and O_KANZEN (exact match). In this
case, use the 'text' slot in the hash to supply the actual query string:

  $jasrac->search(title => { text => $title, option => O_KANZEN });

If unspecified, the default for option is O_KANZEN

Returns a list of WWW::JASRAC::Result objects. 

=head1 SEE ALSO

L<WWW::JASRAC::Result|WWW::JASRAC::Result>

=head1 AUTHOR

Daisuke Maki E<lt>dmaki@cpan.orgE<gt>
All rights reserved.

=cut