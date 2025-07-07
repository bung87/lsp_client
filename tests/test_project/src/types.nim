## Types module for LSP testing
## This module contains various type definitions to test LSP functionality

import std/[tables, sets, options, strformat, math]

type
  # Enum for testing enum completion and hover
  Status* = enum
    Ready = "ready"
    Running = "running" 
    Stopped = "stopped"
    Error = "error"

  # Object type for testing object member completion
  User* = object
    id*: int
    name*: string
    email*: string
    status*: Status
    metadata*: Table[string, string]

  # Ref object for testing inheritance-like patterns
  Animal* = ref object of RootObj
    name*: string
    age*: int

  Dog* = ref object of Animal
    breed*: string
    isGoodBoy*: bool

  Cat* = ref object of Animal
    livesLeft*: int
    isIndoor*: bool

  # Generic type for testing generic type completion
  Container*[T] = object
    items*: seq[T]
    capacity*: int

  # Enum for shape kinds - defined before Shape
  ShapeKind* = enum
    Circle, Rectangle, Triangle

  # Variant object for testing case completion
  Shape* = object
    case kind*: ShapeKind
    of Circle:
      radius*: float
    of Rectangle:
      width*, height*: float
    of Triangle:
      side1*, side2*, side3*: float

# Procedures for testing procedure completion and hover
proc newUser*(id: int, name: string, email: string): User =
  ## Creates a new User instance
  ## 
  ## Args:
  ##   id: Unique identifier for the user
  ##   name: Full name of the user  
  ##   email: Email address of the user
  result = User(
    id: id,
    name: name,
    email: email,
    status: Ready,
    metadata: initTable[string, string]()
  )

proc `$`*(user: User): string =
  ## String representation of User
  result = &"User(id={user.id}, name=\"{user.name}\", email=\"{user.email}\", status={user.status})"

proc setStatus*(user: var User, status: Status) =
  ## Updates the user's status
  user.status = status

proc addMetadata*(user: var User, key: string, value: string) =
  ## Adds metadata to the user
  user.metadata[key] = value

# Animal procedures
proc newDog*(name: string, age: int, breed: string): Dog =
  ## Creates a new Dog instance
  result = Dog(name: name, age: age, breed: breed, isGoodBoy: true)

proc newCat*(name: string, age: int, livesLeft: int = 9): Cat =
  ## Creates a new Cat instance
  result = Cat(name: name, age: age, livesLeft: livesLeft, isIndoor: false)

proc speak*(animal: Animal): string =
  ## Makes the animal speak - demonstrates method dispatch
  if animal of Dog:
    result = "Woof!"
  elif animal of Cat:
    result = "Meow!"
  else:
    result = "..."

# Generic procedures
proc newContainer*[T](capacity: int = 10): Container[T] =
  ## Creates a new Container instance
  result = Container[T](items: @[], capacity: capacity)

proc add*[T](container: var Container[T], item: T): bool =
  ## Adds an item to the container
  if container.items.len < container.capacity:
    container.items.add(item)
    result = true
  else:
    result = false

proc len*[T](container: Container[T]): int =
  ## Returns the number of items in the container
  result = container.items.len

# Shape procedures
proc area*(shape: Shape): float =
  ## Calculates the area of a shape
  case shape.kind
  of Circle:
    result = 3.14159 * shape.radius * shape.radius
  of Rectangle:
    result = shape.width * shape.height
  of Triangle:
    # Using Heron's formula
    let s = (shape.side1 + shape.side2 + shape.side3) / 2
    result = sqrt(s * (s - shape.side1) * (s - shape.side2) * (s - shape.side3))

proc newCircle*(radius: float): Shape =
  ## Creates a new Circle shape
  result = Shape(kind: Circle, radius: radius)

proc newRectangle*(width: float, height: float): Shape =
  ## Creates a new Rectangle shape  
  result = Shape(kind: Rectangle, width: width, height: height)

# Constants for testing constant completion
const
  DEFAULT_CAPACITY* = 100
  MAX_USERS* = 1000
  VERSION* = "1.0.0" 