package XML::Tidy::Tiny;
use 5.008001;
use strict;
use Exporter 'import';
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Tidy::Tiny ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    xml_tidy
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    xml_tidy
);
our $VERSION = '0.02';

sub xml_tidy{
    my $data = shift;
    my $header ='';
    $header  = $1 if $data=~s/^(<\?.*?\?>)\s*//s;
    $header .= "\n" if $header;

    my @data = grep length, split qr{(</?[^<>]+/?>)}, $data, -1;
    my @pre_push ;
    my @pre_number;
    my @pre_level;
    my $buff = '';
    my $level = 0;

    my $accum;

    while (@data) {
        my $item = shift @data;
        next unless length $item;

        my $type;
        if ( $item =~ m/^</ ) { # TAG 
            if ( $item =~ m/^<\// ) {    # TAG CLOSE
                $type = -1;
                my $indent;
                --$level;
                push @pre_push, $item;
                $pre_push[0]=~s/^\s+//;
                $buff .= $_ for "\n", '  ' x $level, @pre_push;
                @pre_push = ();
            }
            elsif ( $item =~ m/\/>\z/ ) { # TAG ALONE
                $type = 0;
                if (@pre_push) {
                    push @pre_push, $item;
                }
                else {
                    $pre_push[0]=~s/^\s+//;
                    $buff .= $_ for "\n", '  ' x $level, @pre_push, $item;
                    @pre_push = ();
                }
            }
            else {
                $type = 1;
                if (@pre_push) { # TAG OPEN
                    $pre_push[0]=~s/^\s+//;
                    $buff .= $_ for  "\n", '  ' x ( $level - 1 ), shift @pre_push;
                    ++$level;
                    if ( @pre_push ){
                        $pre_push[0]=~s/^\s+//;
                        $buff .= $_ for "\n", '  ' x ( $level - 1), @pre_push;
                    }
                    @pre_push = $item;
                }
                else {
                    ++$level;
                    push @pre_push, $item;
                }
            }
        }
        else {
            next if $item=~m/^\s+\z/;
            if (@pre_push) {
                push @pre_push, $item;
            }
            else {
                push @pre_push, $item;
                $pre_push[0]=~s/^\s+//;
                $buff .= $_ for "\n", '  ' x $level, @pre_push;
                @pre_push = ( );
            }
        }
    }
    if (@pre_push) {
        $buff .= "\n" if length $buff;
        $pre_push[0]=~s/^\s+//;
        $buff .= $_   for '  ' x ( $level ), @pre_push;
    }
    $buff=~s/^\s+//;
    $buff=~s/\s+\z//;
    return $header .  $buff;
}



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::Tidy::Tiny - Tiny XML tidy 

=head1 SYNOPSIS

  use XML::Tidy::Tiny; # or use XML::Tidy::Tiny qw(xml_tidy);

  print xml_tidy( $unformated_xml );

=head1 DESCRIPTION

This module allow very restrictive tidy of xml. And don't check validity of xml inputed.  

=head1 SEE ALSO

L<XML::Tidy>

=head1 AUTHOR

A. G. Grishayev, E<lt>grian@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by A. G. Grishayev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
