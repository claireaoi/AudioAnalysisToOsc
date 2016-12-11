//Sound Analysis to Osc///////
//This sketch send by Osc message some sound parameters from the song listened.
//(such as level, average note, beat detection per frequency range, and FFT log spaced averages).
//This version send 63 parameters.
//It uses the library Minim, made for sound analysis. Cf: http://code.compartmental.net/minim/index_analysis.html
//A variant using the microphone or any other audio input possible. (Replace "song" by "in" for instance).
//Minimal visualisation of the beats and level are displayed.


//For OSC communication
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress dest;
//For Sound analysis
import ddf.minim.*;
import ddf.minim.ugens.*;
import ddf.minim.analysis.*;//For freq spectrum etc
Minim minim;//instantiate a minim object for sound
AudioSource audio;
BeatDetect beat0;//Beat detect mode sound energy (spikes of the level)
BeatDetect beat;//Beat detect mode frequency (tracks different part of spectrum)
BeatListener bl;//For beat
BeatListener bl0;//For beat0
String note;// name of the note
int no;//int value midi note
color c;//color
float hertz;//frequency in hertz
float midi;//float midi note
int noteNumber;//Variable for the midi note
int sampleRate= 44100;//sampleRate of 44100
float [] max= new float [sampleRate/2];//Array filled with amplitude values. Half size because FFT only reads the half of the sampleRate frequency.
float maximum;//The maximum amplitude of max.
float frequency;//Frequency in hertz
float spectrumScale = 4;
FFT fftLin;
FFT fftLog;
float sens=8;//sensitivity of the log level
float levelsens=0.1;
int counter=0;
float v_al;
int nparam=63;//number of parameters kept from sound analysis. (With choices made here) 
float [] sound_param=new float[nparam];//array with all the parameters from sound analysis sent via OSC
float radius=0;

void setup() {
  size(1000, 1000, P2D);
  background(0);
  frameRate(50);
  smooth(5); 
  //SOUND initialisation
  minim = new Minim(this);
  //  Uncomment the 2 lines below to use loaded sound file instead of audio input
  audio = minim.loadFile("Jungle.wav");
  ((AudioPlayer)audio).play();
  //  Uncomment line below If want to use AudioInput
  //audio = minim.getLineIn();
  // FFT : precise how long the audio buffers it has to analyse
  fftLin = new FFT(audio.bufferSize(), audio.sampleRate());
  fftLin.linAverages(30); //averages by grouping frequency bands linearly. use 30 averages.
  fftLog = new FFT( audio.bufferSize(), audio.sampleRate() );  //logarithmically spaced averages
  fftLog.logAverages( 22, 3);  // Mini octave width of 22 Hz & split each octave into three bands> results in 30 averages
  beat = new BeatDetect(audio.bufferSize(), audio.sampleRate());//beat.detect(song.mix);
  beat.setSensitivity(20);  
  bl = new BeatListener(beat, audio);    //make a new beat listener
  //Beat detect (sound energy)
  beat0 = new BeatDetect();
  // bl0 = new BeatListener(beat0, song);
 
  //Initialize OSC communication:
  oscP5 = new OscP5(this,12000); //listen for OSC messages on port 12000 (Wekinator default)
  dest = new NetAddress("127.0.0.1",6448); //send messages back to Wekinator on port 6448, localhost (this machine) (default)
  
}


