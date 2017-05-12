package Test::Parser::Oprofile;

=head1 NAME

Test::Parser::Oprofile - Perl module to parse output from oprofile.

=head1 SYNOPSIS

 use Test::Parser::Oprofile;

 my $parser = new Test::Parser::Oprofile;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms oprofile output into a hash that can be used to
generate XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;

@Test::Parser::Oprofile::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              info
              time_units
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Oprofile instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Oprofile $self = fields::new($class);
    $self->SUPER::new();

    $self->name('oprofile');
    $self->type('standards');

    return $self;
}

=head3 data()

Returns a hash representation of the oprofile data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {oprofile => {symbol => $self->{data}, info => [$self->{info}]}};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse oprofile output.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    #
    # Drop anything that doesn't show symbols.
    #
    return 1 if ($line =~ /(no symbols)/);

    #
    # Trim any leading and trailing whitespaces.
    #
    $line =~ s/^\s+//;

    my @i = split / +/, $line;
    if (scalar @i == 4) {
        chomp($i[3]);
        push @{$self->{data}}, {samples => $i[0], percentage => $i[1],
                app_name => $i[2], name => $i[3]};
    } elsif ($i[0] ne 'samples') {
        $self->{info} .= $line;
    }

    return 1;
}

=head3 to_xml()

Returns oprofile data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    my $outfile = shift;
    return XMLout({symbol => $self->{data}, info => [$self->{info}]},
            RootName => 'oprofile');
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

