
# A basic thread test

try:
    import thread
except:
    print "1..0"
    import sys
    sys.exit(0)

print "1..1"
import time
import perl

perl.eval("""
$| = 1;
print "Hello 0\n";
""")

t1_done = 0
t2_done = 0

def t1():
    global t1_done
    time.sleep(0.2)
    perl.eval("""print "Hello 1\n";""")
    time.sleep(0.7)
    perl.eval("""print "Hello 1 again\n";""")
    t1_done = 1

def t2():
    global t2_done
    time.sleep(0.75)
    perl.eval("""print "Hello 2\n";""")
    t2_done = 1 #perl.eval("time")
    

thread.start_new_thread(t1, ())
thread.start_new_thread(t2, ())

# Main thread just waits for both children to terminate
count = 0
while not (t1_done and t2_done):
    time.sleep(0.1)
    count = count + 1
    if count > 100:
        break
    print ".",

print t1_done, t2_done

if count > 100: print "not ",
print "ok 1"

