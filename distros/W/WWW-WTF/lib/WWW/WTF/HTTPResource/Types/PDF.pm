package WWW::WTF::HTTPResource::Types::PDF;

use common::sense;

use Moose::Role;

use WWW::WTF::Helpers::ExternalCommand qw(run_external_command);

use File::Find::Rule;
use File::Temp;

sub get_images {
    my ($self) = @_;

    my $dir = File::Temp->newdir( DIR => '/tmp', CLEANUP => 0 );

    my $pdf_path = "$dir/input.pdf";

    $self->content->write_to($pdf_path);

    my $out = run_external_command({
        command => 'pdfimages',
        args    => [ $pdf_path, "$dir/", '-png' ],
    });

    my @files = File::Find::Rule
        ->file()
        ->name('*.png')
        ->in  ($dir);

    return @files;
}

1;
