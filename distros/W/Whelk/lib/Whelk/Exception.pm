package Whelk::Exception;
$Whelk::Exception::VERSION = '0.03';
use Kelp::Base 'Kelp::Exception';

# hint (string) to send to the user. App won't create a log if hint is present.
attr -hint => undef;

1;

