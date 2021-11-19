import sys
import pandas as pd
import copy

class Route(object):
    def __init__(self, direction, startTime, startFloor, endFloor,elev,route=None,route_time=None):
        if route != None:
            self.route = copy.deepcopy(route)
        else:
            #self.route = { key: False for key in range(min(startFloor,endFloor), max(startFloor,endFloor)+1)}
            self.route = { key: False for key in [min(startFloor,endFloor), max(startFloor,endFloor)]}
        if route_time != None:
            self.route_time = copy.deepcopy(route_time)
        else:
            #self.route_time = {key: startTime+ abs(startFloor-key)/elev.speed for key in range(min(startFloor,endFloor),max(startFloor,endFloor)+1)}
            self.route_time = {key: startTime+abs(startFloor-key)/elev.speed for key in [min(startFloor,endFloor),max(startFloor,endFloor)]}
        self.elev = elev
        self.dir = direction
        self.UP = 1
        self.DOWN = -1
    
    #re-defining the "in" operator when using it on our route object
    def __contains__(self,param1):
        high = max(self.route)
        low = min(self.route)
        if param1 <= high and param1 >= low:
            return True
        return False
   
    #find at what time we will reach the floor
    def get_route_time(self, floor):
        if floor in self.route_time:
            return self.route_time[floor]
        if self.dir == 1:
            new_route_time = {key:self.route_time[key] for key in sorted(self.route_time) if key < floor}


        else:
            new_route_time = {key:self.route_time[key] for key in sorted(self.route_time) if key > floor}
            
        if len(new_route_time) == 0:
            return 0
        last_floor = max(new_route_time,key=new_route_time.get)
        return self.route_time[last_floor] + abs(floor-last_floor)



    



class Elevator(object):
    def __init__(self,elev):
        self.id = elev["id"]
        self.speed = elev["speed"]
        self.minFloor = elev["minFloor"]
        self.maxFloor = elev["maxFloor"]
        self.closeTime = elev["closeTime"]
        self.openTime = elev["openTime"]
        self.startTime = elev["startTime"]
        self.stopTime = elev["stopTime"]
        self.FullRoute = []
        self.floorCount = self.maxFloor - self.minFloor

    #adds a call to our elevator's route
    def add_to_route(self,call,FullRoute,start=0):
        reached_src = False
        route_num = 0
        for route in FullRoute[-self.floorCount:]:
            time_src = route.get_route_time(call["src"])
            
            #if call["src"] in route.route and route.route_time[call["src"]] >= call["time"] and call["dest"] in route.route_time:
            if call["src"] in route and time_src >= call["time"] and call["dest"] in route:
                if (call["dest"]-call["src"])/abs(call["dest"]-call["src"]) == route.dir:
                    route.route[call["src"]] = True
                    route.route[call["dest"]] = True
                    time_dest = route.get_route_time(call["dest"])
                    route.route_time[call["src"]] = time_src
                    route.route_time[call["dest"]] = time_dest
                    return FullRoute, route_num
            
            #if call["src"] in route.route and route.route_time[call["src"]] >= call["time"]:
            if call["src"] in route and time_src >= call["time"]:
                route.route[call["src"]] = True
                route.route_time[call["src"]] = time_src
                reached_src = True
            
            #elif reached_src and call["dest"] in route.route:
            elif reached_src and call["dest"] in route:
                route.route[call["dest"]] = True
                time_dest = route.get_route_time(call["dest"])
                route.route_time[call["dest"]] = time_dest
                return FullRoute, route_num

            elif reached_src == False:
                route_num += 1

        if len(FullRoute) == 0:
            startTime = call["time"]
            startFloor = 0
            if call["src"] == startFloor:
                direction = call["dest"]/abs(call["dest"])
            else:
                direction = call["src"]/abs(call["src"])
            if direction == 1:
                endFloor = self.maxFloor
            else:
                endFloor = self.minFloor
        else:
            startTime = max( call["time"], max(FullRoute[-1].route_time.values()) )

            #if the elevator is on standby
            if call["time"] > max(FullRoute[-1].route_time.values()):
                #all the stops the elevator made
                visited = [key for key,value in FullRoute[-1].route.items() if value]
                if FullRoute[-1].dir == 1:
                    startFloor = max(visited)
                else:
                    startFloor = min(visited)
                
                #special case where the elevator just happens to wait for new calls at the place where the next call will come from 
                if startFloor == call["src"]:
                    reached_src = True

                if reached_src:
                    direction = (call["dest"]-startFloor)/abs(call["dest"]-startFloor)
                else:
                    direction = (call["src"]-startFloor)/abs(call["src"]-startFloor)
            else:
                if FullRoute[-1].dir == 1:
                    startFloor = self.maxFloor
                    direction = -1
                else:
                    startFloor = self.minFloor
                    direction = 1
                
            if direction == 1:
                endFloor = self.maxFloor
            else:
                endFloor = self.minFloor

        newRoute = Route( direction, startTime, startFloor, endFloor,self)
        FullRoute.append(newRoute)
        return self.add_to_route(call,FullRoute,start)

    #updates the the times of all the calls after inserting a new call
    def update(self, FullRoute,last_call,start=0):
        startTime = 0
        time_to_finish = 0
        for route in FullRoute[start:]:
            stopNum = 0
            
            startTime = max( min(route.route_time.values()), startTime)
            
            if route.dir == 1:
                startFloor = min(route.route)
            else:
                startFloor = max(route.route)
            indexs = [k for k in route.route_time]
            if route.dir == -1:
                indexs.reverse()
            for key in indexs:
                
                route.route_time[key] = (self.stopTime + self.openTime + self.startTime + self.closeTime)*stopNum + abs(startFloor-key)/self.speed + startTime
                if route.route[key]:
                    route.route_time[key] += (self.stopTime + self.openTime)
                    stopNum+=1
            if last_call["dest"] in route.route_time:
                time_to_finish = route.route_time[last_call["dest"]]
            startTime = max(route.route_time.values() )
        return FullRoute, time_to_finish - last_call["time"]

    #returns the accumaltive difference in time caused by adding the new stop
    def get_time_diff(self,newRoute,start=0):
        total_diff = 0
        for route in range(start, len(self.FullRoute)):
            for stop,t in self.FullRoute[route].route_time.items():
                total_diff += newRoute[route].route_time[stop] - t
        return total_diff


