package main;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::LoadModule;

load_module_or_skip_all 'ExtUtils::Manifest', undef, [
    qw{ maniread } ];

load_module_or_skip_all 'Perl::MinimumVersion';

load_module_or_skip_all 'version';

use lib qw{ inc };
use My::Module::Meta;

my $min_perl = My::Module::Meta->requires_perl();
my $min_perl_vers = version->parse( $min_perl );

my $manifest = maniread();

foreach my $fn ( sort keys %{ $manifest } ) {
    $fn =~ m{ \A xt/ }smx
	and next;
    is_perl( $fn )
	or next;
    my $doc = Perl::MinimumVersion->new( slurp( $fn ) );
    cmp_ok $doc->minimum_version(), 'le', $min_perl,
	"$fn works under Perl $min_perl";
    my $ppi_doc = $doc->Document();
    foreach my $inc (
	@{ $ppi_doc->find( 'PPI::Statement::Include' ) || [] } ) {
	my $vers = $inc->version()
	    or next;
	ok( version->parse( $vers ) == $min_perl_vers,
	    "$fn has use $min_perl, rather than some other version" );
	last;
    }
}

done_testing;

sub is_perl {
    my ( $fn ) = @_;
    $fn =~ m/ [.] (?: pm | t | pod | (?i: pl ) ) \z /smx
	and return 1;
    -f $fn
	and -T _
	or return 0;
    open my $fh, '<', $fn
	or return 0;
    local $_ = <$fh>;
    close $fh;
    return m/ perl /smx;
}

# The problem we solve with this is that Perl::MinimumVersion relies on
# PPI to parse the code. But if I just pass PPI the file name it gets
# opened with no encoding specified, and slurped. Since the files are
# actually UTF-8, this is what I need. So I open the file with the
# correct encoding, slurp, and pass the content to Perl::MinimumVersion.
sub slurp {
    my ( $fn ) = @_;
    local $/ = undef;
    open my $fh, '<:encoding(utf-8)', $fn
	or die "Unable to open $fn: $!\n";
    my $data = <$fh>;
    close $fh;
    return \$data;
}

1;

# ex: set textwidth=72 :
