package WebService::Pocket::Script;
{
  $WebService::Pocket::Script::VERSION = '0.003';
}
#ABSTRACT: Wrap up WebService::Pocket into a runable script with a config file
use Moose;

extends 'WebService::Pocket'; # XXX: this would ideally be a role :/

with 'MooseX::SimpleConfig';
with 'MooseX::Getopt' => { -version => 0.48 };

# XXX: is this good enough?
has '+configfile' => (
    default => $ENV{HOME} . "/.pocketrc",
    traits => [qw/NoGetopt/]
);

has "+$_" => ( traits => [qw/NoGetopt/] )
for qw/api_key base_url ua json items list_since/;

has "+$_" => (documentation => "Set $_. Can also be set in ~/.pocketrc")
for qw/username password/;

before 'print_usage_text' => sub {
    print <<END;
$0 - Wrap up Webservice::Pocket in a script

Configure in ~/.pocketrc, add something like:

username=myusername
password=s3cr3t

Commands:

  add <url> [<url>]: Add url(s) to your pocket list
  list             : List unread items in pocket

END
};


sub config_any_args {
    my ($self) = @_;
    return {
        force_plugins => ['Config::Any::INI'],
    }
}

sub run {
    my ($self) = @_;
    my @args = @{ $self->extra_argv };
    my $cmd = shift @args;
    unless ($cmd) {
        die "No command given, try add <url> [<url>] to add something to pocket";
    }
    if (my $action = $self->can("cmd_$cmd")) {
        $self->$action(@args);
    }
}

sub cmd_add {
    my ($self, @args) = @_;

    my @items = map {
    {
        url => $_
    }
    } @args;
    my $res = $self->add(\@items);
    print join("\n*", map { $_->url } @$res);
}

sub cmd_list {
    my ($self, @args) = @_;

    my $list = $self->list(state => 'unread');

    foreach my $item (@$list) {
        # Not everything has a title. In those cases, show the url.
        my $title = $item->{title} || $item->{url};
        print "* $title\n";
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Pocket::Script - Wrap up WebService::Pocket into a runable script with a config file

=head1 VERSION

version 0.003

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
