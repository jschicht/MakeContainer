Tool to transform a VeraCrypt container into a masked raw video file. The tool will generate a valid yuv file of the encrypted bytes. Just choose the wanted pixel format of the video file. Since this file format does not have any header, all we need to do is to append some bytes at the end in order to align the file size to match the expected size based on the pixel format chosen.

Some examples for how to play such a file.
vlc --demux rawvideo --rawvid-fps 25 --rawvid-width 320 --rawvid-height 240 --rawvid-chroma I420 file_320x240_rgba.yuv
ffplay -f rawvideo -pixel_format rgba -video_size 320x240 -framerate 25 file_320x240_rgba.yuv
Or this gui tool; https://sourceforge.net/projects/raw-yuvplayer/

What will the video look like?
It will look like random!

So in the end it's just about playing some random binary data as raw video.

This tool is thus not made for my patched VeraCrypt, but the lagacy version.