package App::Grok::Resource::Tablet;
BEGIN {
  $App::Grok::Resource::Tablet::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::Resource::Tablet::VERSION = '0.26';
}

use strict;
use warnings FATAL => 'all';
use App::Grok::Common qw<data_dir download>;
use File::ShareDir qw<dist_dir>;
use File::Spec::Functions qw<catdir catfile>;
use File::stat;

use base qw<Exporter>;
our @EXPORT_OK = qw<tablet_index tablet_fetch tablet_locate tablet_update>;
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

my %tablet;
my $tablet_file = _find_tablet_file();

sub _find_tablet_file {
    my $global = catfile(dist_dir('Perl6-Doc'), 'table_index.pod');
    my $local = catfile(data_dir(), 'resources', 'tablet', 'perl_6_index_tablet.pod');

    die "Tablet file not found\n" if !-e $global && !-e $local;
    return $global if !-e $local;
    return $local if !-e $global;
    return _newer($local, $global);
}

sub _newer {
    my ($x, $y) = @_;

    my $x_stat = stat($x) or die "Can't stat $x: $!";
    my $y_stat = stat($y) or die "Can't stat $y: $!";
    return $x if $x_stat->mtime > $y_stat->mtime;
    return $y;
}

sub _to_text {
    my $text = shift;
    $text =~ s/<em>(.+?)<\/em>/$1/g;
    $text =~ s/<.+?>//g;
    $text =~ s/&amp;/&/g;
    $text =~ s/&lt;/</g;
    $text =~ s/&gt;/>/g;
    $text =~ s/&quot;/"/g;
    $text =~ s/&nbsp;/ /g;
    return $text;
}

sub tablet_update {
    my $res_dir = catdir(data_dir(), 'resources', 'tablet');
    if (!-d $res_dir) {
        mkdir $res_dir or die "Can't create $res_dir: $!\n";

    }

    print "Downloading Perl 6 Index Tablet...\n";
    my $content = download(
        '(1/1) perl_6_index_tablet',
        'http://www.perlfoundation.org/perl6/index.cgi?perl_6_index_tablet',
    );

    my %help;
    for my $line (split /\n/, $content) {
        chomp $line;

        if ($line =~ /<li><strong>(.+?)<\/strong>(.+?)<\/li>/) {
            my ($item, $item_description)= (_to_text($1), _to_text($2) );
            $item_description =~ s/^\s+//;
            if ($help{$item}) {
                $help{$item} .= "\n=item $item_description\n";
            }
            else {
                $help{$item} = "=item $item_description\n";
            }
        }
    }

    my $pod;
    for my $item (sort keys %help) {
        $pod .=  "=head2 C<<< $item >>>\n\n=over\n\n" . $help{$item} . "\n=back\n\n";
    }

    my $file = catfile($res_dir, 'perl_6_index_tablet.pod');
    open my $fh, '>:encoding(utf8)', $file or die "Can't create $file: $!";
    print $fh $pod;
    close $fh;
    return;
}

sub tablet_fetch {
    my ($topic) = @_;
    
    if ($topic eq 'tablet_index') {
        open my $handle, '<:encoding(utf8)', $tablet_file or die "Can't open $tablet_file: $!";
        my $pod = do { local $/ = undef; scalar <$handle> };
        close $handle;
        return $pod;
    }

    _build_tablet() if !%tablet;
    return $tablet{$topic} if defined $tablet{$topic};
    return;
}

sub tablet_index {
    _build_tablet() if !%tablet;
    return keys %tablet;
}

sub tablet_locate {
    return $tablet_file;
}

sub _build_tablet {
    my ($self) = @_; 

    ## no critic (InputOutput::RequireBriefOpen)
    open my $tablet_handle, '<', $tablet_file or die "Can't open '$tablet_file': $!";

    my $entry;
    while (my $line = <$tablet_handle>) {
        $entry = $1 if $line =~ /^=head2 C<<< (.+) >>>$/;
        $tablet{$entry} .= $line if defined $entry;
    }
    while (my ($key, $value) = each %tablet) {
        $tablet{$key} = "=encoding utf8\n\n$value";
    }

    return;
}

1;

=encoding utf8

=head1 NAME

App::Grok::Resource::Tablet - Perl 6 Tablet Index resource for grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Resource::Tablet qw<:ALL>;

 # a list of all entries in the tablet
 my @index = tablet_index();

 # documentation for a tablet entry
 my $pod = tablet_fetch('+');

 # filename where the tablet entry was found
 my $file = tablet_locate('+');

=head1 DESCRIPTION

This resource looks up entries in the Perl 6 Tablet Index
(L<http://www.perlfoundation.org/perl6/index.cgi?perl_6_index_tablet>).

=head1 FUNCTIONS

=head2 C<tablet_update>

Takes no arguments. Downloads the latest tablet into grok's data dir.

=head2 C<tablet_index>

Takes no arguments. Lists all entry names in the tablet.

=head2 C<tablet_fetch>

Takes an entry name as an argument. Returns the documentation for it.

=head2 C<tablet_locate>

Takes an entry name as an argument. Returns the name of the file where it
was found.

=cut
__DATA__
=head1 Perl 6 table index

This is the POD version of http://www.perlfoundation.org/perl6/index.cgi?perl_6_index_tablet

=head1 AUTHORS

For authors of the original wiki place, see:
http://www.perlfoundation.org/perl6/index.cgi?action=revision_list;page_name=perl_table_index

=head1 LICENSE

Copyright (c) 2006-2010 under the same (always latest) license(s) used by the Perl 6 /src 
branch of the Pugs trunk.

=head1 Table index