#finds the most optimal elevator to allocate the stop
def allocate_stop(elevators,call,call_count):
    fastest = float('inf')
    bestIDX = -1
    best_route = []
    i = 0
    for elev in elevators:
        newRoute = [Route(elev.FullRoute[i].dir,0,0,0,elev,route=elev.FullRoute[i].route,route_time=elev.FullRoute[i].route_time) for i in range(len(elev.FullRoute))]
        
        newRoute, route_change = elev.add_to_route(call,newRoute)  
            
        newRoute,wait_time = elev.update(newRoute,call,route_change)
        
        diff = elev.get_time_diff(newRoute,route_change)/call_count
        decision_func = diff**2 + wait_time/call_count

        if(decision_func<fastest):
            bestIDX = i
            best_route = newRoute
            fastest = decision_func
        i+=1
    elevators[bestIDX].FullRoute = best_route
    return bestIDX


#Allocates an elevator for each call
def generate_plan(elevators,calls):
    i = 0
    
    for call in calls:
        call["elev"] = allocate_stop(elevators,call,len(calls))
        
        i+=1
    return calls


if __name__ == "__main__":
    
    args = sys.argv[1:]
    if len(args) > 1:
        try:
            building = pd.read_json(args[0]).to_dict()
        except:
            building = pd.read_json("B5.json").to_dict()
        
        try:
            case = pd.read_csv(args[1],names=["call","time","src","dest","state","elev"])
        except:
            case = pd.read_csv("Calls_b.csv",names=["call","time","src","dest","state","elev"])
        try:
            out = args[2]
        except:
            out = 'out.csv'
    
    else:
        building = pd.read_json("B5.json").to_dict()
        case = pd.read_csv("Calls_b.csv",names=["call","time","src","dest","state","elev"])
        out = "out.csv"
    case = case.to_dict('records')
    #removing the '_' character from the start of the elevator paramaters
    elevators = [ {key[1:]:value for key,value in elevator.items()}  for _,elevator in building["_elevators"].items()]
    elevators = [Elevator(elev) for elev in elevators]
    
    plan = generate_plan(elevators,case)
    wait_time = 0
    
        

    df = pd.DataFrame(plan)
    df.to_csv(out, index=False,header = False)
