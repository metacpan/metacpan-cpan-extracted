package WebService::Google::Client::Discovery;
our $VERSION = '0.07';

# ABSTRACT: Methods for working with Google API discovery service


use Moo;
use Mojo::UserAgent;
use List::Util qw(uniq);
use Hash::Slice qw/slice/;
use Log::Log4perl::Shortcuts qw(:all);

use Data::Dumper;

has 'ua' => ( is => 'ro', default => sub { Mojo::UserAgent->new }, lazy => 1 );
has 'discovery_full' => ( is => 'ro', default => \&discover_all, lazy => 1 );


sub getRest {
    my ( $self, $params ) = @_;
    return $self->ua->get( 'https://www.googleapis.com/discovery/v1/apis/'
          . $params->{api} . '/'
          . $params->{version}
          . '/rest' )->result->json;
}


sub discover_all {
    shift->ua->get('https://www.googleapis.com/discovery/v1/apis')
      ->result->json;
}


sub availableAPIs {
    my $self = shift;
    my $all  = $self->discover_all()->{items};
    for my $i (@$all) {
        $i = {
            map { $_ => $i->{$_} }
            grep { exists $i->{$_} } qw/name version documentationLink/
        };
    }
    my @subset = uniq map { $_->{name} } @$all;    ## unique names
                                                   # warn scalar @$all;
                                                   # warn scalar @subset;
                                                   # warn Dumper \@subset;
          # my @a = map { $_->{name} } @$all;

    my @arr;
    for my $s (@subset) {
        my @v = map { $_->{version} } grep { $_->{name} eq $s } @$all;
        my @doclinks =
          uniq map { $_->{documentationLink} } grep { $_->{name} eq $s } @$all;

        # warn "Match! :".Dumper \@v;
        # my $versions = grep
        push @arr, { name => $s, versions => \@v, doclinks => \@doclinks };
    }

    return \@arr;

    # warn Dumper \@arr;

    # return \@a;
}


sub exists {
    my ( $self, $api ) = @_;
    my $apis_all = $self->availableAPIs();
    my $res = grep { $_->{name} eq $api } @$apis_all;
}


sub printSupported {
    my $self     = shift;
    my $apis_all = $self->availableAPIs();
    printf( "%-27s %-42s %s\n", 'SERVICE', 'VERSIONS', 'DOCUMENTATION' );
    for my $api (@$apis_all) {
        my $docs =
          @{ $api->{doclinks} }[0]
          ? join( ', ', @{ $api->{doclinks} } )
          : 'unavailable';
        printf( "%-27s %-42s %s\n",
            $api->{name}, join( ', ', @{ $api->{versions} } ), $docs, );
    }
}


sub availableVersions {
    my ( $self, $api ) = @_;
    my $apis_all = $self->availableAPIs();
    my @api_target = grep { $_->{name} eq $api } @$apis_all;
    return $api_target[0]->{versions};
}


sub latestStableVersion {
    my ( $self, $api ) = @_;
    my $versions = $self->availableVersions($api);    # arrayref
    if ( $versions->[-1] =~ /beta/ ) {
        return $versions->[0];
    }
    else {
        return $versions->[-1];
    }
}


sub findAPIsWithDiffVers {
    my $self = shift;
    my $all  = $self->availableAPIs();
    grep { scalar @{ $_->{versions} } > 1 } @$all;
}


sub searchInServices {
    my ( $self, $string ) = @_;

    # warn Dumper $self->availableAPIs();
    my @res = grep { $_->{name} eq lc $string } @{ $self->availableAPIs };

    # warn "Result: ".Dumper \@res;
    return $res[0];
}


sub getMethodMeta {
    my ( $self, $caller ) = @_;

    # $caller = 'WebService::Google::Client::Calendar::CalendarList::delete';
    my @a = split( /::/, $caller );

    # warn Dumper \@a;
    my $method   = pop @a;            # delete
    my $resource = lcfirst pop @a;    # CalendarList
    my $service  = lc pop @a;         # Calendar
    my $service_data =
      $self->searchInServices($service);    # was string, become hash

    #    warn "getResourcesMeta:service_data : " . Dumper $service_data
    #      if ( $self->debug );

    my $all = $self->getRest(
        {
            api     => $service_data->{name},
            version => $service_data->{versions}[0]
        }
    );
    my $baseUrl = $all->{baseUrl};
    my $resource_data =
      $all->{resources}{$resource};    # return just a list of all methods
    my $method_data = $resource_data->{methods}{$method};    # need httpMethod
    $method_data->{path} = $baseUrl . $method_data->{path};
    my $res = slice $method_data, qw/httpMethod path id/;
}


sub getResourceMeta {
    my ( $self, $package ) = @_;

    # $package = 'WebService::Google::Client::Calendar::Events';
    my @a        = split( /::/, $package );
    my $resource = lcfirst pop @a;            # CalendarList
    my $service  = lc pop @a;                 # Calendar
    my $service_data =
      $self->searchInServices($service);      # was string, become hash
    my $all = $self->getRest(
        {
            api     => $service_data->{name},
            version => $service_data->{versions}[0]
        }
    );
    return $all->{resources}{$resource};    # return just a list of all methods
}


sub listOfMethods {
    my ( $self, $package ) = @_;
    my $r = $self->getResourceMeta($package);
    my @a = keys %{ $r->{methods} };
    return \@a;
}


sub metaForAPI {
    my ( $self, $params ) = @_;
    my $full = $self->discovery_full;
    my @a;

    if ( defined $params->{api} ) {
        @a = grep { $_->{name} eq $params->{api} } @{ $full->{items} };
    }
    else {
        die "metaForAPI() : No api specified!";
    }

    if ( defined $params->{version} ) {
        @a = grep { $_->{version} eq $params->{version} } @a;
    }

    return $a[0];
}

1;

__END__

=pod

=head1 NAME

WebService::Google::Client::Discovery - Methods for working with Google API discovery service

=head1 VERSION

version 0.07

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
