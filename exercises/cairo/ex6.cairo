## I AM NOT DONE

from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

## Implement a function that sums even numbers from the provided array 
func sum_even{bitwise_ptr : BitwiseBuiltin*}(arr_len : felt, arr : felt*, run : felt, idx : felt) -> (sum : felt):
    alloc_locals

    let (is_even) = bitwise_and(1, arr[idx])
    if is_even == 0:
        tempvar new_run = run + arr[idx]
    else:
        tempvar new_run = run
    end
    
    tempvar idx_diff = arr_len - idx
    if idx_diff == 1:
        return (new_run)
    else:
        return sum_even(arr_len, arr, new_run, idx + 1)
    end
end
