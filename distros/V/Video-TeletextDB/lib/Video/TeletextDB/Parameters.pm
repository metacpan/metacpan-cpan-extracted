package Video::TeletextDB::Parameters;
use 5.006001;
use strict;
use warnings;
use Carp;
use Fcntl qw(O_CREAT O_RDWR LOCK_EX LOCK_NB);
use POSIX qw(ENOENT);

our $VERSION = "0.01";

use Exporter::Tidy
    Other	=> [qw(%default_parameters check_channel_name)];

our %default_parameters =
    (page_versions	=> undef,
     want		=> undef,
     RW			=> undef,
     creat		=> undef,
     umask		=> undef,
     stale_period	=> 20 * 60,
     expire_period	=> 2 * 24 * 60 * 60,
     # blocking		=> 1,
     channel		=> undef,
     user_data		=> undef);

sub new {
    croak "$_[0] requires an even number of parameters" unless @_ % 2;
    my $parameters = bless {}, shift;
    my %params = @_;
    $parameters->{parent} = delete $params{parent} if exists $params{parent};
    $parameters->init(\%params);
    croak("Unknown parameters ", join(", ", keys %params)) if %params;
    return $parameters;
}

sub check_channel_name {
    my $channel = shift;
    my $msg = !defined($channel) ? "Channel name is undefined" :
        $channel eq "" ? "Channel name is empty" :
        # Reasons:
        # : ; \\ and / because they are used as component separators
        # ' because it makes database quoting tricky if we ever go sql
        # \0 because it stops parsing in systemcalls
        $channel =~ m!([:;./\'\\\0])! ? "Channel '$channel' contains forbidden character '$1'" : return;
    croak $msg unless shift;
    return $msg;
}

sub channels {
    my $dir = shift->cache_dir || croak "No directory";
    $dir =~ m!/\z! || croak "Directory '$dir' does not end with a /";
    opendir(my $dh, $dir) || croak "Could not opendir $dir: $!";
    return map(m!\A(.+)\.db\z!s && !check_channel_name($1, 1) &&
               -f "$dir$_" && -r _ ? $1 : (), readdir($dh));
}

sub has_channel {
    my $tele = shift;
    local $tele->{channel} = shift if @_;
    return 1 if !check_channel_name($tele->{channel}, 1) &&
        -f $tele->db_file && -r _;
    return;
}

sub init {
    my ($parameters, $params) = @_;

    for (keys %default_parameters) {
        my $val = exists $params->{$_} ? delete $params->{$_} :
            $parameters->{parent} && $parameters->{parent}{$_};
        if (defined $val) {
            $parameters->{$_} = $val;
        } elsif (defined $default_parameters{$_}) {
            $parameters->{$_} = $default_parameters{$_};
        }
    }
    if (defined($parameters->{page_versions})) {
        $parameters->{page_versions} == int($parameters->{page_versions}) ||
            croak "page_versions $parameters->{page_versions} should be a positive integer";
        $parameters->{page_versions} >= 1 ||
            croak "page_versions $parameters->{page_versions} should not be less than 1";
        $parameters->{page_versions} <= 255 ||
            croak "page_versions $parameters->{page_versions} should not be greater then 255";
    }
    check_channel_name($parameters->{channel}) if defined $parameters->{channel};
}

sub channel {
    return shift->{channel} unless @_ >= 2;

    croak "Too many arguments for channel method" if @_ > 2;
    my ($parameters, $channel) = @_;
    check_channel_name($channel) if defined($channel);

    my $old = $parameters->{channel};
    $parameters->{channel} = $channel;
    return $old;
}

sub cache_dir {
    my $parameters = shift;
    croak "'$parameters' has no cache_dir method";
}

sub db_file {
    my $parameters = shift;
    croak "No channel" unless defined($parameters->{channel});
    return $parameters->cache_dir() . $parameters->{channel} . ".db";
}

sub lock_file {
    my $parameters = shift;
    croak "No channel" unless defined($parameters->{channel});
    return $parameters->cache_dir() . $parameters->{channel} . ".lock";
}

sub want_file {
    my $parameters = shift;
    croak "No channel" unless defined($parameters->{channel});
    return $parameters->cache_dir() . $parameters->{channel} . ".want";
}

sub get_lock {
    my $parameters = shift;
    my $lock_file = shift;;
    my $old_mask  = $parameters->{creat} && defined $parameters->{umask} &&!shift() ?
        umask($parameters->{umask}) : undef;
    my $fh;
    eval {
        while (1) {
            # Do double stats until the file on which we get the lock is
            # actually the right one (in case people are deleting files)
            sysopen($fh, $lock_file,
                    $parameters->{creat} ? O_RDWR | O_CREAT : O_RDWR) ||
                        croak("Could not open",
                              $parameters->{creat} ? "/create" : "",
                              " '$lock_file': $!");
            my @stat = stat($fh) or croak "Could not fstat '$lock_file': $!";
            flock($fh, LOCK_EX) || croak "Could not lock '$lock_file': $!";
            my @new_stat = stat($lock_file);
            if (@new_stat) {
                return if $stat[0] == $new_stat[0] && $stat[1] == $new_stat[1];
            } elsif ($! != ENOENT) {
                croak "Could not restat '$lock_file': $!";
            }
        }
    };
    my $err = $@;
    umask $old_mask if defined $old_mask;
    die $err if $err;

    my $oldfh = select $fh;
    $| = 1;
    print "$$\n";
    select $oldfh;
    truncate $fh, tell($fh);
    return $fh;
}

sub lock : method {
    my $parameters = shift;
    return $parameters->get_lock($parameters->lock_file, @_);
}

sub want {
    my $parameters = shift;
    return $parameters->get_lock($parameters->want_file, @_);
}

my $code = "";
for my $name (keys %default_parameters) {
    no strict "refs";
    next if *{$name}{CODE};
#    if (defined $default_parameters{$name}) {
#        $code .= "sub $name {
#    croak 'Too many arguments for $name method' if \@_ > 1;
#    return shift->{'$name'};
#}\n";
#    } else {
        $code .= "sub $name : method {
    return shift->{'$name'} unless \@_ >= 2;
    croak 'Too many arguments for $name method' if \@_ > 2;
    my \$parameters = shift;
    my \$old = \$parameters->{'$name'};
    \$parameters->{'$name'} = shift;
    return \$old;
}\n";
#    }
}
# print STDERR $code;
if ($code) {
    eval $code;
    die $@ if $@;
}

1;
__END__
