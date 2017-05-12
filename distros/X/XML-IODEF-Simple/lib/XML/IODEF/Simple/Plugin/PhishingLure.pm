package XML::IODEF::Simple::Plugin::PhishingLure;

use XML::IODEF::Simple::Plugin::Email;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    return unless($info->{'impact'} =~ /^phish/);
    return unless(XML::IODEF::Simple::Plugin::Email->prepare($info));
    return(1);
}


sub convert {
    my $class = shift;
    my $info = shift;
    my $iodef = shift;

    $info->{'impact'} = 'phishing lure';

    return($iodef);
}

1;

