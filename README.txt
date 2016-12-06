
Audio Feature Extractor 
with Processing.

This Processing sketch extracts some parameters of the song (or possibly of the audio input).

Send 63 parameters from audio analysis by OSC Message to the default port 6448. 
More precisely, the following parameters:
-Param 0: sound level.
-Param 1: average note.
-Param 2: Beat detection (0 or 1).
-Param 3-32: Beat detection (0 or 1) for each frequency band.
-Param 33-62: FFT logarithmic averages. (30 bands of frequency)


It uses the library  Minim, made for sound analysis. 
Cf. for more informations about it: 
http://code.compartmental.net/minim/index_analysis.html
 
It uses also the library OscP5 for sending OSC message.



Minimal visualisation of the beats and level are displayed, for a partial feedback.


PS: The version used of Processing is 3.0.2.