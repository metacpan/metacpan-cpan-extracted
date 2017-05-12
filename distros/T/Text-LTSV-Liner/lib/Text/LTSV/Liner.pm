package Text::LTSV::Liner;

use strict;
use warnings;

use Term::ANSIColor;

our $VERSION = "0.03";

sub new {
    my $class = shift;
    my %args  = @_;
    unless ( $args{key} ) {
        $args{all} = 1;
    }
    bless \%args, $class;
}

sub run {
    my $self = shift;
    my $line = shift;
    chomp($line);
    print $self->parse($line) . "\n";
}

sub parse {
    my $self = shift;
    my $line = shift;

    my %wants;
    if ( $self->{key} ) {
        %wants = map { $_ => 1 } @{ $self->{key} };
    }

    my %stash;
    my @original;
    for my $kv ( map { [ split( /:/, $_, 2 ) ] } split( /\t/, $line ) ) {
        next if ( not $self->{all} and not $wants{ $kv->[0] } );
        $stash{ $kv->[0] } = $kv->[1];
        push( @original, $kv->[0] );
    }

    my @out;
    my @ordered = $self->{key} ? @{ $self->{key} } : @original;
    for my $_key (@ordered) {
        my ( $key, $value ) = ( $_key, $stash{$_key} || q{} );
        if ( not $self->{'no-color'} ) {
            $key   = color('green') . $key . color('reset');
            $value = color('magenta') . $value . color('reset');
        }
        if ($self->{'no-key'}) {
            push(@out, $value);
        } else {
            push(@out, join(q{:}, $key, $value));
        }
    }

    return join( "\t", @out );
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::LTSV::Liner - Line filter of LTSV text

=head1 SYNOPSIS

    use Text::LTSV::Liner;
    my $liner = Text::LTSV::Liner->new( key => \@keys );
    while(<>) {
        $liner->run($_);
    }

=head1 DESCRIPTION

Labeled Tab-separated Values (LTSV) format is a variant of Tab-separated
Values (TSV). (cf: L<http://ltsv.org/>)
This module simply filters text whose format is LTSV by specified keys.

=head1 METHODS

=head2 new

Constructor.
You can specify some options to filter lines.

=over 4

=item B<key>

You can choose keys as array reference which you want to see in filtered output.

=item B<no-color>

If you prefer no-colorized output, specify this option.

=item B<no-key>

If you don't need to see keys in the output, specify this option.
Then you'll see values only in the output.

=back

=head2 run

Process lines and print output to STDOUT.

=head2 parse

    my $liner = Text::LTSV::Liner->new( key => \@keys );
    for my $line (@lines) {
        my $parsed = $liner->parse($line);
    }

This method is convinent if you want to use the filtered output in your codes.

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2013 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

