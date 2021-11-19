import java.util.LinkedList;
Table table;
LinkedList<Double> callTime;
LinkedList<Integer> src;
LinkedList<Integer> dest;
LinkedList<Integer> elevatorID;
LinkedList<ArrayList<Integer>> Active_calls;
ArrayList<Elevator> elevators;
JSONObject json;
JSONArray elevators_json;
boolean start = true;
boolean pause = false;
public double global_time = 0;
public int frames_per_time_unit = 20;
public float elev_width = 150;
public float elev_height = 200;
int maxFloor;
int minFloor;
//moving grid 
private float gridX, gridY;
private float moveX = 0, moveY = 0, MouseAnchorX = 0, MouseAnchorY = 0;
private boolean clickDown = true;
public int pixelJump = 50;
float scrollTillUpdate = 5;
private float[] scaleStates = new float[(int)(3*scrollTillUpdate)];
private int scaleState = 0;
private float gridScale = 1;

void setup(){  
  generateCalls("Ex1_B1_Calls_a.csv");
  generate_elevators("B1.json");
  Active_calls = new LinkedList<ArrayList<Integer>>();
  fullScreen();
  frameRate(100);
  gridX = width/2;
  gridY = height/2;
  for(int i =0; i<scaleStates.length/3 ; i++){
    scaleStates[i] = (scrollTillUpdate+i*(2-1))/scrollTillUpdate;
    scaleStates[i+(int)(scrollTillUpdate)] = (2*scrollTillUpdate+i*(5-2))/scrollTillUpdate;
    scaleStates[i+2*(int)(scrollTillUpdate)] = (5*scrollTillUpdate+i*(10-5))/scrollTillUpdate;
  }
}

void draw(){
  
  if(start){
    if(!pause){
      if(frameCount % frames_per_time_unit == 0)
        global_time += 1;
    }

    background(255);
    textSize(50);
    textAlign(LEFT,CENTER);
    text("time: "+global_time,250,250);
    pushMatrix();
    translate(gridX, gridY);
    scale(pow(gridScale,-1));
    strokeWeight(10);
    rectMode(CORNERS);
    textSize(50);
    //rect(-elev_width/2,-minFloor*elev_height ,elev_width*1.5, -maxFloor*elev_height );
    if(!pause){
      if(callTime.size() > 0 && callTime.getFirst() <= global_time){
        int id = elevatorID.pop();
        int stop1 = src.pop();
        int stop2 = dest.pop();
        double t = callTime.pop();
        ArrayList<Integer> temp = new ArrayList<Integer>();
        temp.add(id);
        temp.add(stop1);
        temp.add(stop2);
        temp.add(0);
        temp.add(0);
        Active_calls.add(temp);
      }
    
      LinkedList<ArrayList<Integer>> finished_calls = new LinkedList<ArrayList<Integer>>();
    
      for(ArrayList<Integer> call: Active_calls){
         if( call.get(3) == 0){
           
           elevators.get(call.get(0)).add_stop(call.get(1),true);
           call.set(3,1);
         }
         if(elevators.get(call.get(0)).getFloor() == call.get(1) && call.get(3) == 1){
           elevators.get(call.get(0)).add_stop(call.get(2),false);
           call.set(4,1);
         }
         if(elevators.get(call.get(0)).getFloor() == call.get(2) && call.get(4) == 1){
            finished_calls.add(call);
         }
      }
      Active_calls.removeAll(finished_calls);
    }
    int k = 0;
    println(elevators.get(0).direction);
    for(int i = minFloor; i< maxFloor+1; i++){
      fill(0);
      strokeWeight(7);
      text("floor "+i,elev_width*elevators.size(),-(i+0.5)*elev_height);
      stroke(0); 
      noFill();
      line(-elev_width/2,-i*elev_height ,elev_width*(1+elevators.size()), -i*elev_height);
    }
    
    for(Elevator elev: elevators){
      if(!pause){
        elev.update();
      }
      noFill();
      strokeWeight(7);
      rect((k-0.5)*elev_width,-minFloor*elev_height ,(k+0.5)*elev_width, -(maxFloor+1)*elev_height );
      elev.draw_elev();
      
      k+=1;
    }
    
    
    
  
    
    
    popMatrix();
  }
}
void keyReleased(){
  if(key=='g'){
    pause = !pause; 
  }
}

void mouseReleased() {
  clickDown = true;
}
void mouseDragged() {
  //updateDots();
  //move in grid by dragging and holding shift
  //-------------------------------------------------------------------
  if (clickDown) {
    MouseAnchorX = mouseX-gridX+width/2;
    MouseAnchorY = mouseY-gridY+height/2;
    clickDown = false;
  }
  else {
   
    if (keyPressed) {
      if (key==CODED) {
        if (keyCode==SHIFT) {
          moveY = mouseY - MouseAnchorY;
          moveX = mouseX - MouseAnchorX;
          gridX = moveX + width/2;
          gridY = moveY+height/2;
        }
      }
    }
    
  }
}
//mouse wheal scroll up/down: zoom in/out
//-------------------------------------------------------------------
void mouseWheel(MouseEvent event){
  
  float e = event.getCount();
  //scroll down e = 1.0
  //scroll up e = -1.0
  if(e>0){
    scaleState++;
    if(scaleState >= scaleStates.length){
      scaleState = 0;
      for(int i = 0; i<scaleStates.length; i++){
        scaleStates[i] = scaleStates[i]*10.0;
      }
    }  
    gridScale = scaleStates[scaleState];
  }
  else if(e<0){
    scaleState--;
    if(scaleState <=-1){
      scaleState = scaleStates.length-1;
      for(int i = 0; i<scaleStates.length; i++){
        scaleStates[i] = scaleStates[i]/10.0;
      }
    }
    gridScale = scaleStates[scaleState];
  }
  //updateDots();
}



void generateCalls(String path){
  table = loadTable(path,"csv");
  //init calls 
  callTime = new LinkedList<Double>();
  src = new LinkedList<Integer>();
  dest = new LinkedList<Integer>();
  elevatorID = new LinkedList<Integer>();
  for (TableRow row : table.rows()) {
    callTime.add(row.getDouble(1));
    src.add(row.getInt(2));
    dest.add(row.getInt(3));
    elevatorID.add(row.getInt(5));
  }
  
}
void generate_elevators(String path){
  json = loadJSONObject(path);
  elevators_json = json.getJSONArray("_elevators");
  elevators = new ArrayList<Elevator>();
  for(int i = 0; i<elevators_json.size(); i++){
     
     Elevator elev = new Elevator(elevators_json.getJSONObject(i),i);
     elevators.add(elev);
  }
  

  maxFloor = json.getInt("_maxFloor");
  minFloor = json.getInt("_minFloor"); 
  
}
