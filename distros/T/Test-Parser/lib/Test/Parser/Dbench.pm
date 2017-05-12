package Test::Parser::Dbench;

=head1 NAME

Test::Parser::Dbench - Perl module to parse output from Dbench

=head1 SYNOPSIS

    use Test::Parser::Dbench;
    my $parser = new Test::Parser::Dbench;
    $parser->parse($text)
    printf("     Clients: ", $parser->summary('clients'));
    printf("  Throughput: ", $parser->summary('throughput')); 

Additional information is available from the subroutines listed 
below
and from the L<Test::Parser> baseclass.

=head1 DESCRIPTION

This module provides a way to parse and neatly display 
information gained from the
Dbench test.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base 
class.

=cut

use strict;
use warnings;
use Test::Parser;

@Test::Parser::Dbench::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
    data
    );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Dbench instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments

=cut

sub new {
    my $class = shift;
    my Test::Parser::Dbench $self = fields::new($class);
    $self->SUPER::new();
    $self->testname('Dbench');
    $self->type('unit');
    $self->{data} = ();
    $self->{summary}= qq| dbench produces only the filesystem load. It does all the same IO
  calls that the smbd server in Samba would produce when confronted with
  a netbench run. It does no networking calls.|;
    $self->{license}=qq|GPL2|;
    $self->{vendor}= qq|   Copyright (C) by Andrew Tridgell 1999, 2001
   Copyright (C) 2001 by Martin Pool|;
    $self->{description}= qq| dbench is a filesystem benchmark that generates load patterns similar to those of the commercial Netbench benchmark, but without requiring a lab of Windows load generators to run. It is now considered a de-facto standard for generating load on the Linux VFS.|;
    $self->{url}=qq|tridge\@samba.org|;
    $self->platform('FIXME');

    return $self;
}

=head3 data()

Returns a hash representation of the Dbench data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {Dbench => {data => $self ->{data}}};
}

=head3

Override of Test::Parser's default parse_line() routine to make 
it able
to parse Dbench logs.

=cut

sub parse_line {   
    my $units;
    my $name;
    my $val1;
    my $val2;
    my $self = shift;
    my $line = shift;
    if( $line=~m/Throughput\s+(\d+\.\d+)\s(\D+\/\D+)\s(\d+) (\w{5})/){
        if ( ! defined $self->{'num-datum'} ){
            $self->add_column("Throughput",$2);
            $self->add_column("Processes",$4);
            $self->{'num-datum'} = 1;
        } else {
            $self->{'num-datum'} += 1;
        }
        $self->add_data($1, '1');
        $self->add_data($3, '2');
    }
    if( $line =~ m/.*version\s+(\d+\.\d+)\s-\s(.+)/){
        $self->{version}=$1;
        $self->{release}=$1;
        $self->{vendor}=$2;
    }
}

1;
__END__

=head1 AUTHOR

Joshua Jakabosky <jjakabosky@os...>

=head1 COPYRIGHT

Copyright (C) 2006 Joshua Jakabosky &amp; Open Source 
Development Labs, Inc.
All Rights Reserved.

This script is free software; you can redistribute it and/or 
modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end
