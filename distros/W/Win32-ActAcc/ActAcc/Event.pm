# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::Event;

use Time::HiRes;

use overload ( '""'=>\&evDescribe );

sub getAO
{
	my $self = shift;
    my $rv = Win32::ActAcc::AccessibleObjectFromEvent
          ($$self{'hwnd'}, $$self{'idObject'}, $$self{'idChild'});
    return $rv;
}

sub AccessibleObjectFromEvent
{
	my $self = shift;
	return Win32::ActAcc::AccessibleObjectFromEvent($$self{'hwnd'}, $$self{'idObject'}, $$self{'idChild'});
}

sub evDescribe
{
	my $e = shift;

	my $L = Win32::ActAcc::EventConstantName($$e{'event'});
	if ($L eq "") { $L=sprintf("event(%lx)", $$e{'event'}); }
	my $ao = $e->getAO();
	if (defined($ao))
	{
		$L = $L . ' ' . $ao->describe();
	}
	else
	{
		if (0 != $$e{'hwnd'})
		{
			$L = $L . ' ' . sprintf("hwnd:%08lx", $$e{'hwnd'});
		}
	}
	my $objname = Win32::ActAcc::ObjectIdConstantName($$e{'idObject'});
	if (defined($objname))
	{
		$L = $L . " $objname";
	}
	else
	{
		$L = $L . ' ' . sprintf("idObject:%d", $$e{'idObject'});
	}
	if (!defined($ao))
	{
		$L = $L . ' ' . sprintf("idChild:%d", $$e{'idChild'});
	}
	if (exists($$e{'hWinEventHook'}))
	{
		$L = $L . ' ' . sprintf("hook:%08x", $$e{'hWinEventHook'});
	}
	return $L;
}

package Win32::ActAcc::EventMonitor;

my $EventPollInterval = 0.5; # seconds 
my $HOURGLASS_EXTENSION_SECONDS = 10; # seconds

sub waitForEvent
{
	my $self = shift;
	my $pQuarry = shift;
    my $options = shift; # optional HASH { 'timeout'=>seconds, 'trace'=>1 }

    # grandfather original form in which $options was just the number of seconds:
    if (defined($options) && !ref($options))
      {
        $options = +{'timeout'=>$options};
      }

    if (!defined($options))
      {
        $options = +{};
      }

	my $timeoutSecs = $$options{'timeout'}; 

	my $maxIters = defined($timeoutSecs) ? $timeoutSecs / $EventPollInterval : undef;

    #print "waitForEvent: timeoutSecs=$timeoutSecs maxIters=$maxIters\n";

	my $pComparator;
	if (ref($pQuarry) eq 'HASH')
	{
		# rename hwnd as HWND. Deprecate the lowercase.
		if (exists($$pQuarry{'hwnd'}))
		{
			$$pQuarry{'HWND'} = $$pQuarry{'hwnd'};
			delete $$pQuarry{'hwnd'};
		}
		
		# todo - optimize by bubbling HWND match criterion outward 
        # (from AO to event level) so there is just one place to look for it.
		$pComparator = sub{waitForEvent_dfltComparator($pQuarry, @_)};
	}
	else
	{
		$pComparator = $pQuarry;
	}
	
    # Prepare to watch for changes in the "name" of the cursor.
    my $hourglassComparator = 
      sub 
        { 
          waitForEvent_dfltComparator
            ( 
             +{
               'event'=>Win32::ActAcc::EVENT_OBJECT_NAMECHANGE(),
               'ao_profile'=>+{ 'get_accRole'=>Win32::ActAcc::ROLE_SYSTEM_CURSOR() }
              }, @_
            ) 
          };

	my $rv; 

    my $hourglass_trumpet_iter = -1;
    my $orig_maxIters = $maxIters;

	PATIENTLY_AWAITING_QUARRY: for (my $sc = 0; !defined($maxIters) || ($sc <= $maxIters); $sc++)
	{
      if ($sc == $hourglass_trumpet_iter)
        {
           print STDERR "Cursor name change: extending waitForEvent timeout\n";
        }

		DEVOUR_BACKLOG: for (;;)
		{
			my $e = $self->getEvent();
			last DEVOUR_BACKLOG unless defined($e);

            if ($$options{'trace'})
              {
                # display event, unless it might be a result of our displaying events.
                print Win32::ActAcc::Event::evDescribe($e)."\n"
                  unless ($$e{'event'}==Win32::ActAcc::EVENT_CONSOLE_UPDATE_REGION() ||
                          $$e{'event'}==Win32::ActAcc::EVENT_CONSOLE_UPDATE_SCROLL() ||
                          $$e{'event'}==Win32::ActAcc::EVENT_CONSOLE_CARET());
              }

			last PATIENTLY_AWAITING_QUARRY if (defined($rv = &$pComparator($e)));

         if ($maxIters && defined(&$hourglassComparator($e)))
         {
           my $newmax = $sc + ($HOURGLASS_EXTENSION_SECONDS / $EventPollInterval);
             if ($newmax > $maxIters)
               {
                 $maxIters = $newmax;
               }
           $hourglass_trumpet_iter = $orig_maxIters;
         }
		}
		select(undef,undef,undef,$EventPollInterval) unless ($sc == (defined($maxIters)?$maxIters:-1));
	}
	return $rv;
}

    sub waitForEvent_dfltComparator
      {
        my $pQuarry = shift;
        my $e = shift;

        if (ref($pQuarry) eq 'CODE') {
          return &$pQuarry($e);
        } else {
          if (exists($$pQuarry{'event'})) {
			return undef unless $$e{'event'} == $$pQuarry{'event'};
          }

          if (exists($$pQuarry{'hwnd'})) {
			return undef unless $$e{'hwnd'} == $$pQuarry{'hwnd'};
          }

          my $ao = $e->getAO();
          # note: undef if the window is being destroyed

          if (exists($$pQuarry{'ao_profile'})) {
            return undef unless defined($ao);
            my $mr = $ao->match($$pQuarry{'ao_profile'});
	        return undef unless $mr;
          }

          if (exists($$pQuarry{'role'})) {
            return undef unless defined($ao);
            my $mr = $ao->get_accRole();
	        return undef unless $mr == $$pQuarry{'role'};
          }

          if (exists($$pQuarry{'name'})) {
            return undef unless defined($ao);
		    my $aoname = $ao->get_accName();
		    if ('Regexp' eq ref($$pQuarry{'name'})) {
              return undef unless defined($aoname) 
				&& ($aoname =~ /$$pQuarry{'name'}/);
		    } else {
              return undef unless defined($aoname) 
				&& $aoname eq $$pQuarry{'name'};
		    }
          }

          if (exists($$pQuarry{'aoToEqual'})) {
            return undef unless defined($ao);
            return undef unless $ao->Equals($$pQuarry{'aoToEqual'});
          }

          # has 'return', must be last
          if (exists($$pQuarry{'code'})) {
            return &{$$pQuarry{'code'}}($e) ;
          }

          return $ao;
        }
      }

