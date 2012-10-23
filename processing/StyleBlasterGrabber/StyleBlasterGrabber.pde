import processing.opengl.*;
import processing.video.*;
import org.seltar.Bytes2Web.*;
import java.awt.Rectangle;

OpticalFlow of;
Capture cam;
Capture sensor;
Timer cameraTimer, sensorTimer;
int numPixels;
boolean blast; //turns photo-taking on or off
boolean ignoreSensor = true;
boolean debug = false;
boolean uploading = false;
boolean checkRight = false;
boolean grab = false;
ImageToWeb img;
byte[] imgBytes;
PImage grabImage;

MotionSensor leftSensor, rightSensor;

//SETUP VARS
String version = "1.5";
int startHour = 7; //7am
int endHour = 17;  //5pm
int sensorBuffer = -200;
int sensorBufferY = 50;
String uploadURL = "http://styleblaster.herokuapp.com/upload";
int camWidth;
int camHeight = 720;
int sensorThreshold = 15;
int flowThreshold = -100;
float sensorRes = 1;

public void setup() {
  int camWidth = 1280;//(16*camHeight)/9; //get correct aspect ratio for width
  //camHeight = 2;
  int sketchHeight = 1000;
  int sketchWidth = 666;
  float m = .7;
  
  size(round(sketchWidth*m), round(sketchHeight*m));
  //   size(1280, 720);

  String[] devices = Capture.list();
  // uncomment the line below to print a list of devices ready for img capture
  println(devices);
  fill(255, 50, 50);
  noFill();
  String[] cameras = Capture.list();
  if (version == "2.0") {
    cam = new Capture(this, 1280, 960, "Logitech Camera");
  }
  else {
    //   cam = new Capture(this, 2592,1944);
    //Logitech 910c
    //cam = new Capture(this, 1280, 960);
    //Microsoft Studio
    cam = new Capture(this, 1920, 1080);
    // cam = new Capture(this, 1280, 720);
  }

  if (version == "2.0") {
    //   cam.start();
  }
  //set global framerate
  int f = 25;
  frameRate(f);
  cam.frameRate(f);
  cameraTimer = new Timer(1000);

  sensorTimer = new Timer(1000);

  //initialize the hit areas
  leftSensor = new MotionSensor();
  rightSensor = new MotionSensor();

  of = new OpticalFlow(cam);
  
}

void draw() {
  background(0);
  blast = false;
  if (hour()>=startHour) {
    if (hour()<endHour) {
      if (cam.available()) {
        blast = true;
      }
    }
  }
  
  if (mousePressed) {
    rectMode(CORNER);

    leftSensor._bDiff = 0;
    ignoreSensor = true;
    int sensorWidth = round((mouseX - leftSensor._r.x));
    int sensorHeight =  mouseY - leftSensor._r.y;
    leftSensor._r.width = sensorWidth;
    leftSensor._r.height = sensorHeight;

    leftSensor.update();
    
    blast = false;
  }

  if (! uploading) {
    cam.read();
    grabImage = cam.get(cam.width/2-width/2, cam.height/2-height/2, width, height);
    image(grabImage, 0, 0);

    of.updateImage(grabImage);
    of.draw();
    
    if (ignoreSensor) {
        ignoreSensor = false;
      }
      else {
        if (grab) {
          //          leftSensor.reset();
          println("!!!HIT!!! @ : "+rightSensor._bDiff);
          fill(255, 0, 0);
          onHit();
        }
        else {
          noFill();
        }
      }
      
  }

  stroke(255, 100, 100);
  //***DRAW DEBUG SHIT TO SCREEN***

  if (debug) {
    rectMode(CORNER);
    noFill();
    //date
    text(getTimestamp(), 5, 15);

    leftSensor.draw();
    rightSensor.draw();

    fill(255);
    text("threshold: "+sensorThreshold, 5, height-5);
    text("xFlowSum: "+of.xFlowSum, width - 150, height - 5); // time (msec) for this frame
  }

    if (blast) {

      //BLAST OFF!

      boolean hit = false;
      grab = false;
      //update the reference image on the sensors
      //   rightSensor._image = grabImage;
      leftSensor._image = grabImage;

      hit = leftSensor.checkHitArea();     
      if (hit) {
        leftSensor.reset();

        if (of.xFlowSum < flowThreshold) {
          // onHit();
          grab = true;
        }
      }

      /*
      //MONOTR THE LEFT SENSOR
       if (!checkRight) {
       //monitor the left sensor
       leftHit = leftSensor.checkHitArea();
       if (leftHit) {
       checkRight = true;
       rightSensor.reset();
       // leftSensor._bDiff = 0;
       //start the timer
       sensorTimer.start();
       }
       }
       else {
       //monitor the RIGHT sensor
       if (sensorTimer.isFinished()) {
       //STOP monitoring the right sensor
       checkRight = false;
       // rightSensor._bDiff = 0;
       }
       else {
       rightHit = false;
       rightHit = rightSensor.checkHitArea();
       }
       }
       */
      
      
    }
  
}

void mousePressed() {
  leftSensor._r.x = mouseX;
  leftSensor._r.y = mouseY;
  // rightSensor._r.x = mouseX+rightSensor._r.width;
  // rightSensor._r.y = mouseY;
  // rightSensor._r.y = mouseY+sensorBufferY;
  ignoreSensor = true;
}



void onHit() {
  //IS THE CAMERA TIMER NEEDED HERE?
  if (cameraTimer.isFinished()) {
    takePicture();
    cameraTimer.start();
  }
}

String getTimestamp() {
  String filename = "";
  filename += String.valueOf(year());
  filename += "-";
  filename += String.valueOf(month());
  filename += "-";
  filename += String.valueOf(day());
  filename += "-";
  filename += String.valueOf(hour());
  filename += "-";
  filename += String.valueOf(minute());
  filename += "-";
  filename += String.valueOf(second());
  return filename;
}

void takePicture() {

  /* PGraphics pg = createGraphics(grabImage.width, grabImage.height, P2D); // I create a PGraphics from it
   pg.loadPixels();
   grabImage.loadPixels();
   for (int i = 0; i < grabImage.pixels.length; i++)
   {
   pg.pixels = grabImage.pixels;
   }*/

  // "this" references the processing PApplet itself and is mandatory here
  img = new ImageToWeb(this);
  img.setType(ImageToWeb.PNG);

  // load the raw bytes from the thing
  imgBytes = img.getBytes();

  // upload the picture
  uploadPicture();
}

void uploadPicture() {
  // img.post(String project, String url, String filename, boolean popup, byte[] bytes)
  img.post("test", uploadURL, getTimestamp() + ".png", false, imgBytes);
  cameraTimer.start();
}

void keyPressed() {
  if (key == ' ') {
    debug = !debug;
  } 
  else if (key == 'c') {
    //open camera settings
    cam.settings();
    ignoreSensor = true;
  }
  else if (key == '.') {
    //increase the threshold
    sensorThreshold += 1;
    leftSensor._thresh = sensorThreshold;
    rightSensor._thresh = sensorThreshold;
  }
  else if (key == ',') {
    //increase the threshold
    sensorThreshold -= 1;

    leftSensor._thresh = sensorThreshold;
    rightSensor._thresh = sensorThreshold;
  }
  else if (key=='w') of.flagseg=!of.flagseg; // segmentation on/off
  else if (key=='s') of.flagsound=!of.flagsound; //  sound on/off
  else if (key=='m') of.flagmirror=!of.flagmirror; // mirror on/off
  else if (key=='f') of.flagflow=!of.flagflow; // show opticalflow on/off
}

