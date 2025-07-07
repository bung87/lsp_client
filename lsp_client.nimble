# Package

version       = "0.3.6"
author        = "bung87"
description   = "lsp client"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.0"
# requires "faststreams"
#requires "https://github.com/bung87/jsonschema"
requires "https://github.com/glassesneo/OOlib"
requires "chronos"
requires "ast_pattern_matching"

before test:
    requires "https://github.com/bung87/nimlsp#devel"
