package Text::Hyphen::GenderInclusive;
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

sub new {
    my ( $class, %args ) = @_;
    $class = ref $class || $class;
    my $base_class = delete $args{class};
    if ( !$base_class ) {
        croak "Missing class argument.";
    }
    eval "require $base_class" or croak $@;
    my $self;
    $self->{re} ||= delete( $args{re} ) || qr/[:*_]/;
    $self->{hyphenator} = $base_class->new(%args);
    bless $self, $class;
}

sub hyphenate {
    my ( $self, $word, $delim ) = @_;
    my $re = $self->{re};
    $word =~ s/(?<=\w)($re)(?=\w)//;
    my $char  = $1;
    my $pos   = $-[0];
    my @parts = $self->{hyphenator}->hyphenate($word);
    if ($char) {
        for my $part (@parts) {
            if ( length($part) < $pos ) {
                $pos -= length($part);
            }
            else {
                substr( $part, $pos, 0 ) = $char;
                last;
            }
        }
    }
    if ( defined($delim) ) {
        return join( $delim, @parts );
    }
    else {
        return wantarray ? @parts : join( '-', @parts );
    }
}

1;

__END__

=head1 NAME

Text::Hyphen::GenderInclusive - get hyphenation positions with inclusive gender markers

=head1 SYNOPSIS

This module handles words with inclusive gender markers.

    use Text::Hyphen::GenderInclusive;
    my $hyphenator = Text::Hyphen::GenderInclusive->new(class => 'Text::Hyphen::DE');
    print $hyphenator->hyphenate("Arbeiter*innen", '-');

See L<Text::Hyphen> for the interface documentation.

=head1 ATTRIBUTES

=over 4

=item class

Base class for hyphenation. This attribute is required.

=item re

Regexp that matches the gender markers. Defaults to I<[*:_]>.

=back

=head1 COPYRIGHT AND LICENSE 

Copyright 2019 Mario Domgoergen `<mario@domgoergen.com>`

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the   
Free Software Foundation, either version 3 of the License, or (at your  
option) any later version.                                              

This program is distributed in the hope that it will be useful,         
but WITHOUT ANY WARRANTY; without even the implied warranty of          
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       
General Public License for more details.                                

You should have received a copy of the GNU General Public License along 
with this program.  If not, see &lt;http://www.gnu.org/licenses/>.         
