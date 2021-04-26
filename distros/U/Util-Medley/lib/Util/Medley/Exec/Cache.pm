package Util::Medley::Exec::Cache;
$Util::Medley::Exec::Cache::VERSION = '0.060';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';
use Util::Medley::Simple::List qw(nsort);
use Util::Medley::Simple::DateTime qw(localDateTime);
use POSIX 'strftime';

with 'Util::Medley::Roles::Attributes::Cache';

=head1 NAME

Util::Medley::Exec::Cache - proxy for cmdline to Cache lib

=head1 VERSION

version 0.060

=cut

###############################################################

method getRootDir {

	say $self->Cache->rootDir;
}

method getNamespaces {

	my @ns = $self->Cache->getNamespaces;

	foreach my $ns ( nsort(@ns) ) {
		say $ns;
	}
}

method getKeys (Str  :$namespace!,
                Bool :$withExpireTime,
                  ) {

	foreach my $key ( nsort( $self->Cache->getKeys( ns => $namespace ) ) ) {

		if ($withExpireTime) {
			my $epoch =
			  $self->Cache->getExpiresAt( key => $key, ns => $namespace );
			printf "%s - %s\n", $key, localDateTime( $epoch, 1 ),;
		}
        else {
		  say $key;
        }
	}
}

method getExpiresAt (Str :$namespace!,
                     Str :$key!) {

	my $epoch = $self->Cache->getExpiresAt( key => $key, ns => $namespace );

	say "epoch: $epoch";
	printf "local: %s %s\n", localDateTime($epoch), $self->_getLocalTz;
}

#####

method _getLocalTz {

	state $tz = strftime( "%Z", localtime() );

	return $tz;
}

1;
