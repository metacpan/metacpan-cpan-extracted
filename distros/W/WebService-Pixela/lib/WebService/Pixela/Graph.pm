package WebService::Pixela::Graph;
use 5.010001;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = "0.01";

sub new {
    my ($class,$pixela_client) = @_;
    return bless +{
        client => $pixela_client,
    }, $class;
}


sub client {
    my $self = shift;
    return $self->{client};
}

sub id {
    my $self = shift;
    if (@_){
        $self->{id} = shift;
        return $self;
    }
    return $self->{id};
}

sub create {
    my ($self,%args) = @_;
    my $params = {};

    #check id
    $params->{id} = $args{id} // $self->id();
    croak 'require id' unless $params->{id};

    #check name unit
    map { $params->{$_} = $args{$_} // croak "require $_" } (qw/name unit/);

    # check type
    croak 'require type' unless $args{type};
    map {
            if ( $args{type} =~ /^$_$/i){
                $params->{type} = lc($args{type});
            }
    } (qw/int float/);

    croak 'invalid type' unless $params->{type};

    # check color
    croak 'require color' unless $args{color};
    $params->{color} = _color_validate($args{color});
    croak 'invalid color' unless $params->{color};

    #no check timezone...
    $params->{timezone} = $args{timezone} if $args{timezone};

    my $path = 'users/'.$self->client->username.'/graphs';
    $self->id($params->{id});
    return $self->client->request_with_xuser_in_header('POST',$path,$params);
}


sub get {
    my $self = shift;
    my $res  = $self->client->request_with_xuser_in_header('GET',('users/'.$self->client->username.'/graphs'));
    return $self->client->decode() ? $res->{graphs} : $res;
}


sub get_svg {
    my ($self, %args) = @_;
    my $id = $args{id} // $self->id;
    croak 'require graph id' unless $id;

    my $query = {};
    $query->{date} = $args{date} if $args{date};
    $query->{mode} = $args{mode} if $args{mode};

    my $path = 'users/'.$self->client->username.'/graphs/'.$id;

    return $self->client->query_request('GET',$path,$query);
}

sub update {
    my ($self,%arg) = @_;
    my $client = $self->client;

    my $id = $arg{id} // $self->id;
    croak 'require graph id' unless $id;

    my $params = {};
    map { $params->{$_} = $arg{$_} if $arg{$_} } (qw/name unit timezone/);

    #color invalid -> croak
    if ($arg{color}){
        $params->{color} = _color_validate($arg{color});
        croak 'invalid color' unless $params->{color};
    }

    if ($arg{purge_cache_urls}){
        if (ref($arg{purge_cache_urls}) ne 'ARRAY'){
            croak 'invalid types for purge_cache_urls';
        }
        $params->{purgeCacheURLs} = $arg{purge_cache_urls};
    }

    $params->{selfSufficient} = $arg{self_sufficient} if defined $arg{self_sufficient};

    return $client->request_with_xuser_in_header('PUT',('users/'.$client->username.'/graphs/'.$id),$params);
}

sub delete {
    my ($self,$id) = @_;
    my $client = $self->client;

    $id //= $self->id;
    croak 'require graph id' unless $id;

    return $client->request_with_xuser_in_header('DELETE',('users/'.$client->username.'/graphs/'.$id));
}

sub html {
    my ($self,$id) = @_;

    my $client = $self->client;

    $id //= $self->id;
    croak 'require graph id' unless $id;

    return $client->base_url . 'v1/users/'.$client->username.'/graphs/'.$id.'.html';
}

sub pixels {
    my ($self,%args) = @_;

    my $id  = $args{id} // $self->id;
    croak 'require id' unless $id;

    my $params = {};
    $params->{to}   = $args{to}   if $args{to};
    $params->{from} = $args{from} if $args{from};

    my $path = 'users/'.$self->client->username.'/graphs/'.$id.'/pixels';
    my $res  = $self->client->request_with_xuser_in_header('GET',$path,$params);

    return $self->client->decode() ? $res->{pixels} : $res;
}

sub _color_validate  {
    my $check_color = shift;
    map {
        if ($check_color  =~ /^$_$/i){
            return lc($check_color);
        }
    } (qw/shibafu momiji sora ichou ajisai kuro/);
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Pixela::Graph - It's Pixela Graph API client

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;

    use WebService::Pixela;

    # All WebService::Pixela methods use this token and user name in URI, JSON, etc.
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $graph  = $pixela->graph;

    $graph->id('thisisgraphid')->create(name => 'graphname', unit => 'test', 
        type => 'int', color => 'sora', timezone => 'Asis/Tokyo');


    my $graphs = $graph->get();
    print $graphs->[0]->{id};

    my $svg = $graphs->get_svg();

    $graphs->update(name => 'update_graph_name',...);

    # set html url
    my $url = $graphs->html();

    my $pixels = $graphs->pixels();

    # delete graph
    $graphs->delete();



=head1 DESCRIPTION

WebService::Pixela::Graph is user API client about L<Pixe.la|https://pixe.la> webservice.

=head1 INTERFACE

=head2 instance methods

This instance method require L<WebService::Pixela> instance.
So, Usually use these methods from the C<< WebService::Pixela >> instance.


=head4 C<< $pixela->graph->create(%opts) :$hash_ref >>

It is Pixe.la graph create.

I<%opts> might be:

=over

=item C<< [required (autoset)] id :  Str >>

It is an ID for identifying the pixelation graph.

If set in an instance of WebService::Pixela::Graph, use that value.

=item C<< [required] name :  Str >>

It is the name of the pixelation graph.

=item C<< [required] unit :  Str >>

It is a unit of the quantity recorded in the pixelation graph. Ex. commit, kilogram, calory.

=item C<< [required] type :  Str >>

It is the type of quantity to be handled in the graph. Only int or float are supported.

=item C<< [required] color : Str >>

Defines the display color of the pixel in the pixelation graph.
I<shibafu> (green), I<momiji> (red), I<sora> (blue), I<ichou> (yellow), I<ajisai> (purple) and I<kuro> (black) are supported as color kind.

=item C<< timezone : Str  >>

[optional] Specify the timezone for handling this graph as I<Asia/Tokyo>. 
If not specified, it is treated as I<UTC>.

=item C<< self_sufficient : Str  >>

[optional] If SVG graph with this field I<increment> or I<decrement> is referenced, Pixel of this graph itself will be incremented or decremented.
It is suitable when you want to record the PVs on a web page or site simultaneously.
The specification of increment or decrement is the same as Increment a Pixel and Decrement a Pixel with webhook.
If not specified, it is treated as I<none> .

=back

See Also L<https://docs.pixe.la/#/post-graph>

=head4 C<< $pixela->graph->get() >>

Get all predefined pixelation graph definitions.

If you setting I<$pixela->decode(1) [default]> return array refs.
Otherwise it returns json.

See Also L<https://docs.pixe.la/#/get-graph>

=head4 C<< $pixela->graph->get_svg(%args) >>

I<%opts> might be:

=over

=item C<< data :Str >>

[optional] If you specify it in yyyyMMdd format, will create a pixelation graph dating back to the past with that day as the start date.
If this parameter is not specified, the current date and time will be the start date.
(it is used C<<timezone>> setting if Graph’s C<<timezone>> is specified, if not specified, calculates it in C<<UTC>>)

=item C<< mode :Str >>

[optional] Specify the graph display mode.
As of October 23, 2018, support only short mode for displaying only about 90 days.

=back

See Also L<https://docs.pixe.la/#/get-svg>

=head4 C<< $pixela->graph->update(%args) >>

I<%options> might be C<< $pixela->graph->create() >> options.

See Also L<https://docs.pixe.la/#/put-graph>

=head4 C<< $pixela->graph->delete() >>

Delete the predefined pixelation graph definition.

See Also L<https://docs.pixe.la/#/delete-graph>

=head4 C<< $pixela->graph->html() >>

Displays the details of the graph in html format.
(This method return html urls)

See Also L<https://docs.pixe.la/#/get-graph-html>

=head4 C<< $pixela->graph->pixels(%args) >>

Get a Date list of Pixel registered in the graph specified by graphID.
You can specify a period with from and to parameters.

I<%args> might be

=over

=item C<< from :Str >>

[optional] Specify the start position of the period.

=item C<< to : Str >>

[optional] Specify the end position of the period.

=back

See Also L<https://docs.pixe.la/#/get-graph-pixels>


=head1 LICENSE

Copyright (C) Takahiro SHIMIZU.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takahiro SHIMIZU E<lt>anatofuz@gmail.comE<gt>

=cut

