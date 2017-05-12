#
# This file is part of WWW-DaysOfWonder-Memoir44
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package WWW::DaysOfWonder::Memoir44::DB::Scenarios;
# ABSTRACT: scenarios database
$WWW::DaysOfWonder::Memoir44::DB::Scenarios::VERSION = '3.000';
use DateTime;
use MooseX::Singleton;
use MooseX::Has::Sugar;
use Path::Class;
use Storable qw{ nstore retrieve };

use WWW::DaysOfWonder::Memoir44::DB::Params;
use WWW::DaysOfWonder::Memoir44::Utils qw{ $DATADIR };


my $dbfile = $DATADIR->file( "scenarios.store" );

has scenarios => (
    rw, auto_deref,
    traits     => ['Array'],
    isa        => 'ArrayRef[WWW::DaysOfWonder::Memoir44::Scenario]',
    default    => sub { [] },
    writer     => '_set_scenarios',
    handles    => {
        nb_scenarios  => 'count',     # my $nb = $db->nb_scenarios;
        add           => 'push',      # $db->add( $scenario, $scenario );
        clear         => 'clear',     # $db->clear;
        grep          => 'grep',      # $db->grep( sub { $_->need_ef });
    }
);


 # -- public methods
  

# implemented by the 'Array' trait of the 'scenarios' attribute.



# implemented by the 'Array' trait of the 'scenarios' attribute.



sub read {
    my $self = shift;

    my $scenarios_ref = retrieve( $dbfile->stringify );
    $self->_set_scenarios( $scenarios_ref );
}



sub write {
    my $self = shift;
    my @scenarios = $self->scenarios;
    nstore( \@scenarios, $dbfile->stringify );

    # store timestamp
    my $params = WWW::DaysOfWonder::Memoir44::DB::Params->instance;
    my $today  = DateTime->today->ymd;
    $params->set( last_updated => $today );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DaysOfWonder::Memoir44::DB::Scenarios - scenarios database

=head1 VERSION

version 3.000

=head1 SYNOPSIS

    my $db = WWW::DaysOfWonder::Memoir44::DB::Scenarios->instance;
    $db->read;
    my @top_scenarios = $db->grep( sub { $_->rating == 3 } );
    $db->clear;
    $db->add( @top_scenarios );
    $db->write;

=head1 DESCRIPTION

This class implements a singleton holding all the scenarios available.
It is the core of the whole distribution.

=head1 METHODS

=head2 add

    my $db = WWW::DaysOfWonder::Memoir44::DB::Scenarios->instance;
    $db->add( @scenarios );

Store a new scenario in the scenarios database.

=head2 clear

    my $db = WWW::DaysOfWonder::Memoir44::DB::Scenarios->instance;
    $db->clear;

Remove all scenarios from the database.

=head2 read

    my $db = WWW::DaysOfWonder::Memoir44::DB::Scenarios->read;

Read the whole scenarios database from a file. The file is internal to
the distrib, and stored in a private directory.

=head2 write

    my $db = WWW::DaysOfWonder::Memoir44::DB::Scenarios->instance;
    $db->write;

Store the whole scenarios database to a file. The file is internal to
the distrib, and stored in a private directory.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
