# TrafficSimulation

Implementation Goals:
  - Have a way to draw roads and intersections such that it is flexible enough to match real-world roads and intersections (not modular)

  - Make vehicles that can:
    + react appropriately to vehicles or other obstacles in front of them
    + follow along the drawn roads
    + react appropriately to traffic lights at an intersection
    + cross intersections to the correct lane
    + despawn once offscreen

  - Make traffic signals that can:
    + behave differently based on their initialized traffic controller type
    + keep track of a set of states that each of the lights in an intersection will be in for each phase
    + have light transitions (red --> green and green --> yellow --> red)
    + (Timer-based) keep track of a timer or set of timers for each interval or time of day respectively
    + (Detector-based) keep track of the amount of vehicles occupying each lane using variables updated by collision boxes
   
  - Make a spawner that can:
    + spawn all of the roads and intersections when initialiized
    + spawn all of the traffic signals at the intersections when initialized
    + spawn vehicles at given rates/intervals on the roads at the edges of the screen
    
