## Utility functions for the test project
## This module contains helper functions to test cross-module LSP functionality

import std/[strutils, sequtils, algorithm, times, json, strformat, options]
import types

# String utilities
proc capitalize*(s: string): string =
  ## Capitalizes the first letter of a string
  if s.len == 0:
    return s
  result = s[0].toUpperAscii & s[1..^1].toLowerAscii

proc isValidEmail*(email: string): bool =
  ## Simple email validation for testing
  result = email.contains("@") and email.contains(".")

proc sanitizeName*(name: string): string =
  ## Removes special characters from name
  result = name.multiReplace([("!", ""), ("@", ""), ("#", ""), ("$", "")])

# Collection utilities
proc findUserById*(users: seq[User], id: int): Option[User] =
  ## Finds a user by ID in a sequence
  for user in users:
    if user.id == id:
      return some(user)
  return none(User)

proc filterByStatus*(users: seq[User], status: Status): seq[User] =
  ## Filters users by their status
  result = users.filter(proc(u: User): bool = u.status == status)

proc sortUsersByName*(users: var seq[User]) =
  ## Sorts users alphabetically by name
  users.sort(proc(a, b: User): int = cmp(a.name, b.name))

# Data generation utilities
proc generateTestUsers*(count: int): seq[User] =
  ## Generates test users for testing purposes
  result = @[]
  for i in 1..count:
    let user = newUser(
      id = i,
      name = &"User{i}",
      email = &"user{i}@example.com"
    )
    result.add(user)

proc createSampleAnimals*(): seq[Animal] =
  ## Creates a sample collection of animals
  result = @[
    newDog("Rex", 3, "German Shepherd").Animal,
    newCat("Whiskers", 2, 7).Animal,
    newDog("Buddy", 5, "Golden Retriever").Animal,
    newCat("Shadow", 4, 9).Animal
  ]

# Math utilities
proc average*[T: SomeNumber](values: seq[T]): float =
  ## Calculates the average of a sequence of numbers
  if values.len == 0:
    return 0.0
  var total: T = 0
  for value in values:
    total += value
  result = total.float / values.len.float

proc median*[T: SomeNumber](values: seq[T]): float =
  ## Calculates the median of a sequence of numbers
  if values.len == 0:
    return 0.0
  
  var sorted = values.sorted()
  let middle = sorted.len div 2
  
  if sorted.len mod 2 == 0:
    result = (sorted[middle - 1].float + sorted[middle].float) / 2.0
  else:
    result = sorted[middle].float

# Time utilities
proc formatTimestamp*(timestamp: Time): string =
  ## Formats a timestamp for display
  result = timestamp.format("yyyy-MM-dd HH:mm:ss")

proc getCurrentTimestamp*(): string =
  ## Gets the current timestamp as a formatted string
  result = now().format("yyyy-MM-dd HH:mm:ss")

# JSON utilities
proc userToJson*(user: User): JsonNode =
  ## Converts a User to JSON
  result = %*{
    "id": user.id,
    "name": user.name,
    "email": user.email,
    "status": $user.status,
    "metadata": "{}"
  }

proc usersToJson*(users: seq[User]): JsonNode =
  ## Converts a sequence of users to JSON array
  result = newJArray()
  for user in users:
    result.add(userToJson(user))

# Configuration utilities
type
  Config* = object
    apiUrl*: string
    timeout*: int
    retries*: int
    debug*: bool

proc loadDefaultConfig*(): Config =
  ## Loads default configuration
  result = Config(
    apiUrl: "https://api.example.com",
    timeout: 30,
    retries: 3,
    debug: false
  )

proc validateConfig*(config: Config): bool =
  ## Validates configuration parameters
  result = config.apiUrl.len > 0 and
           config.timeout > 0 and
           config.retries >= 0

# Error handling utilities
type
  ValidationError* = object of CatchableError
  ConfigError* = object of CatchableError

proc validateUser*(user: User): bool =
  ## Validates a user object
  if user.name.len == 0:
    raise newException(ValidationError, "User name cannot be empty")
  if not isValidEmail(user.email):
    raise newException(ValidationError, "Invalid email address")
  if user.id <= 0:
    raise newException(ValidationError, "User ID must be positive")
  return true

# Performance testing utilities
proc benchmark*[T](fn: proc(): T, iterations: int = 1000): float =
  ## Simple benchmark function
  let start = cpuTime()
  for i in 1..iterations:
    discard fn()
  let duration = cpuTime() - start
  result = duration / iterations.float

# Template for testing template completion
template withTiming*(body: untyped): untyped =
  ## Template that measures execution time
  echo "Starting timed operation..."
  body
  echo "Timed operation completed" 