package Text::Livedoor::Wiki::Plugin::Block::Table;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);


sub check {
    my $self    = shift;
    my $line    = shift;
    my $args    = shift;
    my $id      = $args->{id};
    my $on_next = $args->{on_next};

    my $row     = '';
    if ( ($row) = $line =~ /^\|(.*)(\||\|\s)$/ ) {
        unless ($on_next) {
            $row =~ s/\|$/\| /;
            $row =~ s/\|\|/\| \|/;
            $row =~ s/\|\|/\| \|/;
        }
        my @rows = split( /\|/, $row , -1);
        return { id => $id , rows => \@rows };

    }
    elsif ( ($row) = $line =~ /^,(.*)(,|,\s)$/ ) {
        unless ($on_next) {
            $row =~ s/,$/, /;
            $row =~ s/,,/, ,/;
            $row =~ s/,,/, ,/;
        }
        my @rows = split( ',', $row , -1);
        return { id => $id , rows => \@rows };
    }

    return;

}

#{{{ get 
sub get {
    my $self = shift;
    my $block = shift;
    my $inline = shift;
    my $items  = shift;
    my $id   = $items->[0]{id};
    my $rows = $self->trs($items);
    my $data = '';
    for my $row  ( @$rows ) {
        $data .= "<tr>\n";
        for my $col (@$row) {
            $data .= qq|<$col->{tag}|;
            for ( qw/colspan rowspan/ ) {
                $data .= qq| $_="$col->{$_}"| if $col->{$_} && $col->{$_} > 1;
            }

            my $style = '';
            for my $option ( @{$col->{options}} ) {
                $style .= qq|$option->{key}:$option->{value};|; 
            }

            my $text = $inline->parse($col->{inline});
            $data .= qq| style="$style"| if $style;
            $data .= q|>|;
            $data .= $text ne '' ? $text : ' ';
            $data .= qq|</$col->{tag}>\n|;

        }
        $data .= "</tr>\n";
    }

    return qq|<table id="$id">\n$data</table>\n|;
}
sub trs {
    my $self  = shift;
    my $items = shift;
    my @rows = ();
    my $rowspan = {};

    for ( reverse @$items ) {
        my $remove_cell = {};
        my $colspan_total = 0;
        my $row   = $self->row($_->{rows});
        for ( my $j = 0; $j < scalar @$row ; $j++ ) { 
            $colspan_total +=  $row->[$j]->{colspan} - 1;
            if( $row->[$j]{inline} =~ /^\^$/ ) {
                $rowspan->{$j + $colspan_total }{cnt}++;
                $remove_cell->{$j} = 1;
            }
            else {
                if ( $rowspan->{$j + $colspan_total }{cnt} ) {
                    $row->[$j]->{rowspan} = $rowspan->{$j + $colspan_total }{cnt} + 1;
                    $rowspan->{$j + $colspan_total}{cnt} = 0;
                }
            }
        }
        my @new_row = ();
        for ( my $j = 0 ; $j < scalar @{$row}  ; $j++ ) {
            push @new_row , $row->[$j] unless $remove_cell->{$j};            
        }
        push @rows , \@new_row;
    }

    @rows = reverse @rows;
    return \@rows;
}
sub row {
    my $self  = shift;
    my $cells = shift;
    my $on_force_th = 0;
    my @row = ();
    my $colspan=1;
    for my $cell ( @$cells ) {
        my @options  = ();
        my $tag      = 'td';
        $cell =~ s/^\s+//;
        $cell =~ s/\s+$//;

        if( $cell =~ /^>$/ ) {
            $colspan++;
            next;
        }
        # th
        if( $cell =~ /^\!/ ) {
            $tag = 'th';
            $cell =~ s/^\!//;
        }
        # force th
        elsif( $cell =~ /^~/ ) {
            $on_force_th = 1;
            $cell =~ s/^~//;
        }

        if( $on_force_th ) {
            $tag = 'th';
        }

        my $data  = {};
        while(1){
            if ( my( $style , $value , $left ) = $cell =~ /^(BGCOLOR|COLOR|SIZE|LEFT|CENTER|RIGHT)\s*(?:\(([A-Za-z0-9\-\#]*)\))?\s*:\s*(.*)/i) {
                $cell = $left;
                $style = lc $style;
                if( $style  eq 'bgcolor' ) {
                    $style = 'background-color'; 
                }
                elsif( $style =~ /left|center|right/ ) {
                    $value = $style;
                    $style = 'text-align';
                }
                elsif( $style eq 'size' ) {
                    $style = 'font-size'; 
                    $value .= 'px';
                }
                push @options , { key => $style , value => $value } ;
            }
            else {
                last;
            }
        }
        %$data =  ( %$data , ( inline => $cell  , options => \@options , tag => $tag , colspan => $colspan ) );
        push @row , $data;

        if( $colspan > 1 ) {
            $colspan = 1;
        }
    }

    return \@row;
}
#}}}

sub mobile {
    my $self   = shift;
    my $block  = shift;
    my $inline = shift;
    my $items  = shift;

    my $data = '';

    for my $item ( @$items ) {
        my $rows = $item->{rows};
        for my $cell ( @$rows ) {
            $cell =~ s/^\s+//;
            $cell =~ s/\s+$//;
            next if $cell  =~ /^>$/ ;
            next if $cell =~ /^\^/;

            $cell =~ s/^\!//;
            $cell =~ s/^~//;
            while(1){
                if ( my( $style , $value , $left ) = $cell =~ /^(BGCOLOR|COLOR|SIZE|LEFT|CENTER|RIGHT)\s*(?:\(([A-Za-z0-9\-\#]*)\))?\s*:\s*(.*)/i) {
                    $cell = $left;
                }
                else {
                    last;
                }
            }
          
            $data .= $inline->parse($cell) . ' ';
        }
        $data .= "<br />\n";
    }


    return $data;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::Table - Table Block Plugin

=head1 DESCRIPTION

create table.

=head1 SYNOPSIS

 |hoge|hoge|
 |!hoge|hoge|
 |~hoge|hoge|
 |>|hoge|

 ,hoge,hoge,
 ,^,hoge,

=head1 FUNCTION

=head2 check

=head2 get

=head2 mobile

=head2 row

=head2 trs

=head1 AUTHOR

polocky

=cut
