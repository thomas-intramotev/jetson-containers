#!/opt/venv/bin/python3

try:
    print('  TESTING gst-python bindings...')
    import gi
    gi.require_version('Gst', '1.0')
    from gi.repository import GObject, Gst
except Exception as e:
    print('  gst-python bindings not working:')
    print(e)
    exit(1)

print('  SUCCESS gst-python bindings')
print('  TESTING gst-python gi overrides...')

Gst.init(None)

overrides = ['Fraction', 'IntRange', 'DoubleRange', 'Bitmask']
try:
    assert(all([hasattr(Gst, o) for o in overrides]))
except AssertionError:
    print('  gst-python gi overrides not working:')
    for o in overrides:
        if not hasattr(Gst, o):
            print(f'Missing Gst.{o}')
    exit(1)

print('  SUCCESS gst-python gi overrides')