void draw() {
counter++;
strokeWeight(2);
background(0);
//FFT
fftLin.forward(audio.mix);//i.e. applied to the mix right and left
fftLog.forward(audio.mix);
//fft.forward(song.mix);

//PARAM 0: level of the sound
float currentlevel=audio.mix.level();
sound_param[0]=currentlevel;
//White rectangle if level reach peak, according to sensibility
if (localpeak(sens)>0){ rect(0,0,width,height); fill(255,255,255,200);}

//PARAM 1: average note  
sound_param[1]=(float) findNote();//Suppose to detect which is the global note. Not that useful in an impure mix.

//PARAM 2: if beat (beat0) detected: 1, else 0:
beat0.detect(audio.mix);
radius *= 0.80;
if (beat0.isOnset()) {radius=400;sound_param[2]=(float)1;
}  
else {sound_param[2]=(float) 0;}
//Display decreasing white circle if beat detected
noStroke(); fill(255,255,255,20); ellipse(width/2,height/2,radius,radius); 

//PARAM 3-32: According to beat (/frequency): 0 if no beat in this freq range, else 1.
//Variant: use classification according to type of beat: beat.isKick() , beat.isSnare(),  beat.isHat()
float rectW = width / beat.detectSize();
for(int i = 0; i < beat.detectSize(); ++i){  //test one frequency band for an onset
    if (beat.isOnset(i))
   { sound_param[3+i]=(float) 1;
   //Rectangles for each band where beat detected
   rect(i*rectW, 0, rectW, height);noStroke();fill(10*i,200*i,100*i,100);  
}
else {sound_param[3+i]=(float) 0;}
}

//33-62 PARAMETERS: FFT Log averages:
for(int i = 0; i < fftLog.avgSize(); i++) {
  //float centerFrequency    = fftLog.getAverageCenterFrequency(i);//center freq of this band
  //float averageWidth = fftLog.getAverageBandWidth(i);   //width of this band
  //float lowFreq  = centerFrequency - averageWidth/2; //Lowest and highest frequencies of this band
  //float highFreq = centerFrequency + averageWidth/2;  
  sound_param[33+i]=fftLog.getAvg(i)*spectrumScale;// Param i+1 correspond to level of i band in log scale.
     
}
//Variant: for case normal average: for(int i = 0; i < fft.specSize(); i++){...
//Can convert the magnitude to a DB value:
//float bandDB = 20 * log( 2 * fft.getBand(i)*spectrumScale / fftLin.timeSize() );
//float bandHeight = map( bandDB, 0, -150, 0, height );
// Or for LIN AVERAGE, with centerFrequency = fftLin.indexToFreq(i); 
// And the width: float w = int( width/fftLin.avgSize() );
//fftLin.getAvg(i)*spectrumScale


//Send Osc message:
sendOsc(sound_param); 

}
  

//KEY CONTROL:::::::
void keyPressed() { 
}


//SOUND FCT:::::::
class BeatListener implements AudioListener{
  private BeatDetect beat;
  private AudioSource source; 
  BeatListener(BeatDetect beat, AudioSource source){
    this.source = source;
    this.source.addListener(this);
    this.beat = beat;
  }  
  void samples(float[] samps) { 
    beat.detect(source.mix);
  }
  void samples(float[] sampsL, float[] sampsR)
  {beat.detect(source.mix);}
}

void stop(){// Close Minim audio classes once finish
  audio.close();
  minim.stop();
  super.stop();
}

//Find the average note
int findNote() { 
  int not;
  for (int f=0;f<fftLin.avgSize();f++) { 
    max[f]=fftLin.getFreq(f); //amplitude vaue corresp to freq indexed by f
  }
  maximum=max(max);//The maximum value of the array.
  for (int i=0; i<max.length; i++) {
    if (max[i] == maximum) {//check which freq index corresponds to maximum.
      frequency= i;  }
  } 
 // From frequency to midi numbers. //-6 correction needed?
  midi= 69+12*(log((frequency-6)/440));
  no= int (midi);
//Octave has 12 tones and semitones. Modulo 12, notes names independently of frequency     
 if (no%12==9) {note = ("a");}
  if (no%12==10){note = ("a#");}
  if (no%12==11)  {note = ("b");}
  if (no%12==0){note = ("c"); }
  if (no%12==1){note = ("c#");}
  if (no%12==2) {note = ("d");}
  if (no%12==3){ note = ("d#");}
  if (no%12==4){note = ("e");}
  if (no%12==5){note = ("f");} 
  if (no%12==6){note = ("f#");}
  if (no%12==7) {note = ("g");}
  if (no%12==8)  {note = ("g#");}
not=no%12;
return not;
}

//To check if local peak of level detected
float localpeak(float sensib) {//return first freq peaking
boolean ifpeak=false;
float peakf=0;
int ff=0;
while ((!(ifpeak))&&(ff<fftLog.avgSize()))
{ifpeak=(fftLog.getAvg(ff)>sensib);
ff++;
}
if (ifpeak) {peakf=fftLog.getAverageCenterFrequency(ff);}  
return peakf;
}

//This is called automatically when OSC message is received
//void oscEvent(OscMessage theOscMessage) {
 // if (theOscMessage.checkAddrPattern("/wek/outputs") == true) {
 //   if(theOscMessage.checkTypetag("ff")) {
  //    float f1 = theOscMessage.get(0).floatValue();
  //   float f2 = theOscMessage.get(1).floatValue();
  //    action((int)f1, (int)f2);
  //  }
 // }
//}

//Action if receive message
//void action(int i, int j) {  
//}

//Send osc message:
void sendOsc(float[] soundan) {
  OscMessage msg = new OscMessage("/wek/inputs");
   for (int i = 0; i < soundan.length; i++) {
      msg.add(soundan[i]); 
   }
  oscP5.send(msg, dest);
}
