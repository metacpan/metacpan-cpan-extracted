package XMLTK::XSPF;
use strict;
use Class::MOP;

use Sub::Exporter -setup => {
    exports => [
        map { $_ => \&_generator }
          qw{ Album Image Location Meta Playlist Title Track TrackList }
    ],
    groups => {
        default => [
            qw( Album Image Location Meta Playlist Title Track TrackList
              )
        ]
    }
};

sub _generator {
    my ( $c, $name ) = @_;
    my $class = "XMLTK::XSPF::${name}";
    Class::MOP::load_class($class);
    return sub () { $class };
}

1;
__END__
