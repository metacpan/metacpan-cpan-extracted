import perl
if perl.MULTI_PERL:
	print "1..0"
	raise SystemExit


try:
	import thread
except:
	print "1..0"
	print "Threads not supported by python"
	raise SystemExit

print "1..1"
import time

inc = perl.get_ref("@INC")
i0 = inc[0]

work_started = 0
work_done = 0

def wait():
    global work_started, work_done
    while not work_started:
        time.sleep(0.1)
    work_started = 0
    while not work_done:
        time.sleep(0.1)

def start():
    global work_started
    work_started = 1
    
def done():
    global work_done
    work_done = 1

def t1():
    start()
    global inc, i0
    if i0 != inc[0]: print "not",
    print "ok 1";
    done()

thread.start_new_thread(t1, ())
wait()
