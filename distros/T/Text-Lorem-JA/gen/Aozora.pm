package Aozora;
use strict;
use warnings;
use utf8;

package Aozora::TextFilter;

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub finish {
    my ($self) = @_;

    if ($self->{next_filter}) {
        $self->{next_filter}->finish();
    }
}

sub puts {
    my ($self, $line) = @_;
    $self->{next_filter}->input($line);
}

package Aozora::ResultCatcher;

use parent -norequire, 'Aozora::TextFilter';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{lines} = [];
    return $self;
}

sub input {
    my ($self, $line) = @_;
    push @{ $self->{lines} }, $line;
}

package Aozora::FileOutput;

use parent -norequire, 'Aozora::TextFilter';

sub new {
    my ($class, $filename) = splice @_, 0, 2;
    my $self = $class->SUPER::new(@_);
    open my $handle, '>:encoding(UTF-8)', $filename  or die $!;
    $self->{handle} = $handle;
    return $self;
}

sub input {
    my ($self, $line) = @_;
    print { $self->{handle} } $line;
}

sub finish {
    my ($self) = @_;

    $self->{handle}->close();

    if ($self->{next_filter}) {
        $self->{next_filter}->finish();
    }
}

package Aozora::TextFilterManager;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{filters} = [];
    return $self;
}

sub add_filter {
    my ($self, $filter) = @_;

    push @{ $self->{filters} }, $filter;
}

sub setup {
    my ($self) = @_;

    my $n = scalar @{ $self->{filters} };
    for my $i (0 .. $n - 2) {
        $self->{filters}->[$i]->{next_filter}
            = $self->{filters}->[$i + 1];
    }
}

sub input {
    my ($self, $line) = @_;
    $self->{filters}->[0]->input($line);
}

sub finish {
    my ($self) = @_;
    $self->{filters}->[0]->finish();
}

package Aozora::BlankTrimmer;

use parent -norequire, 'Aozora::TextFilter';

sub input {
    my ($self, $line) = @_;

    $line =~ s{^\s+}{}gxmso;

    if ($line !~ m{\A \s* \z}xmso) {
        $self->puts($line);
    }
}

package Aozora::AozoraTrimmer;

use parent -norequire, 'Aozora::TextFilter';

sub input {
    my ($self, $line) = @_;

    $line =~ s{｜(\S+?)《.*?》}{$1}gxmso;
    $line =~ s{《.*?》}{}gxmso;
    $line =~ s{［＃.*?］}{}gxmso;

    $self->puts($line);
}

package Aozora::AozoraTrimHeader;

use parent -norequire, 'Aozora::TextFilter';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{state} = 0;
    return $self;
}

sub input {
    my ($self, $line) = @_;

    if ($self->{state} == 2) {
        $self->puts($line);
    }
    elsif ($self->{state} <= 1) {
        if ($line =~ m{^----------}) {
            $self->{state} += 1;
        }
    }
}

package Aozora::AozoraTrimTrailer;

use parent -norequire, 'Aozora::TextFilter';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{state} = 0;
    return $self;
}

sub input {
    my ($self, $line) = @_;

    if ($self->{state} == 1) {
        # pass
    }
    elsif ($self->{state} == 0) {
        if ($line =~ m{^底本：}) {
            $self->{state} = 1;
        } else {
            $self->puts($line);
        }
    }
}

package Aozora::NakamidashiTrimmer;

use parent -norequire, 'Aozora::TextFilter';

sub input {
    my ($self, $line) = @_;

    if ($line !~ m{^ .*? ［＃ .*? 中見出し］ \s* $}xmso) {
        $self->puts($line);
    }
}

package Aozora::StandardFetcher;

use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir catfile rel2abs );
use File::Path qw( mkpath );
use Furl;

our $DOWNLOAD_DIR = rel2abs(catdir(dirname(__FILE__), 'download'));

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub fetch {
    my ($self, $filename, $url, $options) = @_;
    my $force = $options->{force};

    my $output_file = catfile($DOWNLOAD_DIR, $filename);
    if (-f $output_file && ! $force) {
        return $output_file;
    }

    my $res = Furl->new()->get($url);
    die unless $res->is_success;

    if (! -d $DOWNLOAD_DIR) {
        mkpath $DOWNLOAD_DIR;
    }

    open my $file, '>', $output_file  or die $!;
    binmode $file  or die $!;

    print {$file} $res->body;

    close $file;

    return $output_file;
}

sub extract {
    my ($self, $archive, $target, $options) = @_;

    my $encoding = $options->{external_encoding} || 'CP932';

    if (! -f $archive) {
        die;
    }

    my $cmdline = "unzip -xqc $archive $target";

    open my $pipe, '-|', $cmdline  or die $!;
    binmode $pipe, ":encoding($encoding)"  or die $!;

    return $pipe;
}

package Aozora::AozoraFetcher;

use parent -norequire, 'Aozora::StandardFetcher';

use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir catfile rel2abs );
use File::Path qw( mkpath );

our $TEXT_DIR = rel2abs(catdir(dirname(__FILE__), 'text'));

sub run {
    my ($class, $args) = @_;

    my $self = $class->new();

    my $output_file = catfile($TEXT_DIR, $args->{output});
    if (-f $output_file && $args->{force}) {
        return $output_file;
    }

    my $archive = $self->fetch($args->{archive_name}, $args->{url});

    if (! -d $TEXT_DIR) {
        mkpath $TEXT_DIR;
    }

    my $manager = $self->create_manager($output_file);

    my $source = $self->extract($archive, $args->{source});
    while (my $line = <$source>) {
        $manager->input($line);
    }
    unless (close $source) {
        unlink $output_file;
        die "I think pipe open (unzip) failed: $!";
    }

    $manager->finish();

    return $output_file;
}

sub create_manager {
    my ($self, $output_file) = @_;

    my $manager = Aozora::TextFilterManager->new();
    $manager->add_filter(Aozora::AozoraTrimHeader->new());
    $manager->add_filter(Aozora::AozoraTrimTrailer->new());
    $manager->add_filter(Aozora::BlankTrimmer->new());
    $manager->add_filter(Aozora::AozoraTrimmer->new());
    $manager->add_filter(Aozora::FileOutput->new($output_file));
    $manager->setup();

    return $manager;
}

1;
