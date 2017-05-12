package Test::Parser::Mpstat;

=head1 NAME

Test::Parser::Mpstat - Perl module to parse output from mpstat.

=head1 SYNOPSIS

 use Test::Parser::Mpstat;

 my $parser = new Test::Parser::Mpstat;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms mpstat output into a hash that can be used to generate
XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;

@Test::Parser::Mpstat::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              time_units
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Mpstat instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Mpstat $self = fields::new($class);
    $self->SUPER::new();

    $self->name('mpstat');
    $self->type('standards');

    #
    # Mpstat data in an array.
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

Returns a hash representation of the mpstat data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {mpstat => {data => $self->{data}}};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse mpstat output.

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
    # These should ignore the first header line.
    #
    return 1 if (scalar @i != 11);
    return 1 if ($i[1] eq 'CPU');
    #
    # The first set of data doesn't appear to be garbage.
    #
    my $count = scalar @{$self->{data}};
    push @{$self->{data}}, {cpu => $i[1], user => $i[2], nice => $i[3],
            sys => $i[4], iowait => $i[5], irq => $i[6], soft => $i[6],
            steal => $i[7], idle => $i[8], intrs => $i[9],
            elapsed_time => $count};

    return 1;
}

=head3 to_xml()

Returns mpstat data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    my $outfile = shift;
    return XMLout({data => $self->{data}}, RootName => 'mpstat');
}

1;
__END__

=head1 AUTHOR

Mark Wong <markwkm@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2008 Mark Wong
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

