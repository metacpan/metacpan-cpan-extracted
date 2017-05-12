package Test::Parser::PgOptions;

=head1 NAME

Test::Parser::PgOptions - Perl module to parse output from pgoption.

=head1 SYNOPSIS

 use Test::Parser::PgOptions;

 my $parser = new Test::Parser::PgOptions;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms pgoption output into a hash that can be used to
generate XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;

@Test::Parser::PgOptions::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::PgOptions instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::PgOptions $self = fields::new($class);
    $self->SUPER::new();

    $self->name('pgoption');
    $self->type('standards');

    #
    # PgOptions data in an array.
    #
    $self->{data} = [];

    return $self;
}

=head3 data()

Returns a hash representation of the pgoption data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {database => {name => 'PostgreSQL', version => $self->{version},
            parameters => {parameter => $self->{data}}}};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse pgoption output.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

	my @i = split /\|/, $line;
	if (scalar @i == 3 and $i[0] ne 'name') {
        #
        # Trim any leading and trailing whitespaces.
        #
        $i[0] =~ s/^\s+//;
        $i[0] =~ s/\s+$//;
        return 1 if ($i[0] eq 'name');
        $i[1] =~ s/^\s+//;
        $i[1] =~ s/\s+$//;
        $i[2] =~ s/^\s+//;
        $i[2] =~ s/\s+$//;
        push @{$self->{data}}, {name => $i[0], setting => $i[1],
                description => $i[2]};
        $self->{version} = $i[1] if ($i[0] eq 'server_version');
    }

    return 1;
}

=head3 to_xml()

Returns pgoption data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    my $outfile = shift;
    return XMLout({name => 'PostgreSQL', version => $self->{version},
            parameters => {parameter => $self->{data}}},
            RootName => 'database');
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

