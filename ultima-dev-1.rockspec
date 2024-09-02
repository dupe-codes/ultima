package = "ultima"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
   "ldoc = 1.5.0-1",
   "ltui = 2.7",
   "inspect >= 3.1",
   "lua ~> 5.4"
}
build = {
   type = "builtin",
   modules = {
      main = "src/ultima.lua",
      setup = "src/setup.lua"
   }
}
