use inc::Module::Install;

name 'Text-Xslate-Bridge-TT2Like';
all_from 'lib/Text/Xslate/Bridge/TT2Like.pm';

requires 'Text::Xslate' => '1.3000';
requires 'Scalar::Util';
author_tests 'xt';

no_index 'directory' => 'src';
WriteAll;

if ($Module::Install::AUTHOR) {
    warn "Author mode, auto generating pod";

    open my $fh, '<', File::Spec->catfile('lib', 'Text', 'Xslate', 'Bridge', 'TT2Like.pm' ) or
        die "Could not open file : $!";

    my $currkey;
    my %sections;
    while ( <$fh> ) {
        next unless /^__PACKAGE__->bridge\(/;
        while ( <$fh> ) {
            last if /^\)$/;
            if (/^\s+(\w+)\s+=>\s+{/) {
                $currkey = $1;
                $sections{ $currkey } = [];
            } elsif ( /^\s+(\w+)\s+=>/ ) {
                push @{ $sections{ $currkey } }, $1;
            }
        }
    }

    require Text::Xslate;
    my $xslate = Text::Xslate->new(
        syntax => 'TTerse',
        path   => 'src'
    );
    my $string = $xslate->render( 'TT2Like.tx', {
        sections => \%sections,
        names    => [ sort keys %sections ],
    } );
    open my $pod, '>', File::Spec->catfile('lib', 'Text', 'Xslate', 'Bridge', 'TT2Like.pod' ) or
        die "Could not open file: $!";

    print $pod $string;
    close $pod;
}
