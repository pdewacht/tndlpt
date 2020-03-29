name tndlpt

file resident
file tndout
file res_data
file res_end

file tndinit
file cmdline
file tndlpt
file emmhack

# Use tiny model, so that we don't need to worry about segments and
# can just assume that DS == CS
system com

option map
option quiet
