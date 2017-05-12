package WebService::SyncSBS::Delicious;

use strict;
require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.02';

use Net::Delicious;

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = bless {
	user => $args->{user},
	pass => $args->{pass},
	recent_num => $args->{recent_num},
    }, $class;

    $self->{obj} = Net::Delicious->new({user => $self->{user}, pswd => $self->{pass}, debug => 0});

    return $self;
}

sub get_recent {
    my $self = shift;

    my $ret = {};
    foreach ($self->{obj}->recent_posts({count => $self->{recent_num}})) {
	$ret->{$_->href} = {
	    url         => $_->href,
	    title       => $_->description,
	    description => $_->extended,
	    tags        => $_->tags,
	};

	utf8::decode($ret->{$_->href}->{url});
	utf8::decode($ret->{$_->href}->{title});
	utf8::decode($ret->{$_->href}->{description});
	utf8::decode($ret->{$_->href}->{tags});

    }

    return $ret;
}

sub add {
    my $self = shift;
    my $obj  = shift;

    $self->{obj}->add_post({
	url => $obj->{url},
	description => $obj->{title},
	extended => $obj->{description},
	tags => $obj->{tags},
	dt => $obj->{issued},
    });
}

sub delete {
    my $self = shift;
}

1;
__END__
