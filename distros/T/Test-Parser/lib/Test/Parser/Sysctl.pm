package Test::Parser::Sysctl;

=head1 NAME

Test::Parser::Sysctl - Perl module to parse output from sysctl.

=head1 SYNOPSIS

 use Test::Parser::Sysctl;

 my $parser = new Test::Parser::Sysctl;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms sysctl output into a hash that can be used to
generate XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;

@Test::Parser::Sysctl::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Sysctl instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Sysctl $self = fields::new($class);
    $self->SUPER::new();

    $self->name('sysctl');
    $self->type('standards');

    #
    # Sysctl data in an array.
    #
    $self->{data} = [];

    return $self;
}

=head3 data()

Returns a hash representation of the sysctl data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {parameters => {parameter => $self->{data}}};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse sysctl output.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    my @i = split /\=/, $line;
    #
    # Trim any leading and trailing whitespaces.
    #
    $i[0] =~ s/^\s+//;
    $i[0] =~ s/\s+$//;
    $i[1] =~ s/^\s+//;
    $i[1] =~ s/\s+$//;
    push @{$self->{data}}, {variable => $i[0], value => $i[1]};

    return 1;
}

=head3 to_xml()

Returns sysctl data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    my $outfile = shift;
    return XMLout({parameter => $self->{data}}, RootName => 'parameters');
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

