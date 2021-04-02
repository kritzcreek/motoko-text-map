let upstream =
      https://github.com/dfinity/vessel-package-set/releases/download/mo-0.5.10-20200310/package-set.dhall

let overrides = [
  { dependencies = [] : List Text
  , name = "base"
  , repo = "https://github.com/dfinity/motoko-base"
  , version = "d8877676de4c3b6602ad57782da459f10fccc7e1"
  }
]

in  upstream # overrides

