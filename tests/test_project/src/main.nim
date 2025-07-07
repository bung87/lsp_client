## Main application file for LSP testing
## This file demonstrates usage of the types and utils modules

import std/[strformat, sequtils, random, strutils]
import types, utils

# Main application logic
proc runUserDemo() =
  ## Demonstrates user management functionality
  echo "=== User Management Demo ==="
  
  # Create some test users
  var users = generateTestUsers(5)
  echo &"Generated {users.len} test users"
  
  # Add some custom users
  let customUser = newUser(100, "Alice Johnson", "alice@company.com")
  users.add(customUser)
  
  # Modify user status
  users[0].setStatus(Running)
  users[1].setStatus(Error)
  
  # Add metadata
  users[0].addMetadata("department", "engineering")
  users[0].addMetadata("role", "developer")
  
  # Filter and display users
  let readyUsers = filterByStatus(users, Ready)
  echo &"Users with Ready status: {readyUsers.len}"
  
  # Sort users by name
  sortUsersByName(users)
  echo "Users sorted by name:"
  for user in users:
    echo &"  - {user.name} ({user.email}) - {user.status}"

proc runAnimalDemo() =
  ## Demonstrates animal inheritance functionality
  echo "\n=== Animal Demo ==="
  
  let animals = createSampleAnimals()
  echo &"Created {animals.len} animals"
  
  for animal in animals:
    echo &"{animal.name} ({animal.age} years old) says: {speak(animal)}"
    
    # Demonstrate type checking
    if animal of Dog:
      let dog = Dog(animal)
      echo &"  {dog.name} is a {dog.breed} and is a good boy: {dog.isGoodBoy}"
    elif animal of Cat:
      let cat = Cat(animal)
      echo &"  {cat.name} has {cat.livesLeft} lives left and is indoor: {cat.isIndoor}"

proc runShapeDemo() =
  ## Demonstrates shape calculations
  echo "\n=== Shape Demo ==="
  
  let shapes = @[
    newCircle(5.0),
    newRectangle(4.0, 6.0),
    Shape(kind: Triangle, side1: 3.0, side2: 4.0, side3: 5.0)
  ]
  
  for i, shape in shapes:
    let shapeType = case shape.kind
      of Circle: "Circle"
      of Rectangle: "Rectangle" 
      of Triangle: "Triangle"
    
    echo &"Shape {i + 1}: {shapeType} with area {area(shape):.2f}"

proc runContainerDemo() =
  ## Demonstrates generic container functionality
  echo "\n=== Container Demo ==="
  
  # String container
  var stringContainer = newContainer[string](5)
  discard stringContainer.add("hello")
  discard stringContainer.add("world")
  discard stringContainer.add("nim")
  echo &"String container has {len(stringContainer)} items"
  
  # Integer container
  var intContainer = newContainer[int](3)
  for i in 1..5:
    let added = intContainer.add(i * 10)
    let status = if added: "success" else: "failed (container full)"
    echo &"Adding {i * 10}: {status}"
  
  echo &"Integer container has {len(intContainer)} items"

proc runMathDemo() =
  ## Demonstrates mathematical utilities
  echo "\n=== Math Demo ==="
  
  let numbers = @[1, 5, 3, 9, 2, 7, 4, 8, 6]
  echo &"Numbers: {numbers}"
  echo &"Average: {average(numbers):.2f}"
  echo &"Median: {median(numbers):.2f}"

proc runConfigDemo() =
  ## Demonstrates configuration handling
  echo "\n=== Configuration Demo ==="
  
  let config = loadDefaultConfig()
  echo &"Default config: API URL = {config.apiUrl}, Timeout = {config.timeout}s"
  
  if validateConfig(config):
    echo "Configuration is valid"
  else:
    echo "Configuration is invalid"

proc runErrorHandlingDemo() =
  ## Demonstrates error handling
  echo "\n=== Error Handling Demo ==="
  
  # Valid user
  try:
    let validUser = newUser(1, "John Doe", "john@example.com")
    if validateUser(validUser):
      echo "User validation passed"
  except ValidationError as e:
    echo &"Validation error: {e.msg}"
  
  # Invalid user
  try:
    let invalidUser = User(id: -1, name: "", email: "invalid-email")
    discard validateUser(invalidUser)
  except ValidationError as e:
    echo &"Validation error (expected): {e.msg}"

proc runBenchmarkDemo() =
  ## Demonstrates benchmarking functionality
  echo "\n=== Benchmark Demo ==="
  
  # Benchmark simple math operation
  let avgTime = benchmark(proc(): int =
    var sum = 0
    for i in 1..1000:
      sum += i * i
    return sum
  , 100)
  
  echo &"Average time for math operation: {avgTime * 1000:.4f} ms"

proc runTimingDemo() =
  ## Demonstrates timing template
  echo "\n=== Timing Demo ==="
  
  withTiming:
    # Simulate some work
    var total = 0
    for i in 1..100000:
      total += i
    echo &"Calculated sum: {total}"

# Main entry point
proc main() =
  ## Main application entry point
  echo "Starting LSP Test Project Demo"
  echo "=".repeat(40)
  
  # Run all demos
  runUserDemo()
  runAnimalDemo()
  runShapeDemo()
  runContainerDemo()
  runMathDemo()
  runConfigDemo()
  runErrorHandlingDemo()
  runBenchmarkDemo()
  runTimingDemo()
  
  echo "\n" & "=".repeat(40)
  echo "Demo completed successfully!"

# Global variables for testing
var
  globalUserCount* = 0
  globalConfig* = loadDefaultConfig()
  isInitialized* = false

# Procedures that can be called from tests
proc initializeApp*() =
  ## Initializes the application
  globalUserCount = 0
  globalConfig = loadDefaultConfig()
  isInitialized = true
  echo "Application initialized"

proc getStatus*(): string =
  ## Gets the current application status
  result = if isInitialized: "initialized" else: "not initialized"

# Run main when this file is executed directly
when isMainModule:
  randomize() # Initialize random number generator
  main() 