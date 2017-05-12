package Web::MicroID;

use 5.008008;
use strict;
use warnings;
use Carp;
use Digest::SHA1;
use Digest::MD5;

our $VERSION = '0.02';

=pod

=head1 NAME

Web::MicroID - An implementation of the MicroID standard

=head1 VERSION

This documentation refers to Web::MicroID version 0.02

=head1 SYNOPSIS

    use Web::MicroID;

    $id = Web::MicroID->new();

    $id->individual('mailto:user@domain.tld');
    $id->serv_prov('http://domain.tld/'); 

=cut

sub individual {
    my $self = shift;
    my $id   = shift;

    if ($id) {
        croak 'individual() not in the correct format' unless $id =~/:/;

        # Set ID, split it into parts and set them too
        $self->[0]->{individual} = $id;
        (
            $self->[0]->{indv_uri}, $self->[0]->{indv_val}
        ) = split /\:\/*/, $id;
    }

    # Get any ID we may have
    return $self->[0]->{individual};
}
sub indv_uri {
    my $self = shift;

    # Get the URI of any ID we may have
    return $self->[0]->{indv_uri};
}
sub indv_val {
    my $self = shift;

    # Get the URI value of any ID we may have
    return $self->[0]->{indv_val};
}
sub serv_prov {
    my $self = shift;
    my $id   = shift;

    if ($id) {
        croak 'serv_prov() not in the correct format' unless $id =~/:/;
        
        # Set ID, split it into parts and set them too
        $self->[0]->{serv_prov} = $id;
        (
            $self->[0]->{serv_prov_uri}, $self->[0]->{serv_prov_val}
        ) = split /\:\/*/, $id;
        $self->[0]->{serv_prov_val} =~ s/\/$//;
    }

    # Get any ID we may have
    return $self->[0]->{serv_prov};
}
sub serv_prov_uri {
    my $self = shift;

    # Get the URI of any ID we may have
    return $self->[0]->{serv_prov_uri};
}
sub serv_prov_val {
    my $self = shift;

    # Get the URI value of any ID we may have
    return $self->[0]->{serv_prov_val};
}
sub algorithm {
    my $self = shift;
    my $id   = shift;

    # Change the algorithm if a new one is provided
    $self->[0]->{algorithm} = $id || 'sha1';

    # Get the alogorithm we're using
    return $self->[0]->{algorithm};
}

=pod

    # Generate a MicroID token
    $micro_id = $id->generate();

=cut

sub generate {
    my $self = shift;
    my $id   = $self->[0];

    # Check state
    croak 'Must set individual() before calling generate()' 
        unless $id->{individual};
    croak 'Must set serv_prov() before calling generate()'
        unless $id->{serv_prov};
    individual($self, $id->{individual}) unless $id->{indv_uri};
    serv_prov($self,  $id->{serv_prov})  unless $id->{serv_prov_uri};
    algorithm($self)                     unless $id->{algorithm};

    # Call the correct algorithm constructor 
    my $algor;
    if ($id->{algorithm} eq 'md5')  {$algor = Digest::MD5->new}
    else {$algor = Digest::SHA1->new}

    # Hash the ID's
    my $indv = $algor->add($id->{individual})->hexdigest;
    $algor->reset;
    my $serv = $algor->add($id->{serv_prov} )->hexdigest;
    $algor->reset;

    # Hash the ID's together and set as the legacy MicroID token
    $self->[0]->{legacy} = $algor->add($indv . $serv)->hexdigest;

    # Assemble the MicroID token and set it
    my $micro_id = join ':', (
        $id->{indv_uri} . '+' . $id->{serv_prov_uri},
        $id->{algorithm},
        $self->[0]->{legacy}
    );
    $self->[0]->{micro_id} = $micro_id;

    # Get the MicroID token
    return $micro_id;
}
sub legacy {
    my $self = shift;

    # Get any legacy MicroID token
    return $self->[0]->{legacy};
}

=pod

    # Process (validate) a MicroID token
    $test = $id->process($micro_id);

=cut

sub process {
    my $self   = shift;
    my $process = shift || $self->[0]->{process};

    croak 'Must set process() before calling process()' unless $process;

    my @verify = split /:/, $process;
    generate($self); 
    return 1 if pop @verify eq $self->[0]->{legacy};
    return;
}
sub new {
    my $class = shift;
    my $conf  = shift || {};
    my $self  = bless [$conf], $class;
    return $self;
}

__END__


=pod

=head1 DESCRIPTION

This module is used to generate or process a MicroID token.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<http://microid.org/>

=head1 METHODS

=over 4

=item new()

The new() constructor doesn't require any arguments.

    $id = Web::MicroID->new();

You can optionally set the value of one or all these methods.

    $id = Web::MicroID->new(
        {
            algorithm  => $algorithm
            individual => $individual,
            serv_prov  => $serv_prov,
            process    => $process,
        }
    );

=item individual()

Will set or get the value for an individual's ID.

    $individual = 'mailto:user@domain.tld';
    $id->individual($individual);

or 
 
    $individual = $id->individual();

=item indv_uri()

Will get the URI type of the individual's ID (e.g., 'mailto').

=item indv_val()

Will get the URI value for the individual's URI (e.g., 'user@domain.tld').

=item serv_prov()

Will set or get the value for the service provider's ID.

    $serv_prov = 'http://domain.tld/';
    $id->serv_prov($serv_prov);

or 
 
    $serv_prov = $id->serv_prov();

=item serv_prov_uri()

Will get the URI type for the service provider's ID (e.g., 'http').

=item serv_prov_val()

Will get the URI value of the service provider's ID (e.g., 'domain.tld').

=item algorithm()

Will set or get the algorithm method.
Either (md5 or sha1), defaults to 'sha1'.

    $algorithm = 'md5';
    $id->algorithm($algorithm);

or 
 
    $algorithm = $id->algorithm();

=item generate()

Generate a MicroID token

    $micro_id = $id->generate();

=item legacy()

Well get the hash portion of the MicroID token.

    $legacy = id->legacy();

=item process()

Sets and processes (validates) a MicroID token.
Works with both conforming and legacy MicroID specs.
Returns true if successful, undefined on failure.

    $test = $id->process(
        'mailto+http:sha1:7964877442b3dd0b5b7487eabe264aa7d31f463c';
    );

or 
 
    $test = $id->process();

=back

=head1 DEPENDENCIES

Digest::SHA1
Digest::MD5

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to the author.

Patches are welcome.

=head1 AUTHOR

Jim Walker, E<lt>jim@reclaw.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Jim Walker, E<lt>jim@reclaw.comE<gt>
All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;

