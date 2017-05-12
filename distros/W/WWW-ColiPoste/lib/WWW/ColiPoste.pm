package WWW::ColiPoste;
use strict;
use warnings;
use Carp;
use File::Slurp;
use HTML::Entities;
use HTML::TreeBuilder;
use LWP::UserAgent;


{
    no strict "vars";
    $VERSION = '0.03';
}


=head1 NAME

WWW::ColiPoste - Fetch shipping status from ColiPoste

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use WWW::ColiPoste;

    my $coliposte = WWW::ColiPoste->new;
    my $status = $coliposte->get_status(tracking_id => $id);


=head1 DESCRIPTION

This module allows you to fetch the status of packages shipped by 
ColiPoste, the service from the French national postal service. 

Please note that this module works by web-scrapping, and doesn't 
do any transformation or parsing on the data apart from basic cleanup.
Especially, the dates and messages are as given by the web site, 
in French.

B<IMPORTANT:> Thanks to La Poste corporate thinking, this module is
no longer useful (since 2009), because they replaced the texts in the
result page with images (just in case their service was still usable).


=head1 METHODS

=head2 new()

Create a new objet.

=cut

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;
    $self->{agent} = LWP::UserAgent->new;

    return $self
}

=head2 get_status()

Fetch the tracking status of the given shipment ID. Returns the 
corresponding tracking data as an array reference with the following 
sub-structure:

    [
        {
            date    => STRING,
            site    => STRING,
            status  => STRING,
        },
        ...
    ]

B<Options>

=over

=item *

C<tracking_id> - I<(mandatory)> tracking ID of the package

=item *

C<from> - I<(optional)> source URI or file

=item *

C<using> - I<(optional)> use this LWP agent or code reference for 
fetching from the remote site

=back

B<Example>

    my $status = $coliposte->get_status(tracking_id => $id);

=cut

sub get_status {
    my ($self, %args) = @_;
    my $content;

    exists $args{tracking_id} or croak "error: required parameter: tracking_id";
    my $agent = $args{using};

    if (ref $args{from}) {
        my $src  = $args{from};
        my $type = ref $src;

        if    ($type eq "SCALAR") { $content = $$src }
        elsif ($type eq "ARRAY" ) { $content = join "", @$src }
        else { croak "error: don't know how to handle a \L$type reference" }
    }
    else {
        # construct the URL
        my $base_uri = $args{from}
            || "http://www.coliposte.net/particulier/suivi_particulier.jsp?colispart=%s";
        (my $url = $base_uri) =~ s/%s/$args{tracking_id}/;
    
        # fetch the content
        if (-f $url) {
            $content = read_file($url);
            $content =~ /Content-Type[^>]+charset=([^">]+)"[^>]*>/;
            my $encoding = $1 || "iso-8859-1";
            require Encode;
            $content = Encode::decode($encoding, $content);
        }
        elsif (ref $agent eq "CODE") {
            $content = $agent->($url)
        }
        elsif (ref $agent and eval { $agent->isa("LWP::UserAgent") }) {
            $content = $agent->get($url)->decoded_content;
        }
        else {
            $content = $self->{agent}->get($url)->decoded_content;
        }
    }

    my $tree = HTML::TreeBuilder->new_from_content($content);
    my $nbsp = decode_entities("&nbsp;");
    my @table;

    for my $table_node ($tree->look_down(_tag => "table", width => "100%")) {
        for my $tr_node ($table_node->look_down(_tag => "tr")) {
            my @row =
                grep { !/^\s*$/ }
                map { s/\( +/(/g; s/ +\)/)/g; $_ }
                map { s/[$nbsp[:blank:][:cntrl:]]+/ /g; s/^\s*|\s*$//g; $_ }
                map { $_->as_trimmed_text }
                $tr_node->look_down(_tag => qr/^t[dh]$/);
            push @table, \@row if @row;
        }
    }

    # remove the parts that don't interest us
    my $filter = join "|", "Entrez ici votre", "FAQ", "Guide du site";
    @table = grep { not $_->[0] =~ /$filter/ } @table;

    my @fields = qw(date status site);
    my @status = ();

    for my $line (reverse @table[2..$#table]) {
        push @status, { map { $fields[$_] => $line->[$_] } 0..$#fields }
    }

    return \@status
}


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>

=head1 BUGS

Please report any bugs or feature requests 
to C<bug-www-coliposte at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-ColiPoste>. 
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::ColiPoste

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-ColiPoste>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-ColiPoste>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-ColiPoste>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-ColiPoste>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1   # End of WWW::ColiPoste
