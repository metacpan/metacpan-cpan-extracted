package WWW::NioTV;
use Moose;
use version; our $VERSION = qv('0.04');

use WWW::Mechanize;
use HTML::TableExtract;
use HTML::SimpleLinkExtor;
use List::MoreUtils qw(any);
#use Smart::Comments;
#use Data::TreeDumper;

has 'content'  => ( is => 'rw', isa => 'Str'     );
has 'schedule' => ( is => 'rw', isa => 'HashRef' );
has 'mech'     => ( is => 'rw', isa => 'Ref'     );

my $url = 'http://www.niotv.com/i_index.php?cont=now';
my $url_prefix = 'http://www.niotv.com/';
my @ch_id = (46..50, 52, 53);
#my @ch_id = (46..50, 52, 53, 55..57, 141);

=head1 NAME

WWW::NioTV - retrieve TV information from http://www.niotv.com/

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

    use WWW::NioTV;

    my $tv = WWW::NioTV->new;
    $tv->now;
    $tv->next;

=head1 FUNCTIONS

=head2 new

create a WWW::NioTV object

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless \%args, $class;
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;

    # content
    my $mech = WWW::Mechanize->new;
    $mech->get($url);
    $self->content($mech->content);
    $self->mech($mech);

    # parse
    my $te = HTML::TableExtract->new;
    $te->parse($self->content);
    my @tables = $te->tables;
    my @rows = $tables[5]->rows; # 5 => movies
    shift @rows;
    my %schedule;
    foreach my $row (@rows) {
        my $channel   = $row->[0];
        my $now_name  = $row->[2];
        my $next_name = $row->[4];
        $now_name   =~ s/(^\s+|\s+$)//;
        $next_name  =~ s/(^\s+|\s+$)//;

        $schedule{$channel} = {
            now  => $now_name,
            next => $next_name,
        };
    }

    $self->schedule(\%schedule);
    return;
}

sub _find_link {
    my $self = shift;
    my $name = shift;
    my $extor = HTML::SimpleLinkExtor->new;
    $extor->parse($self->content);

    foreach my $link ($extor->links) {
        next unless any { $link =~ /ch_id=$_$/ } @ch_id;
        ### $link
        ### $name
        return "$url_prefix$link" if $link =~ /epg_name=$name/;
    }

    ### _find_link return
    return;
}

=head2 now

retrieve "now on" tv information

=cut

sub now { 
    my $self = shift;
    my %result = $self->_parse('now');
    return wantarray ? %result : \%result;
}

=head2 next

retrieve "next on" tv information

=cut

sub next { 
    my $self = shift;
    my %result = $self->_parse('next');
    return wantarray ? %result : \%result;
}

sub _parse {
    my $self = shift;
    my $type = shift; # now || next
    my $mech = $self->mech;
    my %result;
    foreach my $channel (keys %{$self->schedule}) {
        ### $channel
        my $name = (split /\s+/, $self->schedule->{$channel}->{$type})[0];
        ### _find_link
        my $url  = $self->_find_link($name);
        ### _parse_unit
        my %data = $self->_parse_unit($url);
        $result{$channel} = \%data;
    }
    return %result;
}

sub _parse_unit {
    my $self = shift;
    my $url  = shift;
    my $mech = $self->mech;
    ### get
    $mech->get($url);

    ### parse start
    my $te = HTML::TableExtract->new;
    $te->parse($mech->content);
    ### parse end
    my @tables = $te->tables;
    my $name    = $tables[1]->rows->[0]->[0];
    my $type    = $tables[1]->rows->[1]->[1];
    my $time    = $tables[1]->rows->[2]->[0];
    my ($english_name) = $name =~ /\(([^)]+)/;
    $time =~ s/(^\s+|\s+$)//g;
    $time =~ s/(?<=\))[^0-9]+/ /g;

    my %data = (
        name => $name,
        type => $type,
        time => $time,
        english_name => $english_name,
    );

    return %data;
}

=head1 AUTHOR

Alec Chen, C<< <alec at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-niotv at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-NioTV>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::NioTV

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-NioTV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-NioTV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-NioTV>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-NioTV>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alec Chen, all rights reserved. 

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of WWW::NioTV
