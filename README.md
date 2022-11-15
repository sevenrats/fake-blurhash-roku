# fake-blurhash-roku

Not exactly an implementation of Dag Agren's Blurhash Decoder for Roku

This implementation is designed to overcome several difficulties implicit in the Roku platform.  Rokus in general lack the power to decode blurhashes in the traditional manner.  Unfortunately, they also lack gaussian blur, which is normally necessary for fake-blurhash.  This implementation overcomes those issues by using the Roku scaler instead of gaussian blur, writing bmp's in the filesystem "by hand" using the output of a fake-blurhash decode.  Try it.  The renders are unique, beautiful, and usable.  For the 20-element blurhashes tested, rendering takes between 14-17 milliseconds on a 2021 4K Stick.