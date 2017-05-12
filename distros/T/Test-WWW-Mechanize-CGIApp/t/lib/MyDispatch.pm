package MyDispatch;

use base 'CGI::Application::Dispatch';

sub dispatch_args {

  return {
          table => [
		    ':app'      => {},
                    ':app/:rm'  => {},
                   ],
         };
}

1;
