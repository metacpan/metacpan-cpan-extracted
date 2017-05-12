package Test::Parser::Vmstat;

=head1 NAME

Test::Parser::Vmstat - Perl module to parse output from vmstat.

=head1 SYNOPSIS

 use Test::Parser::Vmstat;

 my $parser = new Test::Parser::Vmstat;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms vmstat output into a hash that can be used to generate
XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;

@Test::Parser::Vmstat::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              time_units
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Vmstat instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Vmstat $self = fields::new($class);
    $self->SUPER::new();

    $self->name('vmstat');
    $self->type('standards');

    #
    # Vmstat data in an array.
    #
    $self->{data} = [];

    #
    # Used for plotting.
    #
    $self->{format} = 'png';
    $self->{outdir} = '.';
    $self->{time_units} = 'Minutes';

    return $self;
}

=head3 data()

Returns a hash representation of the vmstat data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {vmstat => {data => $self->{data}}};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse vmstat output.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    #
    # Trim any leading and trailing whitespaces.
    #
    $line =~ s/^\s+//;
    chomp($line);

    my @i = split / +/, $line;
    #
    # These should ignore any header lines.
    #
    return 1 if (scalar @i != 16);
    return 1 if ($i[0] eq 'r');
    #
    # Since the first row of data is garbage, set everything to 0.
    #
    my $count = scalar @{$self->{data}};
    @i = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            if ($count == 0);
    push @{$self->{data}}, {r => $i[0], b => $i[1], swpd => $i[2],
            free => $i[3], buff => $i[4], cache => $i[5], si => $i[6],
            so => $i[7], bi => $i[8], bo => $i[9],  in => $i[10], cs => $i[11],
            us => $i[12], sy => $i[13], idle => $i[14], wa => $i[15],
            elapsed_time => $count};

    return 1;
}

=head3 to_xml()

Returns vmstat data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    my $outfile = shift;
    return XMLout({data => $self->{data}}, RootName => 'vmstat');
}

1;
__END__

=head1 AUTHOR

Mark Wong <markwkm@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006-2008 Mark Wong & Open Source Development Labs, Inc.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

