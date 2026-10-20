# The oracle the Skyfield author tests ask: reads one JSON list of jobs on
# stdin, writes one JSON list of answers on stdout. Instants are POSIX
# seconds (UTC, leap seconds not counted). The ephemeris is DE421, found in
# the directory named by the first argument. Run with python -I.
import json, sys
from datetime import datetime, timezone
from skyfield import almanac
from skyfield.api import Loader, wgs84
from skyfield.framelib import ecliptic_frame

load = Loader(sys.argv[1], verbose=False)
eph = load('de421.bsp')
ts = load.timescale()
earth, sun, moon = eph['earth'], eph['sun'], eph['moon']

# Not ts.utc(1970, 1, 1, 0, 0, e): that keeps 1970's leap seconds, so an
# instant after 2017 reaches Skyfield 27 s early. A position job carries its
# own TT as jde, so the ephemerides are compared with Delta T left out.
def t_of(e):
    return ts.from_datetime(datetime.fromtimestamp(e, timezone.utc))

def t_job(job):
    return ts.tt_jd(job['jde']) if 'jde' in job else t_of(job['epoch'])

def e_of(t):
    return t.utc_datetime().timestamp()

def _star(job):
    from skyfield.api import Star
    return Star(ra_hours=job['ra'] / 15.0, dec_degrees=job['dec'],
                ra_mas_per_year=job['pmra'] * 1000.0, dec_mas_per_year=job['pmdec'] * 1000.0,
                parallax_mas=job['plx'] * 1000.0, radial_km_per_s=job['rv'])

def events(job):
    place = earth + wgs84.latlon(job['lat'], job['lon'])
    if job['body'] == 'star' or job['body'] in PLANETS:
        return planet_events(job, place)
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

def crossings(job):
    # horizon_degrees given: the centre's geometric altitude, as this dist's
    # crossings take it
    place = earth + wgs84.latlon(job['lat'], job['lon'])
    t0, t1 = t_of(job['start']), t_of(job['end'])
    out = []
    t, ok = almanac.find_risings(place, sun, t0, t1, horizon_degrees=job['altitude'])
    out += [['rising', e_of(x)] for x, y in zip(t, ok) if y]
    t, ok = almanac.find_settings(place, sun, t0, t1, horizon_degrees=job['altitude'])
    out += [['setting', e_of(x)] for x, y in zip(t, ok) if y]
    return sorted(out, key=lambda r: r[1])

def sunpos(job):
    ra, dec, distance = earth.at(t_job(job)).observe(sun).apparent().radec(epoch='date')
    return [ra.hours * 15.0, dec.degrees, distance.au]

PLANETS = {'mercury': 'mercury', 'venus': 'venus', 'mars': 'mars',
           'jupiter': 'jupiter barycenter', 'saturn': 'saturn barycenter',
           'uranus': 'uranus barycenter', 'neptune': 'neptune barycenter',
           'pluto': 'pluto barycenter'}

def planet_events(job, place):
    # a planet or a star is a point: its centre's geometric altitude at -34
    # arcminutes
    body = _star(job) if job['body'] == 'star' else eph[PLANETS[job['body']]]
    t0, t1 = t_of(job['start']), t_of(job['end'])
    out = []
    t, ok = almanac.find_risings(place, body, t0, t1, horizon_degrees=-34.0 / 60.0)
    out += [['rise', e_of(x)] for x, y in zip(t, ok) if y]
    t, ok = almanac.find_settings(place, body, t0, t1, horizon_degrees=-34.0 / 60.0)
    out += [['set', e_of(x)] for x, y in zip(t, ok) if y]
    out += [['transit', e_of(x)] for x in almanac.find_transits(place, body, t0, t1)]
    return sorted(out, key=lambda r: r[1])

def _lonlat(body, t):
    lat, lon, d = earth.at(t).observe(body).apparent().frame_latlon(ecliptic_frame)
    return lon.degrees, lat.degrees, d.au

