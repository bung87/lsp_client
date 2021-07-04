# Package

version       = "0.1.0"
author        = "bung87"
description   = "lsp client"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.0"
requires "asynctools"
requires "faststreams"
requires "https://github.com/bung87/jsonschema#basetype" 
requires "oop_utils"

before test:
    requires "https://github.com/bung87/nimlsp#devel"