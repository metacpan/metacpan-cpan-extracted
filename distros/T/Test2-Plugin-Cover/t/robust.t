use Test2::Plugin::Cover ();
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;

# A custom extract/filter that dies on one file must not cost the rest of
# the report, and must never turn into an exception at report time.

{
    package My::Cover::BadExtract;
    our @ISA = ('Test2::Plugin::Cover');

    sub extract {
        my ($class, $file, %params) = @_;
        die "extract boom\n" if $file =~ m/bad_extract/;
        return $class->SUPER::extract($file, %params);
    }
}

{
    package My::Cover::BadFilter;
    our @ISA = ('Test2::Plugin::Cover');

    sub filter {
        my ($class, $file, %params) = @_;
        die "filter boom\n" if $file =~ m/bad_filter/;
        return $class->SUPER::filter($file, %params);
    }
}

$CLASS->enable;
$CLASS->reset_coverage;

$CLASS->touch_source_file('good_file.pl');
$CLASS->touch_source_file('bad_extract_file.pl');
$CLASS->touch_source_file('bad_filter_file.pl');

my $files;

like(
    warnings { $files = My::Cover::BadExtract->files(root => path('.')) },
    bag { item qr/could not extract a filename from 'bad_extract_file\.pl'/; etc },
    "warned about the dying extract"
);

like(
    $files,
    bag { item 'good_file.pl'; item 'bad_filter_file.pl'; etc },
    "the other files still made it into the report"
);

like(
    warnings { $files = My::Cover::BadFilter->files(root => path('.')) },
    bag { item qr/could not filter 'bad_filter_file\.pl'/; etc },
    "warned about the dying filter"
);

like(
    $files,
    bag { item 'good_file.pl'; item 'bad_extract_file.pl'; etc },
    "the other files still made it into the report"
);

$CLASS->reset_coverage;

done_testing;
