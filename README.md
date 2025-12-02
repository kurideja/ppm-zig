Inspired by Tsoding video on Youtube: https://youtu.be/xNX9H_ZkfNE?si=pcWCEQjS7dzNn13i

Used source code as a reference: https://gist.github.com/rexim/ef86bf70918034a5a57881456c0a0ccf

AI did help to figure out some discrepancies and implementation details.

It was the 2nd and 3rd day touching zig code. Mostly focusing on operations with vectors. Code is definitely not idiomatic and should not be used for teaching.

## Generate video

Generate frames in PPM format:
```sh
zig build run
```

Generate mp4:
```sh
ffmpeg -i output/output-%03d.ppm -r 60 output/output.mp4
```

./output.mp4
