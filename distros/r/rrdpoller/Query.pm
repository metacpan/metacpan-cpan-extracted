package RRD::Query;

use strict;
use RRDs;
use Error qw(:try);

require Exporter;
@RRD::Query::ISA = qw(Exporter);
@RRD::Query::EXPORT_OK = qw(isNaN);

# $Id: Query.pm,v 1.15 2005/02/28 17:37:12 rs Exp $
$RRD::Query::VERSION = sprintf "%d.%03d", q$Revision: 1.15 $ =~ /(\d+)/g;

=pod

=head1 NAME

RRD::Query - Perform queries on RRD file

=head1 DESCRIPTION

Simple wrapper around RRDs library to do some simple queries. It
implemented more advanced error handling by using the Error module.

=head1 CONSTRUCTOR

    my $rq = new RRD::Query("/path/to/file.rrd");

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless({}, $class);
    $self->{file} = shift;
    return $self;
}

=pod

=head1 METHODS


=pod

=head2 list

    @datasources = list();

Return the list of all datasource of the given file

Throws:

Error::RRDs - on RRDs library error

=cut

sub list
{
    my($self) = @_;

    my $info = RRDs::info($self->{file});
    if(RRDs::error())
    {
        throw Error::RRDs("Can't get RRD info: " . RRDs::error());
    }

    my %ds;
    for my $key (keys %$info)
    {
        if(index($key, 'ds[') == 0)
        {
            $ds{substr($key, 3, index($key, ']') - 3)} = undef;
        }
    }

    return([sort keys %ds]);
}

=head2 fetch

    ($value) = fetch($ds, cf => $cf, offset => $offset)

Fetch a single value from the datasource $ds of RRD file. If $offset
is omitted, the last inserted value is returned, otherwise the last
value - $offset is returned. If $cf (consolidation function) is
omited, AVERAGE is used.

=head3 Options

=over 4

=item ds

Datasource you want to fetch. If the datasource contains comat (,),
your datasource will be interpreted as an RPN (Reverse Polish
Notation) expression (see L<Math::RPN>). If the C<Math::RPN> module
isn't loadable, an C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>.

=item cf

Consolidation function name you want to fetch. If omited, the AVERAGE
consolidation function is used.

=item offset

Time offset to go back in the past from the last inserted value time.

=back

=head3 Throws

=over 4

=item Error::RRDs

on RRDs library error

=item Error::RRD::NoSuchDS

if datasource can't be found in RRD file

=item Error::RPN::Feature

if you try to use an RPN DS without Math::RPN installed

=back

=cut

sub fetch
{
    my($self, $ds, %args) = @_;

    $args{offset} ||= 0;
    $args{cf}     ||= 'AVERAGE';

    # treat RPN DS (ie: ds1,ds2,-)
    if(index($ds, ',') != -1)
    {
        $self->_needs_rpn();
        my @rpn = split(/,/, $ds);
        my %ds;
        @ds{@{$self->list()}} = undef;
        for my $item (@rpn)
        {
            if(exists($ds{$item}))
            {
                # substitute variables by their value
                $item = $self->fetch($item, %args);
                if(isNaN($item))
                {
                    $item = 'NaN';
                }
            }
        }
        return(scalar Math::RPN::rpn(join(',', @rpn)));
    }

    # compute the time of the last value
    my $info = $self->info();
    my $rra_step = $info->{step} * $info->{'rra[0].pdp_per_row'};
    my $endtime = $info->{last_update} - ($info->{last_update} % $rra_step);

    my($start, $step, $names, $data) = RRDs::fetch
    (
     $self->{file},
     $args{cf},
     '--start' => 'end-'.$info->{step},
     '--end'   => $endtime.'-'.$args{offset},
    );
    if(RRDs::error())
    {
        throw Error::RRDs("Can't export data: " . RRDs::error(),
                          -object => 'RRDs');
    }

    # get DS id
    my $value;
    my $found = 0;
    for(my $i = 0; $i < @$names; $i++)
    {
        if($names->[$i] eq $ds)
        {
            $found = 1;
            $value = $data->[-1]->[$i];
            last;
        }
    }

    if(!$found)
    {
        throw Error::RRD::NoSuchDS("Can't find datasource in RRD: ".$ds);
    }

    return $value;
}

=pod

=head2 get_last

    $timestamp = get_last()

Returns the timestamp of the inserted value of the RRD file.

=head3 Throws

=over 4

=item Error::RRDs

on RRDs library error

=cut

sub last {get_last(@_)}
sub get_last
{
    my($self) = @_;

    return $self->info()->{last_update};
}

sub info
{
    my($self) = @_;

    my $mtime = (stat($self->{file}))[9];
    if(!defined $self->{info_ts} || $self->{info_ts} != $mtime)
    {
        $self->{info} = RRDs::info($self->{file});
        if(RRDs::error())
        {
            throw Error::RRDs("Can't get info: " . RRDs::error(),
                              -object => 'RRDs');
        }
        $self->{info_ts} = $mtime;
    }

    return $self->{info};
}

=pod

=head1 EXPORTS

=head2 isNaN

    $bool = isNaN($value);

Returns true if the value is Not a Number.

=cut

sub isNaN
{
    my($value) = @_;
    return !defined $value || $value eq 'NaN';
}

sub _needs_rpn
{
    try
    {
        require Math::RPN;
    }
    otherwise
    {
        throw Error::RRD::Feature("Can't load Math::RPN", -object => 'Math::RPN');
    };
}

=pod

=head1 EXCEPTION CLASSES

=head2 Error::RRDs

=cut

package Error::RRDs;

use base qw(Error::Simple);

=pod

=head2 Error::RRD::NoSuchDS

=cut

package Error::RRD::NoSuchDS;

use base qw(Error::Simple);

=pod

=head2 Error::RRD::isNaN

=cut

package Error::RRD::isNaN;

use base qw(Error::Simple);

=pod

=head2 Error::RRD::Feature

=cut

package Error::RRD::Feature;

use base qw(Error::Simple);

=pod

=head1 AUTHOR

Olivier Poitrey E<lt>rs@rhapsodyk.netE<gt>

=head1 LICENCE

RRD::Query, performs queries on RRD files.
Copyright (C) 2004 Olivier Poitrey

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 SEE ALSO

L<RRDs>, L<Error>

=cut

1;
