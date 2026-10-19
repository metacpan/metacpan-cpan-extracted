# The oracle the Skyfield author tests ask: reads one JSON list of jobs on
# stdin, writes one JSON list of answers on stdout. Instants are POSIX
# seconds (UTC, leap seconds not counted). The ephemeris is DE421, found in
# the directory named by the first argument. Run with python -I.
import json, sys
from skyfield import almanac
from skyfield.api import Loader, wgs84

load = Loader(sys.argv[1], verbose=False)
eph = load('de421.bsp')
ts = load.timescale()
earth, sun, moon = eph['earth'], eph['sun'], eph['moon']

def t_of(e):
    return ts.utc(1970, 1, 1, 0, 0, e)

def e_of(t):
    return t.utc_datetime().timestamp()

def events(job):
    place = earth + wgs84.latlon(job['lat'], job['lon'])
    body = sun if job['body'] == 'sun' else moon
    t0, t1 = t_of(job['start']), t_of(job['end'])
    out = []
    t, ok = almanac.find_risings(place, body, t0, t1)
    out += [['rise', e_of(x)] for x, y in zip(t, ok) if y]
    t, ok = almanac.find_settings(place, body, t0, t1)
    out += [['set', e_of(x)] for x, y in zip(t, ok) if y]
    out += [['transit', e_of(x)] for x in almanac.find_transits(place, body, t0, t1)]
    if job['body'] == 'sun':
        t, ok = almanac.find_risings(place, body, t0, t1, horizon_degrees=-6.0)
        out += [['dawn', e_of(x)] for x, y in zip(t, ok) if y]
        t, ok = almanac.find_settings(place, body, t0, t1, horizon_degrees=-6.0)
        out += [['dusk', e_of(x)] for x, y in zip(t, ok) if y]
    return sorted(out, key=lambda r: r[1])

def seasons(job):
    t, y = almanac.find_discrete(ts.utc(job['year'], 1, 1), ts.utc(job['year'] + 1, 1, 1), almanac.seasons(eph))
    return [[int(k), e_of(x)] for x, k in zip(t, y)]

def phases(job):
    t, y = almanac.find_discrete(t_of(job['from']), t_of(job['to']), almanac.moon_phases(eph))
    return [[int(k), e_of(x)] for x, k in zip(t, y)]

def moonpos(job):
    ra, dec, distance = earth.at(t_of(job['epoch'])).observe(moon).apparent().radec(epoch='date')
    return [ra.hours * 15.0, dec.degrees, distance.km]

answers = []
for job in json.load(sys.stdin):
    answers.append({'events': events, 'seasons': seasons, 'phases': phases, 'moonpos': moonpos}[job['kind']](job))
json.dump(answers, sys.stdout)
