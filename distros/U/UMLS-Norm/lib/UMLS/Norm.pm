package UMLS::Norm;

use strict;
use warnings;

our $VERSION = '0.01';

our @EXPORT = qw(
		 start_norm
		 normalize
		);


our $PATH;
$PATH = '/home/software/LuiNorm';
our ($I_NORM, $O_NORM);

sub start_norm {
    chdir( $_[0] || $PATH || die "Please specify the path of LUINORM program") or die $!;
    my $pid = open2($I_NORM, $O_NORM, './luiNorm');
}

END {
    close $I_NORM;
    close $O_NORM;
}

sub tag {
    my $text = shift or die "Please input text";
    print {$O_NORM} $text."\n";
    local $_;
    my $result;
    while($_ = <$I_NORM>){
	$result .= $_;
	last;
    }
    return $result;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

UMLS::Norm - Perl extension for UMLS-Norm based term normalization

=head1 SYNOPSIS

  use UMLS::Norm;
  UMLS-Norm based term normalization

=head1 DESCRIPTION

Stub documentation for UMLS::Norm, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

UMLS-Norm based term normalization

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Harsha Gurulingappa, E<lt>harsha@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Harsha Gurulingappa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
