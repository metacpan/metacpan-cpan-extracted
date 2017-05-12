package Ubic::Persistent;
$Ubic::Persistent::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: simple hash-to-file persistence object


use JSON;
use Ubic::Lockf;
use Ubic::AtomicFile;

{
    # support the compatibility with JSON.pm v1 just because we can
    # see also: Ubic::ServiceLoader::Ext::json
    no strict;
    no warnings;
    sub jsonToObj; *jsonToObj = (*{JSON::from_json}{CODE}) ? \&JSON::from_json : \&JSON::jsonToObj;
    sub objToJson; *objToJson = (*{JSON::to_json}{CODE}) ? \&JSON::to_json : \&JSON::objToJson;
}

my $meta = {};

sub _load {
    my ($fname) = @_;

    open my $fh, '<', $fname or die "Can't open $fname: $!";
    my $data;
    local $/;
    my $str = <$fh>;
    if ($str =~ /^\$data/) {
        # old Data::Dumper format, parsing with regexes
        my ($status) = $str =~ m{'status' => '(\w+)'};
        my ($enabled) = $str =~ m{'enabled' => (\d+)};
        $data = { status => $status, enabled => $enabled };
    }
    else {
        $data = jsonToObj($str);
    }

    return $data;
}

sub load {
    my ($class, $fname) = @_;
    return _load($fname);
}

sub new {
    my ($class, $fname) = @_;
    my $lock = lockf("$fname.lock", { blocking => 1 });

    my $self = {};
    $self = _load($fname) if -e $fname;

    bless $self => $class;
    $meta->{$self} = { lock => $lock, fname => $fname };
    return $self;
}

sub commit {
    my $self = shift;
    my $fname = $meta->{$self}{fname};

    Ubic::AtomicFile::store(objToJson({ %$self }) => $fname);
}

sub DESTROY {
    my $self = shift;
    local $@;
    delete $meta->{$self};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Persistent - simple hash-to-file persistence object

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::Persistent;
    $obj = Ubic::Persistent->new($file); # create object and lock it
    $obj->{x} = 'y';
    $obj->commit; # atomically save file

    $data = Ubic::Persistent->load($file); # { x => 'y' }

=head1 METHODS

=over

=item B<< Ubic::Persistent->load($file) >>

Class method. Load data from file without obtaining lock.

=item B<< Ubic::Persistent->new($file) >>

Construct new persistent object. It will contain all data from file.

Data will be locked all the time this object exists.

=item B<< $obj->commit() >>

Write data back on disk.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
