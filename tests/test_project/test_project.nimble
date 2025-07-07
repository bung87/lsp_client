# Package
version       = "0.1.0"
author        = "Test Author"
description   = "A test project for LSP client testing"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 1.6.0"

task test, "Run tests":
  exec "nim c -r tests/test_all.nim" 