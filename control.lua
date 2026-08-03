util = require("util") --util functions are useful
TFMG = require("__TFMG-lib__.control.util") --a few of my utility/debug functions.
TFMG_table = require("__TFMG-lib__.control.table") --table functions

require("scripts.docking") --handles the assembly of docking port multiblocks.
docking = require("scripts.docking") 
require("scripts.link") --handles linking docking ports.
link = require("scripts.link")
require("scripts.ui") --handles the gui
ui = require("scripts.ui")

require("scripts.on-events")--registers all init events and build/rotate/destroy events.

