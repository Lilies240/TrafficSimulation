# TrafficSimulation

HOW TO OPERATE:
- Open 'Traffic Simulation.exe' file
- Simulation will start running on its own
- Select the 'Time of Day' or 'Fixed Interval' button to restart the simulation with the given configuration
  **Source code can be found in the 'Scripts' folder (.gd files)

Implementation Goals:
  - Have a way to draw roads and intersections such that it is flexible enough to match real-world roads and intersections

  - Make vehicles that can:
    + follow along the drawn roads
    + react appropriately to traffic lights at an intersection
    + cross intersections to the correct lane
    + despawn once it reaches the end of its route offscreen

  - Make traffic signals that can:
    + behave differently based on their initialized traffic controller type
    + have a set of phases that each of the lights in an intersection will be in for each phase
    + have light transitions (red --> green and green --> yellow --> red)
    + have a set of time intervals for each light phase
    + use a different set of time intervals based on whether it is peak or off-peak traffic time
   
  - Make a spawner that can:
    + spawn roads and intersections when initialiized
    + spawn traffic signals at intersections when initialized
    + spawn vehicles and assign random routes for each vehicle
    + randomly spawn each vehicle within a range of time depending on whether it will spawn on a road with major or minor traffic flow
    
Implementation Plan:
  1. Implement and test road drawer
  2. Create vehicle and test road following, vehicle despawning, and intersection crossing
  3. Create traffic signal and test light transitions and timers
  4. Test vehicle interactions (collision avoidance) and traffic light reaction
  5. Test traffic signal detection and variables
  6. Test traffic signal phase coordination
  7. Create spawner and test road initialization
  8. Test vehicle spawning at intervals and traffic signal system initialization
