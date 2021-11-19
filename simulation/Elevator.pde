import java.util.LinkedList;
class Elevator{
  int id;
  double speed;
  int minFloor;
  int maxFloor;
  double closeTime;
  double openTime;
  double startTime;
  double stopTime;
  int GOING_UP = 0, GOING_DOWN = 1, WAITING = 2, DOOR_CLOSE = 3, DOOR_OPEN = 4, STARTING = 5, STOPPING = 6;
  int current_state = WAITING;
  int direction = 0;
  double StateTimeStamp = 0;
  int floor_dest=0;
  LinkedList<Integer> allDest;
  float doorSize;
  float posX;
  float posY;
  int floor;
  public Elevator(JSONObject elev,int index){
    this.id = elev.getInt("_id");
    this.speed = elev.getDouble("_speed");
    
    this.minFloor = elev.getInt("_minFloor");
    this.maxFloor = elev.getInt("_maxFloor");
    this.closeTime = elev.getDouble("_closeTime");
    this.openTime = elev.getDouble("_openTime");
    this.startTime = elev.getDouble("_startTime");
    this.stopTime = elev.getDouble("_stopTime");
    this.posX = index;
    this.posY = 0;
    this.floor = 0;
    this.direction = 0;
    this.doorSize = elev_width/2;
    this.allDest = new LinkedList<Integer>();
  }
  void setState(int state){
    this.current_state = state;
    StateTimeStamp = global_time;
  }
  void update(){
    if(this.direction == 0 && (this.allDest.size() > 0 && !this.allDest.contains(0)  || this.allDest.size() > 1)){
      this.floor_dest = this.allDest.get(0);
      
      if(this.floor_dest == this.floor){ 
        floor_dest = this.allDest.get(1);
      }
    }
    if(this.current_state == GOING_UP){
      if(this.floor >= this.maxFloor && !this.allDest.contains(this.floor)){
        this.direction = -1;
        
        this.setState(GOING_DOWN);
      }
      else if(!this.allDest.contains(this.floor)){
        
        this.posY += (float)Math.min((this.floor+1)*elev_height-this.posY ,elev_height*this.speed/frames_per_time_unit );
      }
    }
    
    else if(this.current_state == GOING_DOWN){
      if(this.floor <= this.minFloor && !this.allDest.contains(this.floor)){
        this.direction = 1;
        this.setState(GOING_UP);
      }
      else if(!this.allDest.contains(this.floor)){
        //(this.floor-1)*elev_height-this.posY
        this.posY += (float)Math.min( abs((this.floor)*elev_height-this.posY) ,-elev_height*this.speed/frames_per_time_unit );
      }
    }
    
    if(posY % elev_height == 0){
      if((this.posY/elev_height)-Math.floor(this.posY/elev_height) >= 0.5){
        this.floor = (int)Math.ceil(this.posY/elev_height);
      }
      else{
        this.floor=(int)Math.floor(this.posY/elev_height);
      }
      
    }
    if(this.allDest.size() == 0 && this.current_state == STARTING){
      this.setState(WAITING);
    }
    else if(this.allDest.contains(this.floor) && (this.current_state == GOING_UP || this.current_state == GOING_DOWN) ){
      this.setState(STOPPING);
      
    }
    
    else if(this.current_state == WAITING){  
      if(this.floor != this.floor_dest && this.allDest.size() > 0){
        
        if(this.floor < this.floor_dest)
          this.direction = 1;
        else if(this.floor > this.floor_dest)
          this.direction = -1;
       this.setState(STARTING);
      } 
      else if (this.allDest.size() > 0)
         this.setState(DOOR_OPEN);  
    }
    
    else if(this.current_state == STOPPING && global_time - StateTimeStamp >= this.stopTime){
       this.setState(DOOR_OPEN);
    }
    
    else if(this.current_state == DOOR_OPEN){
      if(global_time - StateTimeStamp > this.openTime){
        this.setState(DOOR_CLOSE);
      }
      else
        this.doorSize = 0;

    }
    
    else if(this.current_state == DOOR_CLOSE){
      while(this.allDest.contains((Integer)this.floor))
        this.allDest.remove((Integer)this.floor);
      if(global_time - StateTimeStamp > this.closeTime){
        this.setState(STARTING);
      }
      else
        this.doorSize = elev_width/2;


    }
    else if(this.current_state == STARTING && global_time - StateTimeStamp >= this.startTime){
      if(this.direction == 1)
         this.setState(GOING_UP);
       else if(this.direction == -1)
         this.setState(GOING_DOWN);
    }
    
  
  }
  void add_stop(int floor, boolean isSrc){
     if(this.allDest.size() == 0 && isSrc){
       this.floor_dest = floor;
       
       
     }
     if(!this.allDest.contains(floor)){
       this.allDest.add(floor);
     }
     
  }
  int getFloor(){
   return this.floor; 
    
  }
  
  void draw_elev(){
    pushMatrix();
    
    translate(posX*elev_width,-posY);
    noFill();
    stroke(255,0,0);
    strokeWeight(10);
    rectMode(CORNERS);
    rect(-elev_width/2,-elev_height,elev_width/2,0 );
    noStroke();
    fill(0);
    stroke(0);
    textAlign(CENTER, CENTER);
    
    popMatrix();
    strokeWeight(1);
  }
  
  
  
  
  
}
