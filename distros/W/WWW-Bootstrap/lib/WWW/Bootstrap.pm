package WWW::Bootstrap;
use Moose;
use namespace::autoclean;

use CSS::LESS::Filter;
use Path::Extended;
use HTTP::Tiny;
use Archive::Zip;

our $VERSION = '0.03';

BEGIN { system('which npm >/dev/null 2>&1 ') && warn "could not find npm, please install node.js"; }

has 'workdir' => (
    isa     => 'Str',
    is      => 'ro',
    default => '/tmp/bootstrap',
);

has dl_url => (
    isa     => 'Str',
    is      => 'ro',
    default => 'https://github.com/twbs/bootstrap/archive/master.zip',

);

has disabled_features => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        disable_feature      => 'push',
        all_features_enabled => 'is_empty',
    },
);

has variables => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        set_variable     => 'set',
        has_no_variables => 'is_empty',
    },
);

sub fetch_and_extract {
    my ( $self, $file ) = @_;
    my $zipfile;
    unless ( $file ) {
        # if we have the optional file parameter, we will unpack a local file, else we have to download it
        my $ua = HTTP::Tiny->new;
        my $res = $ua->get($self->dl_url);
        die "$res->{status} $res->{reason}" unless $res->{success};
        my $data = $res->{content};
        open my $zipfh,'+<',\$data;
        $zipfile = Archive::Zip->new();
        $zipfile->readFromFileHandle($zipfh);
    } else {
        $zipfile = Archive::Zip->new($file);
    }
    die "could not read Bootstrap archive" unless $zipfile;
    
    for ( $zipfile->members ) {
        # TODO skip unwanted files like disabled componenets
        $_->extractToFileNamed(file($self->workdir,$_->fileName)->absolute);
    }
}

sub update_less {
    my ( $self ) = @_;

    $self->{lessdir} = dir($self->workdir,'bootstrap-master','less');
    # remove the includes for unwanted features
    unless ( $self->all_features_enabled ) {
        my $filter = CSS::LESS::Filter->new;
        my @not_used = @{$self->disabled_features};
        $self->_filter_less_file(bootstrap => [
            '@import',sub {
                my $value = shift;
                for ( @not_used ) {
                    return if $value =~ /['"]$_.less['"]/;
                }
                $value;
            }
        ]);
    }
    unless ( $self->has_no_variables ) {
        my $varfilter = [];
        foreach my $var ( keys %{$self->variables} ) {
            push(@$varfilter,
                sprintf('@%s:',$var),
                $self->variables->{$var},
            );
        }
        $self->_filter_less_file(variables => $varfilter);
    }
}


sub build {
    my ( $self ) = @_;
    chdir dir($self->workdir,'bootstrap-master');
    system("npm install") and warn "grunt error: $?";
    system("grunt clean") and warn "grunt error: $?";
    system("grunt dist-css") and warn "grunt error: $?";
    system("grunt dist-js") and warn "grunt error: $?";
    system("grunt copy:fonts") and warn "grunt error: $?";
}    

sub copy_to {
    my ( $self, $target ) = @_;
    for my $dir ( qw/css fonts js/ ) {
        my $distdir = dir($self->workdir,"bootstrap-master/dist",$dir);
        for my $file ($distdir->children) {
            next if $file->basename eq 'npm.js';
            $file->copy_to(dir($target,$dir,$file->basename));
        }
    }
}

sub _filter_less_file {
    my ( $self, $name, $filters ) = @_;
    my $file = $self->{lessdir}->file("$name.less");
    my $less = $file->exists ? $file->slurp : '';
    my $filter = CSS::LESS::Filter->new;
    $filter->add(@$filters);
    $less = $filter->process($less, {mode => 'append'});
    $file->save($less);
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Bootstrap - fetch, build and use the Bootstrap CSS Framework

=head1 SYNOPSIS

    use WWW::Bootstrap;

    my $bootstrap = WWW::Bootstrap->(workdir => '/tmp');

    # set a few variables
    $bootstrap->set_variable(body-bg => '#fefefe');
    $bootstrap->set_variable(font-base-size => '15px');

    # fetch the bootstrap archive from github
    $bootstrap->fetch_and_extract();
    # OR use a local copy of the github archive
    $bootstrap->fetch_and_extract('/tmp/bootstrap.zip');

    # update the *.less files
    $bootstrap->update_less();

    # generate the css and js files
    $bootstrap->build();

    # copy the files to your document root
    $bootstrap->copy_to('/var/www/htdocs/');

=head1 DESCRIPTION

WWW::Bootstrap wrapps downloading, editing less files and generating css files for the Bootstrap framework

=head2 METHODS

=over 4

=item new(%args)

Create a new Bootstrap Instance. Valid arguments are:

=over 4

=item I<workdir =E<gt> $path>

Path to the working directory to use.

Defaults to F</tmp/bootstrap>

=item I<dl_url =E<gt> $url>

URL to download bootstrap source archive.

Defaults to I<https://github.com/twbs/bootstrap/archive/master.zip>

=item I<disabled_features =E<gt> [ $feature1, $feature2, ... ]>

List of features to disable during build-time.

See also: L</disable_feature($feature)>

=item I<variables =E<gt> { $var1 =E<gt> $val1, $var2 =E<gt> $val2 }>

Hash refernce of variables to be overwritten in F<varaibles.less>

See also: L</set_variable($var =E<gt> $val)>

=back

=item disable_feature($feature)

Disable a feature during buildtime by disabling the matching lessfile. C<$feature> must be the namepart of a file in F<less/>,
for example C<"scaffolding"> for F<less/scaffolding.less>:

    $bootstrap->disable_feature("scaffolding");

=item set_variable($var =E<gt> $val)

Set the value of a variable in F<variables.less>. C<$var> must be the variable name without leading @.

    $boostrap->set_value(body-bg => '#fefefe');

For a full list of variables, have a look at L<http://getbootstrap.com/customize/#less-variables>.

=item fetch_and_extract($zipfile)

Fetch and extract the bootstrap sourcecode from github. If the optional parameter C<$zipfile> is given, it will be used as
path to a local copy of the ZIP file, instead of fetching it via HTTP.

=item update_less()

Updates the F<less/*.less> files to reflect the currently disabled features and the updated variables.

=item build()

Generates the CSS and JS files. After the process is done, the new files are located in the F<bootstrap-master/dist> folder in the working directory.

=item copy_to($target_dir|@path_elements)

Copies the current content of the F<dist/> folder to the C<$target_dir>. If C<@path_elements>, the elements will be used to construct the target path with L<File::Spec/catfile>.
The target directory will be created if it does not already exist.

=back

=head1 CAVEATS

The build process requires L<node.js|http://nodejs.org/> to be installed to generate the CSS and JS files.

=head1 AUTHOR

=over 4

=item Thomas Berger <loki@lokis-chaos.de>

=back

=head1 LICENSE

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