sub debug_spin
{
	my $self = shift;
	my $secs = shift;

	$self->waitForEvent(
		sub {
			my $e = shift;
			# display event, BUT do not display events that RESULT from our displaying events.
			print Win32::ActAcc::Event::evDescribe($e)."\n"
				unless ($$e{'event'}==Win32::ActAcc::EVENT_CONSOLE_UPDATE_REGION() ||
					$$e{'event'}==Win32::ActAcc::EVENT_CONSOLE_UPDATE_SCROLL() ||
					$$e{'event'}==Win32::ActAcc::EVENT_CONSOLE_CARET());
			undef
		}, $secs);
}

sub eventLoop
{
    my $self = shift;
    my $pQuarryList = shift;
    my $timeoutSecs = shift; # optional
    my $returnCritAndEvent = shift; # optional

    my $maxIters = defined($timeoutSecs) ? $timeoutSecs / $EventPollInterval : undef;

    # make quarry an array if it is not an array.
    if ('ARRAY' ne ref($pQuarryList))
    {
        $pQuarryList = +[ $pQuarryList ];
    }

    my $rv; 

    PATIENTLY_AWAITING_QUARRY: for (my $sc = 0; !defined($maxIters) || ($sc <= $maxIters); $sc++)
    {
	    DEVOUR_BACKLOG: for (;;)
	    {
		    my $e = $self->getEvent();
		    last DEVOUR_BACKLOG unless defined($e);
                    my @m = grep(waitForEvent_dfltComparator($_, $e), @$pQuarryList);
                    if (@m)
                    {
						my $occasion = shift(@m);
                        $rv = $returnCritAndEvent ? +{'event'=>$e, 'occasion'=>$occasion} : $occasion;
                        last PATIENTLY_AWAITING_QUARRY;
                    }
	    }
	    select(undef,undef,undef,$EventPollInterval) unless ($sc == (defined($maxIters)?$maxIters:-1));
    }
    return $rv;
}

sub awaitCalm
  {
    my $AWAIT_CALM__CHECK_INTERVAL_SEC = 0.5;
    my $AWAIT_CALM__EVENT_QTY_MAX = 3;
    my $AWAIT_CALM__MAX_SEC = 5;

    my $eh = shift;
    my $max_sec = shift || $AWAIT_CALM__MAX_SEC;
    my $qume = $eh->getEventCount();
    for (my $i = 0; $i < $max_sec; $i+=$AWAIT_CALM__CHECK_INTERVAL_SEC)
      {
        Time::HiRes::sleep($AWAIT_CALM__CHECK_INTERVAL_SEC);
        my $ct = $eh->getEventCount();
        my $delta = $ct-$qume;
        $qume = $ct;
        return 1 if ($delta <= $AWAIT_CALM__EVENT_QTY_MAX);
      }

    return undef; # timeout
  }


1;
