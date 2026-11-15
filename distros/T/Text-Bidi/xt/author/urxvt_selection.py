#!/usr/bin/env python3
"""Check urxvt selection pixels and PRIMARY text on a private Xvfb display.

Example after building Text::Bidi:
    PERL5LIB=blib/lib:blib/arch python3 xt/author/urxvt_selection.py

TEXT_BIDI_XVFB can select an Xvfb binary outside PATH. No desktop is used.
"""
from pathlib import Path
import ctypes as C
import json
import os
import select
import shutil
import tempfile
import subprocess as S
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
# Optional author test: Python 3, urxvt, Xvfb, xclip, libX11 and libXtst.
# Run from a built checkout with PERL5LIB pointing at its blib directories.
XVFB = os.environ.get('TEXT_BIDI_XVFB') or shutil.which('Xvfb')
if not XVFB:
    raise SystemExit('Xvfb is required; install it or set TEXT_BIDI_XVFB to its executable')
work_dir = tempfile.TemporaryDirectory(prefix='text-bidi-urxvt-')
WORK = Path(work_dir.name)
LINE = 'משמר הבחירות האזרח│השיבוצים נפתחים בימים הקרובים - עוד לא הצטרפת לווט        │ '
WORD = 'נפתחים'
x = C.CDLL('libX11.so.6')
test = C.CDLL('libXtst.so.6')
x.XOpenDisplay.argtypes = [C.c_char_p]
x.XOpenDisplay.restype = C.c_void_p
x.XDefaultRootWindow.argtypes = [C.c_void_p]
x.XDefaultRootWindow.restype = C.c_ulong
x.XTranslateCoordinates.argtypes = [C.c_void_p, C.c_ulong, C.c_ulong, C.c_int, C.c_int, C.POINTER(C.c_int), C.POINTER(C.c_int), C.POINTER(C.c_ulong)]
x.XFlush.argtypes = [C.c_void_p]
x.XCloseDisplay.argtypes = [C.c_void_p]
x.XGetImage.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_int, C.c_uint, C.c_uint, C.c_ulong, C.c_int]
x.XGetImage.restype = C.c_void_p
x.XGetPixel.argtypes = [C.c_void_p, C.c_int, C.c_int]
x.XGetPixel.restype = C.c_ulong
x.XDestroyImage.argtypes = [C.c_void_p]
test.XTestFakeMotionEvent.argtypes = [C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_ulong]
test.XTestFakeButtonEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
processes = []
display = None
server_dir = tempfile.TemporaryDirectory(prefix='text-bidi-xvfb-')
server_binary = Path(server_dir.name) / 'Xvfb'
shutil.copyfile(XVFB, server_binary)
server_binary.chmod(0o700)
try:
    server_log = (WORK / 'xvfb.log').open('w')
    server = S.Popen([str(server_binary), '-displayfd', '1', '-screen', '0', '1280x800x24', '-nolisten', 'tcp', '-ac'], stdout=S.PIPE, stderr=server_log, text=True)
    processes.append(server)
    if not select.select([server.stdout], [], [], 10)[0]:
        raise RuntimeError('Xvfb did not become ready: ' + (WORK / 'xvfb.log').read_text())
    number = server.stdout.readline().strip()
    if not number.isdigit():
        raise RuntimeError('Xvfb startup failed: ' + (WORK / 'xvfb.log').read_text())
    env = dict(os.environ, DISPLAY=':' + number, LC_ALL='C.UTF-8', BIDI_REPRO_INFO=str(WORK / 'info.json'), PERL5LIB=os.environ.get('PERL5LIB', str(ROOT / 'blib/lib') + ':' + str(ROOT / 'blib/arch')))
    (WORK / 'info.json').unlink(missing_ok=True)
    (WORK / 'live-probe').write_text("""
use JSON::PP qw(encode_json);
sub on_start {
    my ($self) = @_;
    my $path = $ENV{BIDI_REPRO_INFO};
    open my $fh, '>', "$path.tmp" or die $!;
    print {$fh} encode_json({vt => $self->vt, fw => $self->fwidth, fh => $self->fheight});
    close $fh;
    rename "$path.tmp", $path or die $!;
    ()
}
""")
    terminal_log = (WORK / 'urxvt.log').open('w')
    terminal = S.Popen(['urxvt', '-display', env['DISPLAY'], '-geometry', '80x5+10+10', '-b', '0', '-w', '0', '+sb', '-bg', 'white', '-fg', 'black', '-hc', 'blue', '-fn', 'xft:DejaVu Sans Mono:pixelsize=16', '-title', 'bidi-repro', '--perl-lib', str(ROOT / 'misc') + ':' + str(WORK), '-perl-ext-common', '', '-pe', 'bidi,live-probe', '-e', sys.executable, '-c', 'import sys,time; sys.stdout.write(' + repr(LINE + '\r\n') + '); sys.stdout.flush(); time.sleep(30)'], env=env, stderr=terminal_log)
    processes.append(terminal)
    deadline = time.monotonic() + 10
    while not (WORK / 'info.json').exists():
        if terminal.poll() is not None or time.monotonic() > deadline:
            raise RuntimeError('urxvt startup failed: ' + (WORK / 'urxvt.log').read_text())
        time.sleep(.05)
    time.sleep(.5)
    info = json.loads((WORK / 'info.json').read_text())
    display = x.XOpenDisplay(env['DISPLAY'].encode())
    if not display:
        raise RuntimeError('Cannot connect to private X server')
    root = x.XDefaultRootWindow(display)
    left, top, child = C.c_int(), C.c_int(), C.c_ulong()
    x.XTranslateCoordinates(display, info['vt'], root, 0, 0, C.byref(left), C.byref(top), C.byref(child))
    fw, fh = info['fw'], info['fh']
    def move(col):
        test.XTestFakeMotionEvent(display, 0, left.value + col * fw + fw // 2, top.value + fh // 2, 0)
        x.XFlush(display)
        time.sleep(.1)
    expected = list(range(62, 68))
    def highlighted_columns():
        time.sleep(.2)
        image = x.XGetImage(display, info['vt'], 0, 0, 80 * fw, fh, C.c_ulong(-1).value, 2)
        if not image:
            raise RuntimeError('Cannot read terminal pixels')
        try:
            return [col for col in range(80)
                    if (x.XGetPixel(image, col * fw + 1, 1) & 0xffffff) == 0x0000ff]
        finally:
            x.XDestroyImage(image)

    def button(pressed):
        test.XTestFakeButtonEvent(display, 1, int(pressed), 0)
        x.XFlush(display)
        time.sleep(.1)

    def copied_text():
        return S.run(['xclip', '-display', env['DISPLAY'], '-selection', 'primary', '-o'],
                     capture_output=True, timeout=3, check=True).stdout.decode()

    def check(label):
        highlighted = highlighted_columns()
        print(label + ' highlight columns:', highlighted, flush=True)
        assert highlighted == expected, (label, highlighted, expected)
        button(False)
        copied = copied_text()
        print(label + ' copied text:', ascii(copied), flush=True)
        assert copied == WORD, (label, ascii(copied), ascii(WORD))
        assert highlighted_columns() == expected, label + ' highlight changed after release'

    # FriBidi displays the reported word in columns 62 through 67.
    move(62)
    button(True)
    move(68)
    check('forward drag')
    move(68)
    button(True)
    move(62)
    check('backward drag')
    move(65)
    button(True)
    button(False)
    button(True)
    check('double click')
    print('PASS: real urxvt highlights and copies the reported word')

finally:
    if display:
        x.XCloseDisplay(display)
    for process in reversed(processes):
        process.terminate()
        try:
            process.wait(timeout=3)
        except S.TimeoutExpired:
            process.kill()
            process.wait()

    server_dir.cleanup()
    work_dir.cleanup()
