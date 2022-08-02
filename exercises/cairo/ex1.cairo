# %builtins pedersen range_check ecdsa bitwise output
# %builtins range_check output

from starkware.cairo.common.serialize import serialize_word

## Create a function that accepts a parameter and logs it
func log_value(y : felt):     
   alloc_locals

   # Start a hint segment that uses python print() 
   %{ 
      print(ids.y)
   %}

   ## This exercise has no tests to check against.

   return ()   
end
