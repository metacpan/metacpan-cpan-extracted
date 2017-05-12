package XUL::Image::PPT;

use 5.006001;
use Moose;

use File::Spec;
use Win32::OLE;
use Win32::OLE::Const;

has 'from'  => (is => 'rw', isa => 'Int', default => 1);
has 'indir' => (is => 'rw', isa => 'Str', default => 'xul_img');

sub go {
    my $self = shift;
    my $app = Win32::OLE->GetActiveObject("PowerPoint.Application");
    my $show;
    if (!$app) {
        $app = Win32::OLE->new('PowerPoint.Application')
            or die Win32::OLE->LastError;
        $app->{Visible} = 1;
        $show = $app->Presentations->Add;
    } else {
        $app->{Visible} = 1;
        $show = $app->ActivePresentation;
    }
    if (!$show) {
        $show = $app->Presentations->Add;
    }
    if (!$show) { die "Can't create a new presentation"; }
    
    my $const = Win32::OLE::Const->Load($app);
    my $slides = $show->Slides();

    my $listing = File::Spec->catfile($self->indir, 'listing.txt');
    open my $in, $listing
        or die "Cannot open $listing for reading: $!\n";
    my $i = $self->from;
    my $slide_w = $show->PageSetup->SlideWidth;
    my $slide_h = $show->PageSetup->SlideHeight;
    while (<$in>) {
        chomp;
        next if /^\s*$/;
        my $fbase = $_;
        my $fname = File::Spec->catfile($self->indir, $fbase);
        my $slide = $slides->Add($i++, $const->{ppLayoutBlank});
        warn "inserting $fname...\n";
        my $msoFalse = 0;
        my $msoTrue  = -1;
        my $pic = $slide->Shapes->AddPicture(
            File::Spec->rel2abs($fname),   # FileName
            $msoFalse,                     # LinkToFile
            $msoTrue,                      # SaveWithDocument
            0, 0,                          # Left and Top
        ) or die "error: Failed to insert picture $fname.\n";
        $pic->{Left} = ($slide_w - $pic->Width)  / 2;
        $pic->{Top}  = ($slide_h - $pic->Height) / 3;

        #$pic->Scaleheight(1, $msoTrue);
        #$pic->Scalewidth (1, $msoTrue);
    }
}

1;
__END__


=head1 NAME

XUL::Image::PPT - insert images into a ppt 

=head1 SYNOPSIS

use XUL::Image::PPT;

$obj = XUL::Image::PPT->new();

$obj->go;

This module provides interface to get ppt by inseting it images

=head1 METHODS 

=head2 new(%option)

=over 

=item * from => $from

This option gives the index from which the rest images will be inserted into a ppt and 1 is default

=item * indir => $indir

This option gives the directory, under which images are saved and 'xul_img' is default

=back

=head2 go()

invoke this method to start inserting images to get a ppt

=SEE ALSO

L<XUL::Image>

=head1 AUTHOR

Sal Zhong E<lt>zhongxiang721@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006~2007 Sal Zhong. All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as perl itself.

