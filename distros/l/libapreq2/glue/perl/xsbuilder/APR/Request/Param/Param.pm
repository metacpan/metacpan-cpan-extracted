package APR::Request::Param;
use APR::Request;
use APR::Table;
use APR::Brigade;

sub upload_io {
    tie local (*FH), "APR::Request::Brigade", shift->upload;
    return bless *FH{IO}, "APR::Request::Brigade::IO";
}

sub upload_fh {
    my $fname = shift->upload_tempname(@_);
    open my $fh, "<", $fname
        or die "Can't open ", $fname, ": ", $!;
    binmode $fh;
    return $fh;
}

package APR::Request::Brigade;
push our(@ISA), "APR::Brigade";

package APR::Request::Brigade::IO;
push our(@ISA), ();
