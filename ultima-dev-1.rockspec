package = "ultima"
version = "dev-1"
source = {
    url = "*** please add URL for source tarball, zip or repository here ***",
}
description = {
    homepage = "*** please enter a project homepage ***",
    license = "*** please specify a license ***",
}
dependencies = {
    "ldoc = 1.5.0-1",
    "ltui = 2.7",
    "inspect >= 3.1",
    "lua ~> 5.4",
    "debugger = scm-1",
    "dkjson = 2.8-1",
    "md5 = 1.3-1",
    "argparse = 0.7.1-1",
    "date = 2.2.1-1",
    "toml = 0.4.0-0",
}
build = {
    type = "builtin",
    modules = {
        main = "src/ultima.lua",
        setup = "src/setup.lua",
    },
}
