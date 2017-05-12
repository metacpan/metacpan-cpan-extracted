package WWW::RMDown;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use HTML::TagParser;
use autodie qw/open/;

our $VERSION = 0.01;

sub new
{
    my ($class, %cfg) = @_;
    my $ua = LWP::UserAgent->new (agent => 'Mozilla/5.0', %cfg);
    $ua->default_header ('Origin' => 'www.rmdown.com');

    bless { 
        'ua' => $ua
    }, $class;
}

sub fetch
{
    my ($self, $hash) = @_;
    my $ua   = $self->{ua};
    my %form = ();
    my $contents;
    my $sourceURL = 'http://www.rmdown.com/link.php?hash=' . $hash;

    my $html = HTML::TagParser->new ($sourceURL);
    $ua->default_header ('Referrer' => $sourceURL);

    foreach my $input ($html->getElementsByTagName('input'))
    {
        my $name  = $input->attributes->{'name'};
        my $value = $input->attributes->{'value'};

        $form{$name} = $value;
    }

    my $r = $ua->post ('http://www.rmdown.com/download.php', \%form);
    $contents = $r->decoded_content if ($r->is_success);
    
    return $contents;
}

1;

__END__

=head1 NAME

 WWW::RMDown - rmdown.com helper module

=head1 AUTHOR

 Aaron Lewis <the.warl0ck.1989@gmail.com> Copyright 2013
 Release under GPLv3 License

=head1 DESCRIPTION 

 This module fetch uploaded torrents from rmdown.com

=head1 SYNOPSIS

 use WWW::RMDown;

 my $rmdown = WWW::RMDown->new;
 open my $fh, '>x.torrent' or die $!;
 print $fh $rmdown->fetch ('1317d8779d833a0e604ef6ac23e74ce91402e237350');

=head2 new

 Create a new object and return,
 
 my $rmdown = WWW::RMDown->new;

=head2 fetch

 Fetch resource identified by hash id,

 my $contents = $rmdown->fetch ('1317d8779d833a0e604ef6ac23e74ce91402e237350');