def configs(job):
    # the planet's apparent longitude less the sun's, its zeros and 180s; the
    # greatest elongations (the separation's maxima); the stations (the
    # longitude's motion changing sign)
    import numpy
    from skyfield.searchlib import find_discrete, find_maxima
    body = eph[PLANETS[job['planet']]]
    t0, t1 = ts.tt_jd(job['jde0']), ts.tt_jd(job['jde1'])
    out = []
    def dl(t):
        lp, _, _ = _lonlat(body, t)
        ls, _, _ = _lonlat(sun, t)
        return (lp - ls) % 360.0
    def half(t):
        return (dl(t) // 180.0).astype(int)
    half.step_days = 5.0
    t, y = find_discrete(t0, t1, half)
    for x in t:
        d = dl(x)
        dd = float(min(d, 360.0 - d))
        _, _, dp = _lonlat(body, x)
        _, _, ds = _lonlat(sun, x)
        if abs(float(d) - 180.0) < 90.0:
            out.append(['opposition', float(x.tt)])
        elif job['planet'] in ('mercury', 'venus'):
            out.append(['inferior_conjunction' if dp < ds else 'superior_conjunction', float(x.tt)])
        else:
            out.append(['conjunction', float(x.tt)])
    if job['planet'] in ('mercury', 'venus'):
        def sep(t):
            return earth.at(t).observe(body).apparent().separation_from(earth.at(t).observe(sun).apparent()).degrees
        sep.step_days = 2.0
        t, v = find_maxima(t0, t1, sep)
        for x in t:
            d = float(dl(x))
            out.append(['greatest_elongation_east' if d < 180.0 else 'greatest_elongation_west', float(x.tt)])
    def moving(t):
        a, _, _ = _lonlat(body, ts.tt_jd(t.tt - 0.125))
        b, _, _ = _lonlat(body, ts.tt_jd(t.tt + 0.125))
        return (((b - a + 180.0) % 360.0 - 180.0) > 0).astype(int)
    moving.step_days = 3.0
    t, y = find_discrete(t0, t1, moving)
    for x, v in zip(t, y):
        out.append(['station_direct' if v == 1 else 'station_retrograde', float(x.tt)])
    return sorted(out, key=lambda r: r[1])

def approach(job):
    from skyfield.searchlib import find_minima
    names = {'sun': sun, 'moon': moon}
    a = names.get(job['a']) or eph[PLANETS[job['a']]]
    b = names.get(job['b']) or eph[PLANETS[job['b']]]
    where = earth + wgs84.latlon(job['lat'], job['lon']) if 'lat' in job else earth
    def sep(t):
        o = where.at(t)
        return o.observe(a).apparent().separation_from(o.observe(b).apparent()).degrees
    sep.step_days = 0.25 if 'moon' in (job['a'], job['b']) else 1.0
    t, v = find_minima(t_of(job['start']), t_of(job['end']), sep)
    return [[e_of(x), float(y)] for x, y in zip(t, v)]

def planetpos(job):
    from skyfield.magnitudelib import planetary_magnitude
    astrometric = earth.at(t_job(job)).observe(eph[PLANETS[job['planet']]])
    ra, dec, distance = astrometric.apparent().radec(epoch='date')
    mag = None
    if job['planet'] != 'pluto':
        m = float(planetary_magnitude(astrometric))
        mag = None if m != m else m
    return [ra.hours * 15.0, dec.degrees, distance.au, astrometric.light_time * 86400.0, mag]

def planetmag(job):
    # Skyfield's own formulae, on this dist's distances and angles: a check of
    # the transcription, not of the geometry.
    from skyfield import magnitudelib as m
    p, r, d, i = job['planet'], job['r'], job['delta'], job['phase']
    if p == 'saturn':
        v = m._saturn_magnitude(r, d, i, job['sun_lat'], job['obs_lat'])
    elif p == 'uranus':
        v = m._uranus_magnitude(r, d, i, job['sun_lat'], job['obs_lat'])
    elif p == 'neptune':
        v = m._neptune_magnitude(r, d, i, job['year'])
    else:
        v = getattr(m, '_%s_magnitude' % p)(r, d, i)
    v = float(v)
    return None if v != v else v

def planetphase(job):
    # The phase angle and the distance from the sun with the sun's own place,
    # not the barycentre's: the planet at the time its light left.
    t = t_job(job)
    a = earth.at(t).observe(eph[PLANETS[job['planet']]])
    tl = ts.tt_jd(t.tt - a.light_time)
    sp = (eph[PLANETS[job['planet']]] - sun).at(tl).position.au
    ep = (earth - sun).at(t).position.au
    import numpy
    op = sp - ep
    r = float(numpy.linalg.norm(sp))
    c = float(numpy.dot(sp, op) / (r * numpy.linalg.norm(op)))
    out = [r, float(numpy.degrees(numpy.arccos(max(-1.0, min(1.0, c)))))]
    if job['planet'] in ('saturn', 'uranus'):
        # the planetocentric latitudes of the sun and the earth, from
        # Skyfield's ICRF poles, as its magnitudes take them
        from skyfield import magnitudelib as m
        from skyfield.functions import angle_between
        pole = m._SATURN_POLE if job['planet'] == 'saturn' else m._URANUS_POLE
        out += [float(numpy.degrees(angle_between(pole, sp))) - 90.0,
                float(numpy.degrees(angle_between(pole, op))) - 90.0]
    return out

def starpos(job):
    # the same catalogue numbers in Skyfield's Star: its rigorous place, IAU
    # 2006/2000A precession and nutation
    st = _star(job)
    out = []
    for jde in job['jdes']:
        ra, dec, _ = earth.at(ts.tt_jd(jde)).observe(st).apparent().radec(epoch='date')
        out.append([ra.hours * 15.0, dec.degrees])
    return out

def moon_constellations(job):
    from skyfield.api import load_constellation_map
    where = load_constellation_map()
    return [str(where(earth.at(t_of(e)).observe(moon).apparent())) for e in job['epochs']]

def seasons(job):
    t, y = almanac.find_discrete(ts.utc(job['year'], 1, 1), ts.utc(job['year'] + 1, 1, 1), almanac.seasons(eph))
    return [[int(k), e_of(x)] for x, k in zip(t, y)]

def phases(job):
    t, y = almanac.find_discrete(t_of(job['from']), t_of(job['to']), almanac.moon_phases(eph))
    return [[int(k), e_of(x)] for x, k in zip(t, y)]

def moonpos(job):
    ra, dec, distance = earth.at(t_job(job)).observe(moon).apparent().radec(epoch='date')
    return [ra.hours * 15.0, dec.degrees, distance.km]

answers = []
for job in json.load(sys.stdin):
    answers.append({'events': events, 'crossings': crossings, 'seasons': seasons, 'phases': phases, 'moonpos': moonpos, 'sunpos': sunpos, 'planetpos': planetpos, 'planetmag': planetmag, 'planetphase': planetphase, 'configs': configs, 'approach': approach, 'starpos': starpos, 'moon_constellations': moon_constellations}[job['kind']](job))
json.dump(answers, sys.stdout)
