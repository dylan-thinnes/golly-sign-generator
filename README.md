Given a PPM P6 image, generates an image of a glider gun that
[life-framebuffer](https://github.com/dylan-thinnes/life-framebuffer) can run to
produce the same original image in the form of LWSS gliders!

For example the following new year sign generated from `hoard-of-bitfonts/msx/msx-japanese-a1gt.yaff`:
![new year sign source](/new-year-sign-source.jpg)
is then turned to the following initial life state (using `image-to-games`):
![new year sign initial state](/new-year-sign-game.jpg)
to run on a monitor in real life (using `life-framebuffer`):
![new year sign running](/new-year-sign-real-life.jpg)

Requires Golly, Python3 with opencv2, and gcc, and the incredible
[monobit](https://github.com/robhagemans/monobit).

Made for [Edinburgh Hacklab](https://ehlab.uk).

Another generated rgb/cmyk sign running on a monitor:
![generated rgb/cmyk sign running on a monitor](/rgbcmyk-sign.jpg)
