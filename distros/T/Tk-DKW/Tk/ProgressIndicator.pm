package Tk::ProgressIndicator;

use Tk;
use Tk::Frame;

use base qw (Tk::Derived Tk::Frame);
use vars qw ($VERSION);
use strict;
use Carp;

$VERSION = '0.02';

Tk::Widget->Construct ('ProgressIndicator');

sub Populate
   {
    my $this = shift;

    $this->SUPER::Populate (@_);

    $this->{'m_Increment'} = 10;
    $this->{'m_Current'} = 0;
    $this->{'m_Padding'} = 1;
    $this->{'m_Limit'} = 100;

    $this->configure
       (
        '-relief' => 'sunken',
        '-borderwidth' => 2,
       );

    $this->ConfigSpecs
       (
        '-foreground' => [['SELF','PASSIVE','METHOD'], 'foreground', 'Foreground', 'blue'],
        '-increment'  => ['METHOD', 'increment', 'Increment', 10],
        '-current'    => ['METHOD', 'current', 'Current', 0],
        '-padding'    => ['METHOD', 'padding', 'Padding', 1],
        '-limit'      => ['METHOD', 'limit', 'Limit', 100],
       );

    return $this;
   }

sub Reconfigure
   {
    my $this = shift;

    my $l_CellCount = int ($this->{'m_Limit'} / $this->{'m_Increment'});

    foreach my $l_Child ($this->children())
       {
        $l_Child->destroy();
       }

    for (my $l_Index = 1; $l_Index <= $l_CellCount; ++$l_Index)
       {
        my $l_Cell = $this->Component
           (
            'Frame' => 'Cell_'.$l_Index,
            '-borderwidth' => 1,
            '-relief' => 'flat',
           );

        $l_Cell->place
           (
            '-relx' => ($l_Index - 1) * ($this->{'m_Increment'} / $this->{'m_Limit'}),
            '-relwidth' => $this->{'m_Increment'} / $this->{'m_Limit'},
            '-width' => - $this->{'m_Padding'},
            '-relheight' => '1.0',
            '-height' => -1,
            '-y' => 0,
           );
       }

    $this->configure
       (
        '-current' => $this->cget ('-current')
       );
   }

sub limit
   {
    my ($this, $p_Limit) = @_;

    if (defined ($p_Limit))
       {
        $this->{'m_Limit'} = $p_Limit;
        $this->Reconfigure();
       }

    return $this->{'m_Limit'};
   }

sub increment
   {
    my ($this, $p_Increment) = @_;

    if (defined ($p_Increment))
       {
        $this->{'m_Increment'} = $p_Increment;
        $this->Reconfigure();
       }

    return $this->{'m_Current'};
   }

sub current
   {
    my ($this, $p_Current) = @_;

    if (defined ($p_Current))
       {
        my $l_UpTo = int (($this->{'m_Current'} = $p_Current) / $this->{'m_Increment'});

        my $l_CellCount = int ($this->{'m_Limit'} / $this->{'m_Increment'});

        for (my $l_Index = 1; $l_Index <= $l_CellCount; ++$l_Index)
           {
            my $l_Cell = $this->Subwidget ('Cell_'.$l_Index);

            next unless Exists ($l_Cell);

            $l_Cell->configure
               (
                '-background' => ($l_Index <= $l_UpTo ? $this->cget ('-foreground') : $this->cget ('-background'))
               );
           }
       }

    return $this->{'m_Current'};
   }

sub foreground
   {
    my ($this, $p_Foreground) = @_;

    if (defined ($p_Foreground))
       {
        $this->{'m_Foreground'} = $p_Foreground;
        $this->Reconfigure();
       }

    return $this->{'m_Foreground'};
   }

sub padding
   {
    my ($this, $p_Padding) = @_;

    if (defined ($p_Padding))
       {
        $this->{'m_Padding'} = $p_Padding;
        $this->Reconfigure();
       }

    return $this->{'m_Padding'};
   }

1;

__END__

=cut

=head1 NAME

Tk::ProgressIndicator - Another, simpler ProgressBar

=head1 SYNOPSIS

    use Tk::ProgressIndicator;

    my $MainWindow = MainWindow->new();

    $ProgressIndicator = $MainWindow->ProgressIndicator
       (
        '-current' => 0,
        '-limit' => 200,
        '-increment' => 10,
        '-height' => 20,
        '-width' => 400
       );

    Tk::MainLoop;

    ...

    $ProgressIndicator->configure ('-current' => ++$index);

=head1 DESCRIPTION

A progress bar widget.

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

=head1 HISTORY 
 
=cut
