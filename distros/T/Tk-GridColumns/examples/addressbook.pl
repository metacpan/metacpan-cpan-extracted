#!/usr/bin/perl

# PRAGMAS
# -------
use strict;
use warnings;
use lib '../lib';

# MODULES
# -------
use Text::CSV;
use Tk;
use Tk::GridColumns;

my $DATAFILE = 'addressbook.txt';

my $mw = tkinit( -title => 'Tk::GridColumns example -- AddressBook' );
$mw->geometry( '=480x360+100+100' );

my $gc = $mw->Scrolled(
    'GridColumns' =>
    -scrollbars => 'ose',
    -data => \my @data,
    -columns => \my @columns,
    -bg => 'white',
    -itemattr => { -anchor => 'w', -bg => Tk::NORMAL_BG },
    -itemgrid => { -padx => 1, -pady => 1 },
    -item_bindings => { '<Double-ButtonPress-1>' => \&edit_item },
)->pack(
    -fill => 'both',
    -expand => 1,
)->Subwidget( 'scrolled' );

@columns = (
    {
        -text => 'Name',
        -command => $gc->sort_cmd( 0, 'abc' ),
    },
    {
        -text => 'Phone',
        -command => $gc->sort_cmd( 1, 'num' ),
    },
    {
        -text => 'Street',
        -command => $gc->sort_cmd( 2, 'abc' ),
        -weight => 1,
    },
);

open_adrbook( $gc, $DATAFILE )->refresh;

my $frm_bottom = $mw->Frame->pack(
    -side => 'bottom',
    -fill => 'x',
);

$frm_bottom->Button(
    -text => 'New entry',
    -command => sub { $gc->add_row( 'New', 0, '' )->refresh_items },
)->pack(
    -side => 'left',
);

$frm_bottom->Button(
    -text => 'Delete entry',
    -command => sub {
        my @sel = @{ $gc->curselection };
        if ( @sel ) {
            $gc->deselect( $sel[0][0], $_ ) for 0 .. 2;
            splice @data, $sel[0][0], 1;
            $gc->refresh_items;
        } # if
    },
)->pack(
    -side => 'left',
);

$frm_bottom->Button(
    -text => 'Save changes',
    -command => sub { save_adrbook( $gc, $DATAFILE ) },
)->pack(
    -side => 'right',
);

MainLoop;

sub open_adrbook {
    my( $gc, $file ) = @_;
    
    my $csv = Text::CSV->new({ 'binary' => 1 });
    my @data;
    
    open my $fh, '<', $file or die "Cannot open file '$file': $!\n";
    
    while ( my $line = <$fh> ) {
        chomp $line;
        next if $line =~ /^\s*(?:#.*)?$/;

        $csv->parse( $line );
        my @fields = $csv->fields;
        
        if ( defined $fields[0] ) {
            if ( @fields == 3 ) {
                push @data, \@fields;
            } # if
            else {
                warn "open_adrbook() warning: not enough fields\n$file:$.: $line\n";
            } # else
        } # if
        else {
            my @error = $csv->error_diag;
            die "open_adrbook() failure $error[0]: $error[1]:\n$file:$.:$error[2]: ". $csv->error_input ."\n";
        } # else
    } # while
    
    close $fh;
    
    @{ $gc->data } = @data;
    
    return $gc;
} # open_adrbook

sub save_adrbook {
    my( $gc, $file ) = @_;
    
    my $csv = Text::CSV->new({ 'binary' => 1, 'always_quote' => 1 });
    
    open my $fh, '>', $file or die "Cannot open file '$file': $!\n";

    for my $row ( 0 .. $#{ $gc->data } ) {
        $csv->combine( @{ $gc->data->[$row] } );
        my $line = $csv->string;
        
        if ( defined $line ) {
            print $fh "$line\n";
        } # if
        else {
            my @error = $csv->error_diag;
            die "save_adrbook() failure $error[0]: $error[1]:\ndata row $row: ". $csv->error_input ."\n";
        } # else
    } # for
    
    close $fh;
    
    return $gc;
} # save_adrbook

sub edit_item {
    my( $self, $w, $row, $col ) = @_;
    
    $w->destroy;
    
    my $entry = $self->Entry(
        -textvariable => \$data[$row][$col],
        -width => 0,
    )->grid(
        -row => $row+1,
        -column => $col,
        -sticky => 'nsew',
    );
    
    $entry->selectionRange( 0, 'end' );
    $entry->focus;

    $entry->bind( '<Return>' => sub { $self->refresh_items } );
    $entry->bind( '<FocusOut>' => sub { $self->refresh_items } );
} # edit_item

__END__

