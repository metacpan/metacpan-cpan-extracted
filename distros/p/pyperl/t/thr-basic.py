
# A basic thread test

try:
    import _thread
except:
    print("1..0")
    import sys
    sys.exit(0)

print("1..1")
import time
import perl

perl.eval("""
$| = 1;
$a = "0";
""")

t1_done = 0
t2_done = 0

def t1():
    global t1_done
    time.sleep(0.2)
#    perl.eval("""print "Hello 1\n";""")
    perl.eval("""$a = "1a";""")
    time.sleep(0.7)
#    perl.eval("""print "Hello 1 again\n";""")
    perl.eval("""$a = "1b";""")
    t1_done = 1

def t2():
    global t2_done
    time.sleep(0.75)
#    perl.eval("""print "Hello 2\n";""")
    perl.eval("""$a = "2";""")
    t2_done = 1 #perl.eval("time")
    

_thread.start_new_thread(t1, ())
_thread.start_new_thread(t2, ())

# Main thread just waits for both children to terminate
count = 0
while not (t1_done and t2_done):
    time.sleep(0.1)
    count = count + 1
    if count > 100:
        break
#    print '.',

if count > 100: 
     print("not ", end=' ')
elif t1_done != 1 or t2_done != 1:
     print("not ", end=' ')
print("ok 1")

