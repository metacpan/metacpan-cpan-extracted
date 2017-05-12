package Test::Parser::Readprofile;

=head1 NAME

Test::Parser::Readprofile - Perl module to parse output from readprofile.

=head1 SYNOPSIS

 use Test::Parser::Readprofile;

 my $parser = new Test::Parser::Readprofile;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms readprofile output into a hash that can be used to
generate XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;

@Test::Parser::Readprofile::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              time_units
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Readprofile instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Readprofile $self = fields::new($class);
    $self->SUPER::new();

    $self->name('readprofile');
    $self->type('standards');

    #
    # Readprofile data in an array.
    #
    $self->{data} = [];

    return $self;
}

=head3 data()

Returns a hash representation of the readprofile data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {readprofile => {symbol => $self->{data}}};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse readprofile output.

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
    push @{$self->{data}}, {ticks => $i[0], name => $i[1], load => $i[2]}
            if (scalar @i == 3);

    return 1;
}

=head3 to_xml()

Returns readprofile data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    my $outfile = shift;
    return XMLout({symbol => $self->{data}}, RootName => 'readprofile');
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

