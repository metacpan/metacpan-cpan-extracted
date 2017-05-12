package WWW::AtMovies::TV;
use Moose;
use WWW::Mechanize;
use HTML::TableExtract;
#use Smart::Comments;

=head1 NAME

WWW::AtMovies::TV - retrieve TV information from http://www.atmovies.com.tw/

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';
my $base_url = 'http://tv.atmovies.com.tw/tv/attv.cfm?action=showtime&groupid=M';

has 'content' => ( is => 'rw', isa => 'Str'     );
has 'mech'    => ( is => 'rw', isa => 'Ref'     );
has 'data'    => ( is => 'rw', isa => 'HashRef' );

=head1 SYNOPSIS

    use WWW::AtMovies::TV;

    my $foo = WWW::AtMovies::TV->new();
    $foo->now;
    $foo->next;

=head1 FUNCTIONS

=head2 new

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless \%args, $class;
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;
    my $mech = WWW::Mechanize->new;
    $mech->get($base_url);
    $self->content($mech->content);

    # top
    my @links = grep { $_->url_abs =~ /tvdata/ } $mech->links;
    ### @links

    my (%ch_name, %data);
    foreach my $ch_id (56..58, 60..62) {
	### $ch_id
        my $ch_name = $mech->find_link( url_regex => qr/$ch_id$/ )->text;
        $ch_name{"CH$ch_id"} = $ch_name;
    }

    foreach my $index (0..@links-1) {
        my $link = $links[$index];
        my $type = $index % 2 ? 'next' : 'now';

        # tv page
        my $url  = $link->url_abs;
        my $name = $link->text;
        my ($ch_id) = $url =~ /channelid=(\w+)/;
        my $ch_name = $ch_name{$ch_id};
        $mech->get($url);

        my $te = HTML::TableExtract->new;
        $te->parse($mech->content);
        my @tables = $te->tables;
        my ($date, $time) = split q{ }, $tables[1]->rows->[1]->[0];

	### info
        my %info = (
            name => $name,
            date => $date,
            time => $time,
            ch_name => $ch_name,
            ch_id   => $ch_id,
        );
	### %info

        ### film page
	if ($mech->content =~ /filmdata/) {
	    $mech->follow_link( url_regex => qr/filmdata/ );
	    my ($imdb_url) = grep { $_ =~ /imdb/ } 
			     map { $_->url_abs } $mech->links;

	    if (defined $imdb_url) {
		my ($imdb_id) = $imdb_url =~ /(\d+)$/;
		$info{imdb_id} = $imdb_id;
	    }
	}

        $data{$type}->{$ch_name} = \%info;
    }
    $self->data(\%data);
    return;
}

=head2 now

retrieve "now on" information

=cut

sub now { 
    my $self = shift;
    my $return = $self->data->{now};
    return wantarray ? %{$return} : $return;
}

=head2 next

retrieve "next on" information

=cut

sub next { 
    my $self = shift;
    my $return = $self->data->{next};
    return wantarray ? %{$return} : $return;
}

=head1 AUTHOR

Alec Chen, C<< <alec at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-atmovies-tv at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-AtMovies-TV>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::AtMovies::TV


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-AtMovies-TV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-AtMovies-TV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-AtMovies-TV>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-AtMovies-TV>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alec Chen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of WWW::AtMovies::TV
