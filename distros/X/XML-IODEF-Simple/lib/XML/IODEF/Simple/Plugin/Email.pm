package XML::IODEF::Simple::Plugin::Email;

use Regexp::Common qw/URI/;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    my $address = $info->{'address'};
    return unless(isEmail($address));
    return(1);
}

sub convert {
    my $self = shift;
    my $info = shift;
    my $iodef = shift;

    my $address = $info->{'address'};
    return unless(isEmail($address));

    $iodef->add('IncidentEventDataFlowSystemNodeAddresscategory','e-mail');
    $iodef->add('IncidentEventDataFlowSystemNodeAddress',$address);
    return $iodef;
}

sub isEmail {
    my $e = shift;
    return unless($e);
    return if($e =~ /^$RE{'URI'}/);
    return if($e =~ /^$RE{'URI'}{'HTTP'}{-scheme => 'https'}$/);
    return unless(lc($e) =~ /[a-z0-9_.-]+\@[a-z0-9.-]+\.[a-z0-9.-]{2,5}/);
    return(1);
}

1;
