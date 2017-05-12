package Test::Parser::Iostat;

=head1 NAME

Test::Parser::Iostat - Perl module to parse output from iostat (iostat -x).

=head1 SYNOPSIS

 use Test::Parser::Iostat;

 my $parser = new Test::Parser::Iostat;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms iostat output into a hash that can be used to generate
XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;

@Test::Parser::Iostat::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              device
              data
              elapsed_time
              info
              time_units
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Iostat instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Iostat $self = fields::new($class);
    $self->SUPER::new();

    $self->name('iostat');
    $self->type('standards');

    #
    # Iostat data in an array and other supporting information.
    #
    $self->{data} = [];
    $self->{info} = '';
    #
    # Start at -1 because the first increment to the value will set it to 0
    # for the first set of data.
    #
    $self->{elapsed_time} = -1;

    #
    # Used for plotting.
    #
    $self->{format} = 'png';
    $self->{outdir} = '.';
    $self->{time_units} = 'Minutes';

    return $self;
}

=head3 data()

Returns a hash representation of the iostat data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {iostat => {data => $self->{data}}};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse iostat output.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    #
    # Trim any leading and trailing whitespaces.
    #
    chomp($line);
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    my @i = split / +/, $line;
    my $count = scalar @i;
    if ($count == 12) {
        #
        # This is either the iostat headers or the data.  If it's a header
        # skip to the next line and increment the counter.
        #
        if ($i[0] eq "Device:") {
            #
            # We've gone through 1 iteration of data, increment the counter.
            #
            ++$self->{elapsed_time};
            return 1;
        }
    } elsif ($count == 1) {
        #
        # This just read the device name.  The data will be on the next line.
        #
        $self->{device} = $line;
        return 1;
    } elsif ($count == 11) {
        #
        # Put $self->{device} in front of @i
        #
        unshift @i, $self->{device};
    } elsif ($count == 4) {
        #
        # This should be information about the OS and the date.
        #
        $self->{info} = $line;
        return 1;
    } else {
        #
        # Skip empty lines.
        #
        return 1;
    }
    #
    # If $self->{elapsed_time} == 0 then zero the data out since it's bogus.
    #
    @i = ($i[0], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            if ($self->{elapsed_time} == 0);
    push @{$self->{data}}, {device => $i[0], rrqm => $i[1], wrqm => $i[2],
            r => $i[3], w => $i[4], rmb => $i[5], wmb => $i[6], avgrq => $i[7],
            avgqu => $i[8], await => $i[9], svctm => $i[10], util => $i[11],
            elapsed_time => $self->{elapsed_time}};

    return 1;
}

=head3 to_xml()

Returns iostat data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    my $outfile = shift;
    return XMLout({data => $self->{data}}, RootName => 'iostat');
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

