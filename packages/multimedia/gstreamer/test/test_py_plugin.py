# A trivial passthrough element implemented in Python.
# Each buffer that passes through prints its PTS and size,
# proving the C->Python->C round-trip works.

import gi
gi.require_version('Gst', '1.0')
gi.require_version('GstBase', '1.0')
from gi.repository import Gst, GObject, GstBase


class PyLogger(GstBase.BaseTransform):
    __gstmetadata__ = (
        'Python Logger',                           # long name
        'Filter/Effect',                           # element classification
        'Logs buffer pts/size as buffers pass through',
        'You'
    )

    __gsttemplates__ = (
        Gst.PadTemplate.new(
            "src",
            Gst.PadDirection.SRC,
            Gst.PadPresence.ALWAYS,
            Gst.Caps.new_any(),
        ),
        Gst.PadTemplate.new(
            "sink",
            Gst.PadDirection.SINK,
            Gst.PadPresence.ALWAYS,
            Gst.Caps.new_any(),
        ),
    )

    def do_transform_ip(self, buf):
        print(
            f"[pylogger] pts={buf.pts} size={buf.get_size()}",
            flush=True,
        )
        return Gst.FlowReturn.OK


GObject.type_register(PyLogger)

__gstelementfactory__ = ("pylogger", Gst.Rank.NONE, PyLogger)