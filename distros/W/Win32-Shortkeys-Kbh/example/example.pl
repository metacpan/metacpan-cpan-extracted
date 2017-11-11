use lib qw(../lib ../blib/arch/auto/Win32/Shortkeys/Kbh);
#use blib;
use strict;
use warnings;
#use Time::HiRes qw(usleep);
use Win32::Shortkeys::Kbh qw(:hook :input VK_BACK VK_TAB);
set_key_processor(sub {
        my ($cup, $code, $alt, $ext) = @_;
        print "process_key in perl cup: $cup code: $code alt: $alt ext: $ext \n";
        return if $cup == 0 ;
        
        if ($code == 123) { 
            unregister_hook(); 
            quit();
        }

        if ($code == 83) { 
            #use usleep for shorter time;
            sleep 1;
             unregister_hook();
             send_cmd(1, VK_BACK);
             send_string("You hit the s key !!!");
             register_hook();
        }
    
    });
register_hook();
msg_loop();

