import peasy.*;
import controlP5.*;
import processing.opengl.*;
import processing.pdf.*;
import processing.dxf.*;

PeasyCam cam;
ControlP5 cp5;

int segments;

float[][] surfaceLevelData;
float[] surfaceLevelEnvelope;
float amplitude;

float fov = PI/3.0;
float cameraZ = (height/2.0) / tan(fov/2.0);
int scale = 20;

int alpha=255;

boolean exportPDF=false;
boolean exportDXF=false;

void setup() {
  size(1200, 680, P3D);
  smooth(8);
  
  cam = new PeasyCam(this,700);
  cam.setRotations(-1,0.6,0);
  perspective(fov, float(width)/float(height), 
            cameraZ/30.0, cameraZ*30.0);
            
  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);
  cp5.setColorForeground(color(64,181,138));
  cp5.setColorBackground(color(5,5,5));
  cp5.setColorActive(color(46,255,139));
  
  segments = 25;
  surfaceLevelData = new float[segments+1][segments+1];
  surfaceLevelEnvelope = new float[30];
  
  cp5.addSlider("wave")
     .setPosition(10 + 10*0,10)
     .setSize(10,100)
     .setRange(0.0,1.0)
     .setValue(0)
     .setId(0)
     ;
  for(int i = 1;i<30;i++){
    cp5.addSlider("wave"+i)
     .setPosition(10 + 10*i,10)
     .setSize(10,100)
     .setRange(0.0,1.0)
     .setValue(0)
     .setId(i)
     .setLabelVisible(false)
     ;
  }
  cp5.addSlider("amplitude")
     .setPosition(320,10)
     .setSize(10,100)
     .setRange(0.0,60.0)
     .setValue(25)
     ;
  cp5.addSlider("segments")
     .setPosition(370,10)
     .setSize(10,100)
     .setRange(3,82)
     .setValue(segments)
     ;
  cp5.addSlider("fov")
     .setPosition(420,10)
     .setSize(10,100)
     .setRange(1.0,9.0)
     .setValue(3.0)
     ;
  cp5.addNumberbox("alpha")
     .setPosition(460,70)
     .setSize(37,12)
     .setRange(0,255)
     .setDirection(Controller.HORIZONTAL)
     .setValue(255)
     .setColorForeground(color(20,20,20))
     ;
  cp5.addButton("export_PDF")
     .setValue(0)
     .setPosition(460,10)
     .setSize(60,20)
     ;
  cp5.addButton("export_DXF")
     .setValue(0)
     .setPosition(460,40)
     .setSize(60,20)
     ;
  
  updateSurfaceLevelData();
}

void draw() {
  background(0);
  drawMesh();
  gui();
}

void drawMesh(){
  stroke(255,alpha);
  
  if(exportPDF){
    beginRaw(PDF, "tensile_logo_"+str(month())+str(day())+str(hour())+str(second())+"-####.pdf");
    stroke(0);
  }
  else if(exportDXF){
    beginRaw(DXF, "tensile_logo_"+str(month())+str(day())+str(hour())+str(second())+"-####.dxf");
    stroke(0);
  }
  
  translate(-(segments/2)*scale,-(segments/2)*scale);

  noFill();
  for(int y = 0; y<segments; y++){
    for (int x = 0; x<segments; x++){ 
      line(x*scale,y*scale, surfaceLevelData[x][y], 
        (x+1)*scale, y*scale, surfaceLevelData[x+1][y]);
      line(x*scale,y*scale, surfaceLevelData[x][y], 
        x*scale, (y+1)*scale, surfaceLevelData[x][y+1]);
    }
    line(segments*scale, y*scale, surfaceLevelData[segments][y],
      segments*scale, (y+1)*scale, surfaceLevelData[segments][y+1]);
  }

  for (int x = 0; x<segments; x++){
    line(x*scale,segments*scale, surfaceLevelData[x][segments], 
      (x+1)*scale, segments*scale, surfaceLevelData[x+1][segments]);
  } 
  
  if(exportPDF||exportDXF){
    endRaw();
    println("exported");
    exportDXF = false;
    exportPDF = false;
  }
}

void updateSurfaceLevelData(){ 
  for(int y = 0; y<segments+1; y++){
    for (int x = 0; x<segments+1; x++){
      surfaceLevelData[x][y]=calculateLevel(sqrt(pow((x-segments/2.0)/2.0,2)
        +pow((y-segments/2.0)/2.0,2)))
        *amplitude;
    }
  }
}

float calculateLevel(float distanceToCenter){
  float level=0;
  int envelopeIndex = (int)distanceToCenter;
  level = map(distanceToCenter, envelopeIndex, envelopeIndex+1,
    surfaceLevelEnvelope[envelopeIndex], surfaceLevelEnvelope[envelopeIndex+1]);
  return level;
}

void gui() {
  hint(DISABLE_DEPTH_TEST);
  cam.beginHUD();
  perspective();
  stroke(35);
  noFill();
  rect(0.5,0.5,530,131);
  cp5.draw();
  perspective(fov, float(width)/float(height), 
            cameraZ/30.0, cameraZ*30.0);
  cam.endHUD();
  hint(ENABLE_DEPTH_TEST);
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.getController().getName().startsWith("wave")) {
    int id = theEvent.getController().getId();
    if(id>=0&&id<surfaceLevelEnvelope.length){
      surfaceLevelEnvelope[id] = theEvent.getValue();
      updateSurfaceLevelData();
    }
  }
  
  else if (theEvent.getController().getName().startsWith("amplitude")){
    updateSurfaceLevelData();
  }
  
  else if(theEvent.getController().getName().startsWith("segments")){
    segments = (int)theEvent.getValue();
    surfaceLevelData = new float[segments+1][segments+1];  
    updateSurfaceLevelData();
  }
  
  else if(theEvent.getController().getName().startsWith("fov")){
    fov = PI/theEvent.getValue();
  }
  
  else if(theEvent.getController().getName().startsWith("alpha")){
    alpha = (int)theEvent.getValue();
  }
}

void export_PDF(){
  if(frameCount!=0){
    saveFrame("tensile_logo_"+str(month())+str(day())+str(hour())+str(second())+"UIbackup-####.png");
    exportPDF = true;
  }
}

void export_DXF(){
  if(frameCount!=0){
    saveFrame("tensile_logo_"+str(month())+str(day())+str(hour())+str(second())+"UIbackup-####.png");
    exportDXF = true;
  }
}

void mousePressed(){
  if (mouseX > 0 && mouseX < 530 && mouseY > 0 && mouseY < 131) {
    cam.setActive(false);
  } else {
    cam.setActive(true);
  }
}
