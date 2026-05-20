import gi
gi.require_version('Gst', '1.0')
gi.require_version('GstApp', '1.0')
from gi.repository import Gst, GstApp

Gst.init(None)

# parse_launch builds a pipeline from a description string; appsink lets
# us pull encoded buffers back into Python.
pipeline = Gst.parse_launch(
    "videotestsrc num-buffers=10 ! "
    "video/x-raw,width=1280,height=720,framerate=30/1,format=I420 ! "
    "nvvidconv ! "
    "video/x-raw(memory:NVMM),format=NV12 ! "
    "nvv4l2h264enc ! "
    "h264parse ! "
    "pylogger ! "
    "appsink name=sink sync=false"
)

sink = pipeline.get_by_name("sink")
pipeline.set_state(Gst.State.PLAYING)

count = 0
while True:
    sample = sink.try_pull_sample(Gst.SECOND)
    if sample is None:
        break
    buf = sample.get_buffer()
    ok, info = buf.map(Gst.MapFlags.READ)
    if ok:
        count += 1
        print(f"frame {count:2d}: {info.size:6d} bytes, pts={buf.pts}")
        buf.unmap(info)

pipeline.set_state(Gst.State.NULL)
print(f"\nPulled {count} hardware-encoded H.264 frames into Python.")
assert count == 10, f"expected 10 frames, got {count}"